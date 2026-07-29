module FiscalAuditor
  class PayrollComparisonDetail
    Result = Data.define(:summary, :events, :invoices)

    def initialize(client_code:, period:, payroll_records: nil, billing_records: nil)
      @client_code = client_code.to_s.strip.sub(/\.0\z/, "")
      @period = period.to_s
      raise ArgumentError, "Cliente ou competência inválidos" if @client_code.blank? || !@period.match?(/\A\d{4}-(?:0[1-9]|1[0-2])\z/)

      @dashboard = PayrollDashboard.new(
        periods: [ @period ], client_code: @client_code,
        payroll_records: payroll_records, billing_records: billing_records
      )
    end

    def result
      @result ||= begin
        summary = dashboard.base_comparison_rows.find do |row|
          row[:client_code] == client_code && row[:month] == period
        end
        raise ArgumentError, "Cruzamento da folha não localizado" unless summary

        Result.new(summary: summary, events: sorted_events.freeze, invoices: sorted_invoices.freeze)
      end
    end

    private

    attr_reader :client_code, :period, :dashboard

    def sorted_events
      dashboard.records.sort_by { |record| [ record.source, record.source_row, record.event_code ] }
    end

    def sorted_invoices
      dashboard.billing_records.sort_by do |record|
        [ record.emission_date || Date.new(9999, 12, 31), record.invoice_number.to_s, record.source_row ]
      end
    end
  end
end
