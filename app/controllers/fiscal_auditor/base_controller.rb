module FiscalAuditor
  class BaseController < ApplicationController
    layout "fiscal_auditor"
    before_action :require_fiscal_auditor
    before_action :require_fiscal_auditor_company

    helper_method :fiscal_auditor_signed_in?, :current_fiscal_auditor_company

    private

    def require_fiscal_auditor
      redirect_to fiscal_auditor_login_path, alert: "Entre para acessar a central de auditoria." unless fiscal_auditor_signed_in?
    end

    def require_fiscal_auditor_company
      return unless fiscal_auditor_signed_in?
      redirect_to fiscal_auditor_companies_path if session[:fiscal_auditor_company].blank?
    end

    def fiscal_auditor_signed_in?
      session[:fiscal_auditor] == true
    end

    def current_fiscal_auditor_company
      session[:fiscal_auditor_company].presence || "appa"
    end
  end
end
