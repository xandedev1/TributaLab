module FiscalAuditor
  class ExpensesController < BaseController
    def show
      @dashboard = ExpensesDashboard.new(periods: params[:periods])
    end
  end
end
