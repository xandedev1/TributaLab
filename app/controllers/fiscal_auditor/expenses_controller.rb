module FiscalAuditor
  class ExpensesController < BaseController
    def show
      @dashboard = ExpensesDashboard.new(periods: params[:periods], company: current_fiscal_auditor_company)
    end
  end
end
