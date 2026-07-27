require "test_helper"

module FiscalAuditor
  class ReceivablesDashboardTest < ActiveSupport::TestCase
    test "filters competences within one emission month and aggregates real values" do
      records = [
        record(emission: Date.new(2025, 2, 3), competence: Date.new(2025, 1, 1), gross: 1_000, contingency: 100, outstanding: 50, paid: 800),
        record(emission: Date.new(2025, 2, 4), competence: Date.new(2025, 2, 1), gross: 500, paid: 420),
        record(emission: Date.new(2025, 1, 5), competence: Date.new(2025, 1, 1), gross: 200, paid: 170)
      ]
      dashboard = ReceivablesDashboard.new(emission_month: "2025-02", competence_months: [ "2025-01" ])
      dashboard.instance_variable_set(:@all_records, records)

      assert_equal [ "2025-01", "2025-02" ], dashboard.available_competence_months
      assert_equal 1, dashboard.records.size
      assert_equal 1_000.to_d, dashboard.totals[:gross]
      assert_equal 100.to_d, dashboard.totals[:contingency]
      assert_equal 50.to_d, dashboard.totals[:outstanding]
      assert_equal 800.to_d, dashboard.totals[:paid]
      assert_equal 10.to_d, dashboard.contingency_rate
    end

    private

    def record(emission:, competence:, gross:, paid:, contingency: 0, outstanding: 0)
      ReceivableWorkbook::Record.new(
        source: "sample.xlsb",
        source_row: 2,
        client_code: "123",
        client: "123-Cliente Teste-MAO DE OBRA",
        cost_center: "1-Centro",
        invoice_number: emission.day.to_s,
        rps: "10",
        emission_date: emission,
        bank: "Banco",
        competence: competence,
        competence_text: competence.to_s,
        status: "",
        gross: gross.to_d,
        contingency: contingency.to_d,
        outstanding: outstanding.to_d,
        reconciliation_status: "OK",
        paid: paid.to_d,
        payment_date: emission + 15.days
      )
    end
  end
end
