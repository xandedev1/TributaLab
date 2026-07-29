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
      assert_equal({ file: "billing.xlsx", row: 2, value: 80.to_d }, detail.result.rows.find { |entry| entry[:invoice_number] == "1" }[:billing_sources].first)
      assert_equal({ file: "receivables.xlsb", row: 2, value: 80.to_d }, detail.result.rows.find { |entry| entry[:invoice_number] == "1" }[:receivable_sources].first)
    end

    test "isolates the exact entries behind reconciliation statuses" do
      matched = calculation_detail("matched").result
      divergent = calculation_detail("divergent").result
      missing = calculation_detail("missing_receivable").result

      assert_equal [ "1" ], matched.rows.map { |entry| entry[:invoice_number] }
      assert_equal [ "2" ], divergent.rows.map { |entry| entry[:invoice_number] }
      assert_equal [ "3" ], missing.rows.map { |entry| entry[:invoice_number] }
    end

    test "recomposes billing values from original documents" do
      records = [ billing_record("1", net: 80), billing_record("2", net: 100) ]
      detail = CalculationDetail.new(module_name: "billing", metric: "net", billing_records: records)

      assert_equal 180.to_d, detail.result.value
      assert_equal detail.result.value, detail.result.rows.sum(&:net)
      assert_equal "billing.xlsx", detail.result.rows.first.source
    end

    test "recomposes received value from original notes" do
      records = [ receivable_record("1", paid: 80), receivable_record("2", paid: 120) ]
      detail = CalculationDetail.new(module_name: "receivables", metric: "paid", receivable_records: records)

      assert_equal 200.to_d, detail.result.value
      assert_equal detail.result.value, detail.result.rows.sum(&:paid)
      assert_equal "receivables.xlsb", detail.result.rows.first.source
    end

    test "recomposes expense cash balance with signed source rows" do
      receipts = [ receivable_record("1", paid: 200) ]
      expenses = [ expense_record(competence: true, amount: 80), expense_record(competence: false, amount: 30) ]
      detail = CalculationDetail.new(
        module_name: "expenses", metric: "cash_balance", params: { periods: [ "2025-02" ] },
        receivable_records: receipts, expense_records: expenses
      )

      assert_equal 90.to_d, detail.result.value
      assert_equal detail.result.value, detail.result.rows.sum { |row| row[:signed_value] }
      assert_equal [ "Recebido real", "Saídas deduzidas" ], detail.result.components.map { |component| component[:label] }
    end

    test "applies client and category drilldown filters" do
      billing = [
        billing_record("1", net: 80, cnpj: "11.111.111/0001-11"),
        billing_record("2", net: 100, cnpj: "22.222.222/0001-22")
      ]
      billing_detail = CalculationDetail.new(
        module_name: "billing", metric: "billed", params: { detail_cnpj: "22.222.222/0001-22" }, billing_records: billing
      )
      receivables = [
        receivable_record("1", paid: 80, client: "123-Fornecimento Teste"),
        receivable_record("2", paid: 120, client: "456-Mão de Obra Teste")
      ]
      receivable_detail = CalculationDetail.new(
        module_name: "receivables", metric: "gross", params: { detail_category: "Fornecimento" }, receivable_records: receivables
      )

      assert_equal [ "2" ], billing_detail.result.rows.map(&:invoice_number)
      assert_equal [ "1" ], receivable_detail.result.rows.map(&:invoice_number)
    end

    test "totals every filtered payroll comparison row before pagination" do
      payroll = 101.times.map do |index|
        payroll_record(client_code: (index + 1).to_s, amount: 100)
      end
      billing = 101.times.map do |index|
        billing_record((index + 1).to_s, net: 50, client_code: (index + 1).to_s)
      end
      result = CalculationDetail.new(
        module_name: "payroll", metric: "deficit",
        payroll_records: payroll, billing_records: billing
      ).result

      assert_equal 101, result.total_rows
      assert_equal 100, result.rows.size
      assert_equal 10_100.to_d, result.column_totals[:earnings]
      assert_equal 0.to_d, result.column_totals[:discounts]
      assert_equal 10_100.to_d, result.column_totals[:payroll_net]
      assert_equal 5_050.to_d, result.column_totals[:billing_net]
      assert_equal(-5_050.to_d, result.column_totals[:formula_value])
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

    def billing_record(invoice, net:, cnpj: "12.345.678/0001-90", client_code: "123")
      RetentionWorkbook::Record.new(
        source: "billing.xlsx", source_row: invoice.to_i + 1, cnpj: cnpj, client_code: client_code,
        client: "Cliente Teste", rps: "10", invoice_number: invoice, emission_date: Date.new(2025, 1, 2),
        competence: Date.new(2025, 1, 1), status: "", billed: (net + 20).to_d, inss: 20.to_d,
        irrf: 0.to_d, pis: 0.to_d, cofins: 0.to_d, csll: 0.to_d, iss: 0.to_d, net: net.to_d
      )
    end

    def payroll_record(client_code:, amount:)
      PayrollWorkbook::Record.new(
        source: "payroll.xlsx", source_row: client_code.to_i + 1, company: "001",
        client_code: client_code, client: "Cliente #{client_code}", event_code: "1",
        event_description: "Salário", event_type: "Vencimento",
        competence: Date.new(2025, 1, 1), amount: amount.to_d
      )
    end

    def receivable_record(invoice, paid:, client: "123-Cliente Teste")
      ReceivableWorkbook::Record.new(
        source: "receivables.xlsb", source_row: invoice.to_i + 1, client_code: "123", client: client,
        cost_center: "1-Centro", invoice_number: invoice, rps: "10", emission_date: Date.new(2025, 1, 2),
        bank: "Banco", competence: Date.new(2025, 1, 1), competence_text: "2025-01", status: "",
        gross: (paid + 20).to_d, contingency: 0.to_d, outstanding: 0.to_d, reconciliation_status: "OK",
        paid: paid.to_d, payment_date: Date.new(2025, 2, 2)
      )
    end

    def expense_record(competence:, amount:)
      ExpenseWorkbook::Record.new(
        source: "payables.xlsb", source_sheet: "FORNECEDORES", source_row: amount,
        due_date: Date.new(2025, 2, 1), payment_date: Date.new(2025, 2, 2), party: "Fornecedor",
        client: nil, document: amount.to_s, description: "Despesa", identification: "Categoria",
        competence_expense: competence, amount: amount.to_d
      )
    end
  end
end
