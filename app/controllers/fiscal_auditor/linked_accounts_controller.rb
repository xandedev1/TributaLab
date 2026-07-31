module FiscalAuditor
  class LinkedAccountsController < BaseController
    def show
      @dashboard = LinkedAccountsDashboard.new
    end
  end
end
