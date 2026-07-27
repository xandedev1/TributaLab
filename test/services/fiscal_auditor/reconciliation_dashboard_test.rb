require "test_helper"

module FiscalAuditor
  class ReconciliationDashboardTest < ActiveSupport::TestCase
    test "classifies matched divergent and missing invoices" do
      dashboard = ReconciliationDashboard.new
      dashboard.instance_variable_set(:@billing_records, [
        billing_record("1", gross: 100, net: 80),
        billing_record("2", gross: 200, net: 160),
        billing_record("3", gross: 300, net: 240)
      ])
      dashboard.instance_variable_set(:@receivable_records, [
        receivable_record("1", gross: 100, paid: 80),
        receivable_record("2", gross: 210, paid: 150),
        receivable_record("4", gross: 400, paid: 320)
      ])

      assert_equal 4, dashboard.document_count
      assert_equal({ matched: 1, divergent: 1, missing_receivable: 1, missing_billing: 1 }, dashboard.status_counts)
      assert_in_delta 66.67, dashboard.match_rate, 0.01
      assert_equal 600.to_d, dashboard.totals[:billing_gross]
      assert_equal 710.to_d, dashboard.totals[:receivable_gross]
      assert_equal 110.to_d, dashboard.totals[:gross_difference]
      assert_equal 70.to_d, dashboard.totals[:selected_difference]
      assert_equal "net", dashboard.billing_value_type
      assert_equal "net", dashboard.receivable_value_type
    end

    test "filters emission and competence independently for each source" do
      dashboard = ReconciliationDashboard.new(
        billing_emission_periods: [ "2025" ],
        billing_competence_periods: [ "2025-01" ],
        receivable_emission_periods: [ "2024-02" ],
        receivable_competence_periods: [ "2023" ]
      )
      dashboard.instance_variable_set(:@all_billing_records, [
        billing_record("1", gross: 100, net: 80),
        billing_record("2", gross: 200, net: 160, competence: Date.new(2025, 2, 1))
      ])
      dashboard.instance_variable_set(:@all_receivable_records, [
        receivable_record("1", gross: 100, paid: 80, emission: Date.new(2024, 2, 2), competence: Date.new(2023, 12, 1)),
        receivable_record("2", gross: 200, paid: 160, emission: Date.new(2024, 3, 2), competence: Date.new(2023, 12, 1))
      ])

      assert_equal [ "2025" ], dashboard.billing_emission_periods
      assert_equal [ "2025-01" ], dashboard.billing_competence_periods
      assert_equal [ "2024-02" ], dashboard.receivable_emission_periods
      assert_equal [ "2023" ], dashboard.receivable_competence_periods
      assert_equal [ "1" ], dashboard.entries.map { |entry| entry[:invoice_number] }
      assert_equal :matched, dashboard.entries.first[:status]
    end

    test "compares the selected value types and defaults invalid values to net" do
      dashboard = ReconciliationDashboard.new(billing_value_type: "gross", receivable_value_type: "net")
      dashboard.instance_variable_set(:@billing_records, [ billing_record("1", gross: 100, net: 80) ])
      dashboard.instance_variable_set(:@receivable_records, [ receivable_record("1", gross: 100, paid: 80) ])

      assert_equal "gross", dashboard.billing_value_type
      assert_equal "net", dashboard.receivable_value_type
      assert_equal 100.to_d, dashboard.entries.first[:billing_value]
      assert_equal 80.to_d, dashboard.entries.first[:receivable_value]
      assert_equal(-20.to_d, dashboard.entries.first[:selected_difference])
      assert_equal :divergent, dashboard.entries.first[:status]

      invalid = ReconciliationDashboard.new(billing_value_type: "other", receivable_value_type: nil)
      assert_equal "net", invalid.billing_value_type
      assert_equal "net", invalid.receivable_value_type
    end

    private

    def billing_record(invoice, gross:, net:, emission: Date.new(2025, 1, 2), competence: Date.new(2025, 1, 1))
      RetentionWorkbook::Record.new(
        source: "billing.xlsx", source_row: 2, cnpj: "12.345.678/0001-90", client_code: "123",
        client: "Cliente Teste", rps: "10", invoice_number: invoice, emission_date: emission,
        competence: competence, status: "", billed: gross.to_d, inss: 0.to_d, irrf: 0.to_d,
        pis: 0.to_d, cofins: 0.to_d, csll: 0.to_d, iss: 0.to_d, net: net.to_d
      )
    end

    def receivable_record(
      invoice, gross:, paid:, emission: Date.new(2025, 1, 2), competence: Date.new(2025, 1, 1)
    )
      ReceivableWorkbook::Record.new(
        source: "receivables.xlsb", source_row: 2, client_code: "123", client: "123-Cliente Teste",
        cost_center: "1-Centro", invoice_number: invoice, rps: "10", emission_date: emission,
        bank: "Banco", competence: competence, competence_text: competence.strftime("%Y-%m"), status: "",
        gross: gross.to_d, contingency: 0.to_d, outstanding: 0.to_d, reconciliation_status: "OK",
        paid: paid.to_d, payment_date: Date.new(2025, 2, 2)
      )
    end
  end
end
