module FiscalAuditor
  class ReceivablesController < BaseController
    def show
      @dashboard = ReceivablesDashboard.new(
        emission_month: params[:emission_month],
        competence_months: params[:competence_months]
      )
    end
  end
end
