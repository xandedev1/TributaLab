require "test_helper"

module FiscalAuditor
  class ExpensesDashboardTest < ActiveSupport::TestCase
    test "separates competence expenses and compares them with receipts in the same period" do
      records = [
        expense(sheet: "FUNCIONARIOS", identification: "Despesas Folha", competence: true, amount: 600, date: Date.new(2025, 1, 10)),
        expense(sheet: "FUNCIONARIOS", identification: "Acordo Judicial", competence: false, amount: 150, date: Date.new(2025, 1, 12)),
        expense(sheet: "FORNECEDORES", identification: "Tributos", competence: true, amount: 250, date: Date.new(2025, 1, 15)),
        expense(sheet: "FORNECEDORES", identification: "Parcelamentos Tributários", competence: false, amount: 100, date: Date.new(2025, 2, 2))
      ]
      dashboard = ExpensesDashboard.new(
        periods: [ "2025-01" ],
        expense_records: records,
        receivable_records: [ receivable(paid: 1_100, date: Date.new(2025, 1, 20)), receivable(paid: 400, date: Date.new(2025, 2, 20)) ]
      )

      assert_equal 3, dashboard.records.size
      assert_equal 850.to_d, dashboard.totals[:competence]
      assert_equal 150.to_d, dashboard.totals[:non_competence]
      assert_equal 1_000.to_d, dashboard.totals[:paid]
      assert_equal 1_100.to_d, dashboard.totals[:received]
      assert_equal 250.to_d, dashboard.competence_balance
      assert_equal 100.to_d, dashboard.cash_balance
    end

    test "filters the explorer by source and identification" do
      records = [
        expense(sheet: "FUNCIONARIOS", identification: "Despesas Folha", competence: true, amount: 600),
        expense(sheet: "FORNECEDORES", identification: "Despesas Folha", competence: true, amount: 250),
        expense(sheet: "FORNECEDORES", identification: "Despesas Gerais", competence: true, amount: 100)
      ]
      dashboard = ExpensesDashboard.new(
        source_sheet: "FORNECEDORES",
        identification: "Despesas Folha",
        expense_records: records,
        receivable_records: []
      )

      assert_equal 1, dashboard.records.size
      assert_equal 250.to_d, dashboard.totals[:paid]
      assert_equal [ "Despesas Folha", "Despesas Gerais" ], dashboard.available_identifications
    end

    private

    def expense(sheet:, identification:, competence:, amount:, date: Date.new(2025, 1, 10))
      ExpenseWorkbook::Record.new(
        source: "sample.xlsb",
        source_sheet: sheet,
        source_row: 2,
        due_date: date - 5.days,
        payment_date: date,
        party: "Favorecido",
        client: "Cliente",
        document: "123",
        description: "Descrição",
        identification: identification,
        competence_expense: competence,
        amount: amount.to_d
      )
    end

    def receivable(paid:, date:)
      ReceivableWorkbook::Record.new(
        source: "sample.xlsb",
        source_row: 2,
        client_code: "1",
        client: "Cliente",
        cost_center: "Centro",
        invoice_number: "1",
        rps: "1",
        emission_date: date - 10.days,
        bank: "Banco",
        competence: date.beginning_of_month,
        competence_text: "",
        status: "",
        gross: paid.to_d,
        contingency: 0.to_d,
        outstanding: 0.to_d,
        reconciliation_status: "OK",
        paid: paid.to_d,
        payment_date: date
      )
    end
  end
end
