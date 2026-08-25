module FiscalAuditor
  class ExpenseExplorerController < BaseController
    def show
      @dashboard = ExpensesDashboard.new(
        periods: params[:periods],
        source_sheet: params[:source_sheet],
        identification: params[:identification],
        page: params[:page],
        company: current_fiscal_auditor_company
      )
    end
  end
end
