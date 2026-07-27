require "test_helper"

module FiscalAuditor
  class CalculationDetailTest < ActiveSupport::TestCase
    test "recomposes both sides and selected difference from reconciliation rows" do
      detail = calculation_detail("selected_difference")

      assert_equal 3, detail.result.total_rows
      assert_equal(-70.to_d, detail.result.value)
      assert_equal 270.to_d, detail.result.rows.sum { |entry| entry[:billing_value] }
      assert_equal 200.to_d, detail.result.rows.sum { |entry| entry[:receivable_value] }
      assert_equal(-70.to_d, detail.result.rows.sum { |entry| entry[:selected_difference] })
      assert_equal [ "Recebido real", "Líquido faturado" ], detail.result.components.map { |component| component[:label] }
    end

    test "isolates the exact entries behind reconciliation statuses" do
      matched = calculation_detail("matched").result
      divergent = calculation_detail("divergent").result
      missing = calculation_detail("missing_receivable").result

      assert_equal [ "1" ], matched.rows.map { |entry| entry[:invoice_number] }
      assert_equal [ "2" ], divergent.rows.map { |entry| entry[:invoice_number] }
      assert_equal [ "3" ], missing.rows.map { |entry| entry[:invoice_number] }
    end

    private

    def calculation_detail(metric)
      CalculationDetail.new(
        module_name: "reconciliation",
        metric: metric,
        billing_records: [
          billing_record("1", net: 80),
          billing_record("2", net: 100),
          billing_record("3", net: 90)
        ],
        receivable_records: [
          receivable_record("1", paid: 80),
          receivable_record("2", paid: 120)
        ]
      )
    end

    def billing_record(invoice, net:)
      RetentionWorkbook::Record.new(
        source: "billing.xlsx", source_row: invoice.to_i + 1, cnpj: "12.345.678/0001-90", client_code: "123",
        client: "Cliente Teste", rps: "10", invoice_number: invoice, emission_date: Date.new(2025, 1, 2),
        competence: Date.new(2025, 1, 1), status: "", billed: (net + 20).to_d, inss: 20.to_d,
        irrf: 0.to_d, pis: 0.to_d, cofins: 0.to_d, csll: 0.to_d, iss: 0.to_d, net: net.to_d
      )
    end

    def receivable_record(invoice, paid:)
      ReceivableWorkbook::Record.new(
        source: "receivables.xlsb", source_row: invoice.to_i + 1, client_code: "123", client: "123-Cliente Teste",
        cost_center: "1-Centro", invoice_number: invoice, rps: "10", emission_date: Date.new(2025, 1, 2),
        bank: "Banco", competence: Date.new(2025, 1, 1), competence_text: "2025-01", status: "",
        gross: (paid + 20).to_d, contingency: 0.to_d, outstanding: 0.to_d, reconciliation_status: "OK",
        paid: paid.to_d, payment_date: Date.new(2025, 2, 2)
      )
    end
  end
end