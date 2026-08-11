module FiscalAuditor
  class PayrollController < BaseController
    def show
      @dashboard = PayrollDashboard.new(
        periods: params[:periods],
        client_code: params[:client_code],
        statuses: params[:statuses],
        page: params[:page],
        company: current_fiscal_auditor_company
      )
    end
  end
end
