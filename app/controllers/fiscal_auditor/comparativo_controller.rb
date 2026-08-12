module FiscalAuditor
  class ComparativoController < BaseController
    def show
      @dashboard = ComparativoDashboard.new(company: current_fiscal_auditor_company)
      @monthly = @dashboard.monthly_comparison
      @totals = @dashboard.totals
    end
  end
end
