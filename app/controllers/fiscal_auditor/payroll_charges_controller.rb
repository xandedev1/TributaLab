module FiscalAuditor
  class PayrollChargesController < BaseController
    def show
      @dashboard = PayrollChargesDashboard.new(periods: params[:periods], company: current_fiscal_auditor_company)
      @available_periods = @dashboard.available_periods
    end
  end
end
