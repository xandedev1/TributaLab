module FiscalAuditor
  class UniformsController < BaseController
    def show
      @dashboard = UniformsDashboard.new(company: current_fiscal_auditor_company)
    end
  end
end
