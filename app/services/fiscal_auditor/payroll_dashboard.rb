module FiscalAuditor
  class PayrollDashboard
    PAGE_SIZE = 100
    STATUSES = %w[covered deficit missing_billing negative_payroll].freeze

    class << self
      def source_paths(company = "appa")
        Dir[CompanyPath.payroll_glob(company)].sort
      end

      def records(company = "appa")
        paths = source_paths(company)
        signature = paths.map { |path| [ path, File.mtime(path).to_i, File.size(path) ] }
        cache_key = "records_#{company}"
        return instance_variable_get("@#{cache_key}") if instance_variable_get("@#{cache_key}_sig") == signature

        records = PayrollSnapshot.new(paths).records
        instance_variable_set("@#{cache_key}", records)
        instance_variable_set("@#{cache_key}_sig", signature)
        records
      end
    end

    attr_reader :periods, :client_code, :statuses, :page, :company

    def initialize(periods: [], client_code: nil, statuses: [], page: nil, payroll_records: nil, billing_records: nil, company: "appa")
      @periods = normalize_periods(periods)
      @client_code = client_code.to_s.strip.presence
      @statuses = Array(statuses).map(&:to_s).select { |status| STATUSES.include?(status) }.uniq.freeze
      @page = [ page.to_i, 1 ].max
      @payroll_records = payroll_records
      @company = company
      @billing_records = billing_records
    end

    def available?
      all_records.any?
    end

    def available_periods
      @available_periods ||= all_records.map { |record| month_key(record.competence) }.uniq.sort.freeze
    end

    def available_clients
      @available_clients ||= all_records.group_by(&:client_code).map do |code, client_records|
        [ code, client_records.group_by(&:client).max_by { |_, records| records.size }.first ]
      end.sort_by { |code, name| [ name, code ] }.freeze
    end

    def records
      return scoped_records if statuses.empty?

      @records ||= comparison_rows.map { |row| [ row[:client_code], row[:month] ] }.to_set.then do |selected_keys|
        scoped_records.select { |record| selected_keys.include?([ record.client_code, month_key(record.competence) ]) }
      end
    end

    def totals
      @totals ||= {
        earnings: comparison_rows.sum { |row| row[:earnings] },
        discounts: comparison_rows.sum { |row| row[:discounts] }
      }.tap { |totals| totals[:net] = totals[:earnings] - totals[:discounts] }
    end

    def billing_total
      comparison_rows.sum { |row| row[:billing_net] }
    end

    def difference
      billing_total - totals[:net]
    end

    def coverage_rate
      positive = comparison_rows.select { |row| row[:payroll_net].positive? }
      return 0.to_d if positive.empty?

      positive.count { |row| row[:status] == :covered }.to_d / positive.size * 100
    end

    def monthly_flow
      @monthly_flow ||= comparison_rows.group_by { |row| row[:month] }.transform_values do |month_rows|
        {
          earnings: month_rows.sum { |row| row[:earnings] },
          discounts: month_rows.sum { |row| row[:discounts] },
          payroll_net: month_rows.sum { |row| row[:payroll_net] },
          billing_net: month_rows.sum { |row| row[:billing_net] },
          difference: month_rows.sum { |row| row[:difference] }
        }
      end
    end

    def comparison_rows
      @comparison_rows ||= base_comparison_rows.select { |row| statuses.empty? || statuses.include?(row[:status].to_s) }
    end

    def base_comparison_rows
      @base_comparison_rows ||= payroll_groups.map do |(code, month), payroll_records|
        earnings = payroll_records.select { |record| record.event_type == "Vencimento" }.sum(&:amount)
        discounts = payroll_records.select { |record| record.event_type == "Desconto" }.sum(&:amount)
        payroll_net = earnings - discounts
        invoices = billing_groups.fetch([ code, month ], [])
        billing_net = invoices.sum(&:net)
        difference = billing_net - payroll_net

        {
          client_code: code,
          client: payroll_records.group_by(&:client).max_by { |_, grouped| grouped.size }.first,
          month: month,
          earnings: earnings,
          discounts: discounts,
          payroll_net: payroll_net,
          billing_net: billing_net,
          difference: difference,
          status: comparison_status(payroll_net, billing_net),
          events: payroll_records.size,
          documents: invoices.size
        }
      end.sort_by { |row| [ row[:month], row[:client] ] }
    end

    def billing_records
      filtered_billing_records
    end

    def status_counts
      @status_counts ||= comparison_rows.group_by { |row| row[:status] }.transform_values(&:size)
    end

    def paginated_comparison_rows
      comparison_rows.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || []
    end

    def total_pages
      [ (comparison_rows.size.to_f / PAGE_SIZE).ceil, 1 ].max
    end

    def source_count
      self.class.source_paths.size
    end

    def partial_period?(month)
      month == "2025-12"
    end

    private

    def all_records
      @all_records ||= @payroll_records || self.class.records(company)
    end

    def payroll_groups
      scoped_records.group_by { |record| [ record.client_code, month_key(record.competence) ] }
    end

    def scoped_records
      @scoped_records ||= all_records.select do |record|
        period_selected?(record.competence) && (client_code.blank? || record.client_code == client_code)
      end
    end

    def billing_groups
      @billing_groups ||= filtered_billing_records.group_by do |record|
        [ normalize_identifier(record.client_code), month_key(record.competence) ]
      end
    end

    def filtered_billing_records
      (@billing_records || Dashboard.records(company)).select do |record|
        record.client_code.present? && record.competence && period_selected?(record.competence) &&
          (client_code.blank? || normalize_identifier(record.client_code) == client_code) && !cancelled?(record)
      end
    end

    def comparison_status(payroll_net, billing_net)
      return :negative_payroll if payroll_net.negative?
      return :missing_billing if payroll_net.positive? && billing_net.zero?
      return :covered if billing_net >= payroll_net

      :deficit
    end

    def cancelled?(record)
      I18n.transliterate(record.status.to_s).downcase.include?("cancel")
    end

    def period_selected?(date)
      periods.empty? || periods.any? do |period|
        period.length == 4 ? date.year.to_s == period : month_key(date) == period
      end
    end

    def month_key(date)
      date.strftime("%Y-%m")
    end

    def normalize_periods(values)
      Array(values).select { |period| period.to_s.match?(/\A(?:\d{4}|\d{4}-(?:0[1-9]|1[0-2]))\z/) }
        .map(&:to_s).uniq.sort.freeze
    end

    def normalize_identifier(value)
      value.to_s.strip.sub(/\.0\z/, "")
    end
  end
end
