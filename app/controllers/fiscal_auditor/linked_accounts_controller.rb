module FiscalAuditor
  class LinkedAccountsController < BaseController
    def show
      @dashboard = LinkedAccountsDashboard.new(company: current_fiscal_auditor_company)
    end
  end
end
