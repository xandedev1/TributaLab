require "test_helper"

module FiscalAuditor
  class ModulesControllerTest < ActionDispatch::IntegrationTest
    test "protects all financial modules" do
      get fiscal_auditor_receivables_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_reconciliation_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_payroll_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_payroll_charges_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_payroll_detail_path(client_code: "492", period: "2025-01")
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_expenses_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_expense_explorer_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_calculation_detail_path("reconciliation", "selected_difference")
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_spreadsheet_path(source_kind: "billing", filename: "source.xlsx")
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
      assert_select "a.fa-detail-hit[href*='memoria-de-calculo/receivables']", count: 4
      assert_select "a.fa-tax--detail[href*='detail_category']", minimum: 1
      assert_select "a.fa-ranking__row--detail[href*='detail_client_code']", count: 10

      get fiscal_auditor_root_path
      assert_response :success
      assert_select "a.fa-detail-hit[href*='memoria-de-calculo/billing']", count: 4
      assert_select "a.fa-tax--detail[href*='memoria-de-calculo/billing']", count: 6
      assert_select "a.fa-ranking__row--detail[href*='detail_cnpj']", count: 8

      get fiscal_auditor_reconciliation_path
      assert_response :success
      assert_select "h1", "Faturamento × recebimentos"
      assert_select "a.fa-nav__item--active", "Cruzamento"
      assert_select ".fa-source-filter", count: 2
      assert_select ".fa-period-select", count: 4
      assert_select ".fa-value-select", count: 2
      assert_select ".fa-comparison h2", "Líquido faturado × recebido real"
      assert_select ".fa-table--reconciliation tbody tr", count: 100
      assert_select ".fa-pagination", text: /Exibindo 1–100 de 25\.123/
      assert_select ".fa-pagination a[rel='next']", "Próxima"
      assert_select "a.fa-detail-hit[href*='memoria-de-calculo/reconciliation']", minimum: 8
      assert_select ".fa-comparison a.fa-metric-link", count: 3

      get fiscal_auditor_payroll_path
      assert_response :success
      assert_select "h1", "Folha"
      assert_select "a.fa-nav__item--active", "Folha"
      assert_select ".fa-kpi p", "Total de vencimentos"
      assert_select ".fa-kpi p", "Total de descontos"
      assert_select ".fa-kpi p", "Folha líquida"
      assert_select ".fa-kpi p", "Faturamento líquido"
      assert_select ".fa-payroll-warning", text: /Dezembro parcial/
      assert_select ".fa-table--payroll tbody tr", count: 100
      assert_select ".fa-pagination a[rel='next']", "Próxima"
      assert_select "a.fa-detail-hit[href*='memoria-de-calculo/payroll']", count: 5
      assert_select ".fa-payroll-statuses a[href*='memoria-de-calculo/payroll']", count: 3
      assert_select ".fa-payroll-month-list a[href*='memoria-de-calculo/payroll']", count: 12
      assert_select ".fa-status-select input[name='statuses[]']", count: 4
      assert_select ".fa-filters--payroll .fa-status-select", count: 0
      assert_select ".fa-payroll-table__tools .fa-status-select", count: 1
      assert_select ".fa-table-row--link[data-href*='folha/detalhamento']", count: 100
      assert_select "a.fa-row-detail-link[href*='folha/detalhamento']", count: 100

      get fiscal_auditor_payroll_path, params: { periods: [ "2025-01" ], client_code: "335" }
      assert_response :success
      assert_select "select[name='client_code'] option[selected][value='335']"
      assert_select ".fa-table--payroll tbody tr", count: 1
      assert_select ".fa-table--payroll tbody tr", text: /MUNICIPIO DE SALVADOR/

      get fiscal_auditor_payroll_detail_path(client_code: "492", period: "2025-01", return_to: fiscal_auditor_payroll_path)
      assert_response :success
      assert_select "h1", "Cliente × folha × faturamento"
      assert_select ".fa-cross-detail-hero h2", "FUNDACAO MUNICIPAL DE CULTURA DE TUBARAO"
      assert_select ".fa-table--payroll-events tbody tr", minimum: 1
      assert_select ".fa-table--payroll-invoices tbody tr", minimum: 1
      assert_select "a.fa-source-link[href*='source_kind=payroll']", minimum: 1
      assert_select "a.fa-source-link[href*='source_kind=billing']", minimum: 1
      assert_select "a.fa-back-link[href='#{fiscal_auditor_payroll_path}']"

      filtered_return_path = "#{fiscal_auditor_payroll_path}?periods%5B%5D=2025-01&client_code=492"
      get fiscal_auditor_payroll_detail_path(client_code: "492", period: "2025-01", return_to: filtered_return_path)
      assert_response :success
      assert_select "a.fa-back-link[href='#{filtered_return_path}']"

      get fiscal_auditor_payroll_detail_path(client_code: "492", period: "2025-01", return_to: "/auditor-fiscal/%2e%2e/admin")
      assert_response :success
      assert_select "a.fa-back-link[href='#{fiscal_auditor_payroll_path}']"

      get fiscal_auditor_payroll_detail_path(client_code: "1", period: "2025-01")
      assert_response :success
      assert_select ".fa-status--missing_billing", "Sem faturamento"
      assert_select ".fa-table--payroll-events tbody tr", minimum: 1
      assert_select ".fa-table--payroll-invoices", count: 0
      assert_select ".fa-cross-detail-empty", text: /Nenhuma nota encontrada/

      get fiscal_auditor_payroll_path, params: { statuses: %w[deficit missing_billing] }
      assert_response :success
      assert_select "#statuses_deficit[checked]"
      assert_select "#statuses_missing_billing[checked]"
      assert_select ".fa-filterbar__count strong", "557"
      assert_select ".fa-table--payroll .fa-status--covered", count: 0

      get fiscal_auditor_calculation_detail_path("payroll", "net"), params: { periods: [ "2025-01" ], client_code: "335" }
      assert_response :success
      assert_select ".fa-calculation-hero h2", "Folha líquida"
      assert_select ".fa-calculation-components article", count: 2
      assert_select ".fa-table--payroll-memory tbody tr", minimum: 1
      assert_select "a.fa-source-link[href*='source_kind=payroll']", minimum: 1

      get fiscal_auditor_calculation_detail_path("payroll", "deficit")
      assert_response :success
      assert_select ".fa-column-totals", count: 1
      assert_select ".fa-column-totals h3", text: /Total das .* linhas filtradas/
      assert_select ".fa-column-totals dl > div", count: 5
      assert_select ".fa-table--payroll-memory .fa-table-total", count: 1
      assert_select ".fa-table-total th", text: /Total das .* linhas filtradas/
      assert_select ".fa-table-total td", count: 6

      get fiscal_auditor_calculation_detail_path("reconciliation", "selected_difference")
      assert_response :success
      assert_select "h1", "Memória de cálculo"
      assert_select ".fa-calculation-hero h2", "Diferença selecionada"
      assert_select ".fa-calculation-components article", count: 2
      assert_select ".fa-table--calculation tbody tr", count: 100
      assert_select ".fa-table--calculation th", text: "Fonte do faturamento"
      assert_select ".fa-table--calculation th", text: "Fonte do recebimento"
      assert_select ".fa-pagination a[rel='next']", "Próxima"
      assert_select "a.fa-source-reference[href*='visualizador-de-planilha']", minimum: 1

      get fiscal_auditor_expenses_path, params: { periods: [ "2025-01" ] }
      assert_response :success
      assert_select "h1", "Dashboard de despesas"
      assert_select "a.fa-nav__item--active", "Dashboard de despesas"
      assert_select ".fa-kpi p", "Recebido real"
      assert_select ".fa-kpi p", "Despesas de competência"
      assert_select ".fa-kpi p", "Despesas de não competência"
      assert_select ".fa-kpi p", "Total pago no período"
      assert_select "a.fa-detail-hit[href*='memoria-de-calculo/expenses']", count: 6
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

    test "shows every stage of the monthly payroll charge calculation" do
      post fiscal_auditor_login_path, params: { username: "Xande", password: "123321" }

      get fiscal_auditor_payroll_charges_path, params: { periods: [ "2025-01" ] }

      assert_response :success
      assert_select "h1", "Descontos e encargos"
      assert_select ".fa-payroll-tab--active", "Descontos e encargos"
      assert_select ".fa-charge-equation__flow > div", count: 5
      assert_select ".fa-charge-equation__result", text: /R\$ 34\.208\.668,43/
      assert_select ".fa-charge-kpis article", count: 5
      assert_select ".fa-table--charges tbody tr", count: 1
      assert_select ".fa-charge-month[open]", count: 1
      assert_select ".fa-charge-steps li", count: 7
      assert_select ".fa-charge-evidence > section", count: 3
      assert_select "a.fa-source-reference[href*='source_kind=payroll_charges']", minimum: 10
      assert_select "a.fa-source-reference[href*='source_kind=payroll']", minimum: 1
      assert_select ".fa-charge-method-note", text: /sem criar rateio por cliente/
    end

    test "opens only an authorized source and highlights its physical row" do
      post fiscal_auditor_login_path, params: { username: "Xande", password: "123321" }
      source = Dashboard.source_paths.first

      get fiscal_auditor_spreadsheet_path(
        source_kind: "billing", filename: File.basename(source), row: 10,
        return_to: fiscal_auditor_calculation_detail_path("billing", "net")
      )

      assert_response :success
      assert_select "h1", "Visualizador de planilha"
      assert_select ".fa-sheet-title strong", File.basename(source)
      assert_select ".fa-spreadsheet-grid thead th", text: "A"
      assert_select "tr.fa-sheet-row--focused[data-spreadsheet-viewer-target='focusedRow'] th", "10"
      assert_select ".fa-sheet-tabs a.fa-sheet-tab--active", "Planilha1"
      assert_select "a.fa-back-link[href='#{fiscal_auditor_calculation_detail_path("billing", "net")}']"

      get fiscal_auditor_spreadsheet_path(source_kind: "billing", filename: "../../config/database.yml")
      assert_response :not_found

      payroll_source = PayrollDashboard.source_paths.first
      get fiscal_auditor_spreadsheet_path(source_kind: "payroll", filename: File.basename(payroll_source), row: 3)
      assert_response :success
      assert_select ".fa-sheet-title strong", File.basename(payroll_source)
      assert_select "tr.fa-sheet-row--focused th", "3"
    end
  end
end
