module FiscalAuditor
  class BaseController < ApplicationController
    layout "fiscal_auditor"
    before_action :require_fiscal_auditor

    helper_method :fiscal_auditor_signed_in?

    private

    def require_fiscal_auditor
      redirect_to fiscal_auditor_login_path, alert: "Entre para acessar a central de auditoria." unless fiscal_auditor_signed_in?
    end

    def fiscal_auditor_signed_in?
      session[:fiscal_auditor] == true
    end
  end
end
