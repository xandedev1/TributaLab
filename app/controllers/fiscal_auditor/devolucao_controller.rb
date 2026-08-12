module FiscalAuditor
  class DevolucaoController < BaseController
    def show
      @dashboard = DevolucaoDashboard.new(company: current_fiscal_auditor_company)
      @selected_month = params[:month].presence
      @records = @dashboard.records(month: @selected_month)
    end
  end
end
