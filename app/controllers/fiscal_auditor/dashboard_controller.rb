module FiscalAuditor
  class DashboardController < BaseController
    def show
      @dashboard = Dashboard.new(
        emission_month: params[:emission_month],
        competence_months: params[:competence_months],
        company: current_fiscal_auditor_company
      )
    end
  end
end
