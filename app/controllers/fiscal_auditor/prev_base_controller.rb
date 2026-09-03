module FiscalAuditor
  class PrevBaseController < BaseController
    def show
      company = current_fiscal_auditor_company
      @available = company == "appa"
      @dashboard = PrevBaseDashboard.new(company) if @available
    end
  end
end
