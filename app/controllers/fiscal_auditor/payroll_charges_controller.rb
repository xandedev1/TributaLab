module FiscalAuditor
  class PayrollChargesController < BaseController
    def show
      @dashboard = PayrollChargesDashboard.new(periods: params[:periods])
      @available_periods = @dashboard.available_periods
    end
  end
end
