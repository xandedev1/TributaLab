module FiscalAuditor
  class PayrollChargesDashboard
    INSS_DISCOUNT_CODES = %w[566 596 641 757].freeze

    class << self
      def source_paths(company = "appa")
        Dir[CompanyPath.payroll_charges_glob(company)].sort
      end

      def inss_entries(company = "appa")
        inss_path = source_paths(company).find { |path| File.basename(path).upcase.start_with?("INSS") }
        inss_path ? PayrollChargesWorkbook.new(inss_path).inss_entries.freeze : []
      end

      def fgts_entries(company = "appa")
        source_paths(company).reject { |path| File.basename(path).upcase.start_with?("INSS") }
          .map { |path| PayrollChargesWorkbook.new(path).fgts_entry }.freeze
      end
    end

    attr_reader :periods, :company

    def initialize(periods: [], payroll_records: nil, inss_entries: nil, fgts_entries: nil, company: "appa")
      @periods = normalize_periods(periods)
      @payroll_records = payroll_records
      @inss_entries = inss_entries
      @fgts_entries = fgts_entries
      @company = company
    end

    def available?
      inss_entries.any? && fgts_entries.any?
    end

    def available_periods
      (inss_entries.map(&:period) + fgts_entries.map(&:period)).uniq.sort
    end

    def rows
      @rows ||= selected_periods.map do |period|
        payroll_net = payroll_totals.fetch(period, 0.to_d)
        monthly_inss = inss_entries.select { |entry| entry.period == period && entry.source_column != "N" }.sum(&:amount)
        thirteenth_inss = period == "2025-12" ? inss_entries.select { |entry| entry.source_column == "N" }.sum(&:amount) : 0.to_d
        inss_discounts = discount_records.select { |record| month_key(record.competence) == period }.sum(&:amount)
        inss_to_add = monthly_inss + thirteenth_inss - inss_discounts
        monthly_fgts = fgts_entries.select { |entry| entry.period == period && entry.kind == :monthly }.sum(&:amount)
        thirteenth_fgts = fgts_entries.select { |entry| entry.period == period && entry.kind == :thirteenth }.sum(&:amount)
        fgts_to_add = monthly_fgts + thirteenth_fgts
        charges_to_add = inss_to_add + fgts_to_add

        {
          period: period,
          payroll_net: payroll_net,
          inss_gross: monthly_inss + thirteenth_inss,
          inss_monthly: monthly_inss,
          inss_thirteenth: thirteenth_inss,
          inss_discounts: inss_discounts,
          inss_to_add: inss_to_add,
          fgts_monthly: monthly_fgts,
          fgts_thirteenth: thirteenth_fgts,
          fgts_to_add: fgts_to_add,
          charges_to_add: charges_to_add,
          adjusted_payroll: payroll_net + charges_to_add
        }
      end.freeze
    end

    def totals
      @totals ||= rows.first&.keys&.excluding(:period)&.to_h do |field|
        [ field, rows.sum { |row| row[field] } ]
      end || {}
    end

    def inss_components(period)
      inss_entries.select { |entry| entry.period == period }
    end

    def discount_components(period)
      discount_records.select { |record| month_key(record.competence) == period }
        .group_by { |record| [ record.event_code, record.event_description ] }
        .map do |(code, description), records|
          { code: code, description: description, amount: records.sum(&:amount), records: records }
        end.sort_by { |component| component[:code] }
    end

    def fgts_components(period)
      fgts_entries.select { |entry| entry.period == period }.sort_by { |entry| entry.kind == :monthly ? 0 : 1 }
    end

    private

    def inss_entries
      @inss_entries ||= self.class.inss_entries(company)
    end

    def fgts_entries
      @fgts_entries ||= self.class.fgts_entries(company)
    end

    def payroll_records
      @payroll_records ||= PayrollDashboard.records(company)
    end

    def discount_records
      @discount_records ||= payroll_records.select do |record|
        record.event_type == "Desconto" && INSS_DISCOUNT_CODES.include?(record.event_code)
      end
    end

    def payroll_totals
      @payroll_totals ||= payroll_records.group_by { |record| month_key(record.competence) }.transform_values do |records|
        earnings = records.select { |record| record.event_type == "Vencimento" }.sum(&:amount)
        discounts = records.select { |record| record.event_type == "Desconto" }.sum(&:amount)
        earnings - discounts
      end
    end

    def selected_periods
      available_periods.select { |period| periods.empty? || periods.include?(period) || periods.include?(period.first(4)) }
    end

    def normalize_periods(values)
      Array(values).select { |period| period.to_s.match?(/\A(?:\d{4}|\d{4}-(?:0[1-9]|1[0-2]))\z/) }
        .map(&:to_s).uniq.sort.freeze
    end

    def month_key(date)
      date.strftime("%Y-%m")
    end
  end
end
