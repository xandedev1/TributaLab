module FiscalAuditor
  class ReconciliationDashboard
    TOLERANCE = 0.05.to_d
    VALUE_TYPES = %w[net gross].freeze
    PAGE_SIZE = 100

    attr_reader :billing_value_type, :receivable_value_type

    def initialize(
      billing_emission_periods: [], billing_competence_periods: [], billing_value_type: nil,
      receivable_emission_periods: [], receivable_competence_periods: [], receivable_value_type: nil,
      page: nil
    )
      @requested_billing_emission_periods = normalize_periods(billing_emission_periods)
      @requested_billing_competence_periods = normalize_periods(billing_competence_periods)
      @requested_receivable_emission_periods = normalize_periods(receivable_emission_periods)
      @requested_receivable_competence_periods = normalize_periods(receivable_competence_periods)
      @billing_value_type = normalize_value_type(billing_value_type)
      @receivable_value_type = normalize_value_type(receivable_value_type)
      @requested_page = [ page.to_i, 1 ].max
    end

    def available?
      all_billing_records.any? && all_receivable_records.any?
    end

    def billing_available_emission_periods
      @billing_available_emission_periods ||= available_periods(all_billing_records, :emission_date)
    end

    def billing_available_competence_periods
      @billing_available_competence_periods ||= available_periods(all_billing_records, :competence)
    end

    def receivable_available_emission_periods
      @receivable_available_emission_periods ||= available_periods(all_receivable_records, :emission_date)
    end

    def receivable_available_competence_periods
      @receivable_available_competence_periods ||= available_periods(all_receivable_records, :competence)
    end

    def billing_emission_periods
      @billing_emission_periods ||= valid_periods(@requested_billing_emission_periods, billing_available_emission_periods)
    end

    def billing_competence_periods
      @billing_competence_periods ||= valid_periods(@requested_billing_competence_periods, billing_available_competence_periods)
    end

    def receivable_emission_periods
      @receivable_emission_periods ||= valid_periods(@requested_receivable_emission_periods, receivable_available_emission_periods)
    end

    def receivable_competence_periods
      @receivable_competence_periods ||= valid_periods(@requested_receivable_competence_periods, receivable_available_competence_periods)
    end

    def entries
      @entries ||= (billing_groups.keys | receivable_groups.keys).map do |key|
        billing = billing_groups.fetch(key, [])
        receivables = receivable_groups.fetch(key, [])
        build_entry(key, billing, receivables)
      end.sort_by { |entry| [ -entry[:absolute_difference], entry[:client].to_s ] }
    end

    def totals
      @totals ||= {
        billing_gross: entries.sum { |entry| entry[:billing_gross] },
        receivable_gross: entries.sum { |entry| entry[:receivable_gross] },
        billing_net: entries.sum { |entry| entry[:billing_net] },
        paid: entries.sum { |entry| entry[:paid] },
        contingency: entries.sum { |entry| entry[:contingency] },
        billing_value: entries.sum { |entry| entry[:billing_value] },
        receivable_value: entries.sum { |entry| entry[:receivable_value] }
      }.then do |values|
        values.merge(
          gross_difference: values[:receivable_gross] - values[:billing_gross],
          net_difference: values[:paid] - values[:billing_net],
          selected_difference: values[:receivable_value] - values[:billing_value]
        )
      end
    end

    def status_counts
      @status_counts ||= entries.map { |entry| entry[:status] }.tally
    end

    def matched_count
      entries.count { |entry| entry[:status] == :matched }
    end

    def matched_source_count
      entries.count { |entry| entry[:billing_present] && entry[:receivable_present] }
    end

    def match_rate
      return 0 if billing_groups.empty?

      matched_source_count.fdiv(billing_groups.size) * 100
    end

    def visible_entries
      @visible_entries ||= entries.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || []
    end

    def page
      @page ||= [ @requested_page, total_pages ].min
    end

    def total_pages
      @total_pages ||= [ (document_count.fdiv(PAGE_SIZE)).ceil, 1 ].max
    end

    def first_visible_index
      return 0 if document_count.zero?

      ((page - 1) * PAGE_SIZE) + 1
    end

    def last_visible_index
      [ page * PAGE_SIZE, document_count ].min
    end

    def document_count
      entries.size
    end

    def billing_document_count
      billing_groups.size
    end

    def receivable_document_count
      receivable_groups.size
    end

    private

    def billing_records
      @billing_records ||= filtered_records(
        all_billing_records,
        emission_periods: billing_emission_periods,
        competence_periods: billing_competence_periods
      ).select { |record| key_for(record) }
    end

    def receivable_records
      @receivable_records ||= filtered_records(
        all_receivable_records,
        emission_periods: receivable_emission_periods,
        competence_periods: receivable_competence_periods
      ).select { |record| key_for(record) }
    end

    def all_billing_records
      @all_billing_records ||= Dashboard.records
    end

    def all_receivable_records
      @all_receivable_records ||= ReceivablesDashboard.records
    end

    def filtered_records(source_records, emission_periods:, competence_periods:)
      source_records.select do |record|
        period_matches?(record.emission_date, emission_periods) &&
          period_matches?(record.competence, competence_periods)
      end
    end

    def billing_groups
      @billing_groups ||= billing_records.group_by { |record| key_for(record) }
    end

    def receivable_groups
      @receivable_groups ||= receivable_records.group_by { |record| key_for(record) }
    end

    def key_for(record)
      return if record.client_code.blank? || record.invoice_number.blank?

      [ normalize_identifier(record.client_code), normalize_identifier(record.invoice_number) ]
    end

    def normalize_identifier(value)
      value.to_s.strip.sub(/\.0\z/, "")
    end

    def month_key(date)
      date&.strftime("%Y-%m")
    end

    def available_periods(records, field)
      records.filter_map { |record| month_key(record.public_send(field)) }.uniq.sort.freeze
    end

    def valid_periods(requested, available_months)
      available_years = available_months.map { |month| month.first(4) }.uniq
      requested.select { |period| available_months.include?(period) || available_years.include?(period) }.freeze
    end

    def period_matches?(date, periods)
      return true if periods.empty?
      return false unless date

      periods.include?(date.strftime("%Y")) || periods.include?(month_key(date))
    end

    def normalize_periods(periods)
      Array(periods).filter_map do |period|
        value = period.to_s
        value if value.match?(/\A\d{4}(?:-(?:0[1-9]|1[0-2]))?\z/)
      end.uniq.sort.freeze
    end

    def normalize_value_type(value)
      VALUE_TYPES.include?(value.to_s) ? value.to_s : "net"
    end

    def build_entry(key, billing, receivables)
      values = {
        client_code: key.first,
        invoice_number: key.last,
        client: receivables.first&.client || billing.first&.client,
        billing_emission_date: billing.first&.emission_date,
        billing_competence: billing.first&.competence,
        receivable_emission_date: receivables.first&.emission_date,
        receivable_competence: receivables.first&.competence,
        billing_gross: billing.sum(&:billed),
        receivable_gross: receivables.sum(&:gross),
        billing_net: billing.sum(&:net),
        paid: receivables.sum(&:paid),
        contingency: receivables.sum(&:contingency),
        billing_present: billing.any?,
        receivable_present: receivables.any?
      }
      billing_value = billing_value_type == "gross" ? values[:billing_gross] : values[:billing_net]
      receivable_value = receivable_value_type == "gross" ? values[:receivable_gross] : values[:paid]
      selected_difference = receivable_value - billing_value
      values.merge(
        gross_difference: values[:receivable_gross] - values[:billing_gross],
        net_difference: values[:paid] - values[:billing_net],
        billing_value: billing_value,
        receivable_value: receivable_value,
        selected_difference: selected_difference,
        absolute_difference: selected_difference.abs,
        status: status_for(values, selected_difference)
      )
    end

    def status_for(values, selected_difference)
      return :missing_receivable unless values[:receivable_present]
      return :missing_billing unless values[:billing_present]
      return :divergent if selected_difference.abs > TOLERANCE

      :matched
    end
  end
end
