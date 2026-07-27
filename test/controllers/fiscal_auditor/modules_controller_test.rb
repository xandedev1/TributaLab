require "test_helper"

module FiscalAuditor
  class ModulesControllerTest < ActionDispatch::IntegrationTest
    test "protects all financial modules" do
      get fiscal_auditor_receivables_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_reconciliation_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_expenses_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_expense_explorer_path
      assert_redirected_to fiscal_auditor_login_path
    end

    test "renders authenticated financial modules from their real sources" do
      post fiscal_auditor_login_path, params: { username: "Xande", password: "123321" }

      get fiscal_auditor_receivables_path
      assert_response :success
      assert_select "h1", "Contas a receber"
      assert_select "a.fa-nav__item--active", "Contas a receber"
      assert_select ".fa-kpi p", "Bruto lançado"
      assert_select ".fa-kpi p", "Recebido real"
      assert_select ".fa-table--receivables tbody tr", minimum: 1

      get fiscal_auditor_reconciliation_path
      assert_response :success
      assert_select "h1", "Faturamento × recebimentos"
      assert_select "a.fa-nav__item--active", "Cruzamento"
      assert_select ".fa-source-filter", count: 2
      assert_select ".fa-period-select", count: 4
      assert_select ".fa-value-select", count: 2
      assert_select ".fa-comparison h2", "Líquido faturado × recebido real"
      assert_select ".fa-table--reconciliation tbody tr", count: 100
      assert_select ".fa-pagination", text: /Exibindo 1–100 de 25\.074/
      assert_select ".fa-pagination a[rel='next']", "Próxima"

      get fiscal_auditor_expenses_path, params: { periods: [ "2025-01" ] }
      assert_response :success
      assert_select "h1", "Dashboard de despesas"
      assert_select "a.fa-nav__item--active", "Dashboard de despesas"
      assert_select ".fa-kpi p", "Recebido real"
      assert_select ".fa-kpi p", "Despesas de competência"
      assert_select ".fa-kpi p", "Despesas de não competência"
      assert_select ".fa-kpi p", "Total pago no período"
      assert_select "a.fa-tax--expense", minimum: 1

      get fiscal_auditor_expense_explorer_path, params: { periods: [ "2025-01" ], identification: "Despesas Gerais" }
      assert_response :success
      assert_select "h1", "Explorador de despesas"
      assert_select "a.fa-nav__item--active", "Explorador de despesas"
      assert_select "select[name='identification'] option[selected]", "Despesas Gerais"
      assert_select ".fa-table--expenses tbody tr", maximum: 100, minimum: 1
      assert_select ".fa-table--expenses .fa-status", text: "Competência"
      assert_select ".fa-pagination"
    end
  end
end
