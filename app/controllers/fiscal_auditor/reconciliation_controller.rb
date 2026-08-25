module FiscalAuditor
  class ReconciliationController < BaseController
    def show
      @dashboard = ReconciliationDashboard.new(
        billing_emission_periods: params[:billing_emission_periods],
        billing_competence_periods: params[:billing_competence_periods],
        billing_value_type: params[:billing_value_type],
        receivable_emission_periods: params[:receivable_emission_periods],
        receivable_competence_periods: params[:receivable_competence_periods],
        receivable_value_type: params[:receivable_value_type],
        page: params[:page],
        company: current_fiscal_auditor_company
      )
    end
  end
end
