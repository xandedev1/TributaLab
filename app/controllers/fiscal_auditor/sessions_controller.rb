require "digest"

module FiscalAuditor
  class SessionsController < BaseController
    skip_before_action :require_fiscal_auditor, only: %i[new create]
    rate_limit to: 8, within: 3.minutes, only: :create, with: -> { redirect_to fiscal_auditor_login_path, alert: "Muitas tentativas. Aguarde alguns minutos." }

    def new
      redirect_to fiscal_auditor_root_path if fiscal_auditor_signed_in?
    end

    def create
      if valid_credentials?
        reset_session
        session[:fiscal_auditor] = true
        redirect_to fiscal_auditor_root_path, notice: "Acesso liberado."
      else
        flash.now[:alert] = "Usuário ou senha inválidos."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to fiscal_auditor_login_path, notice: "Sessão encerrada."
    end

    private

    def valid_credentials?
      valid_users = {
        "Xande" => ENV.fetch("FISCAL_AUDITOR_PASSWORD_XANDE", "123321"),
        "Lobo" => ENV.fetch("FISCAL_AUDITOR_PASSWORD_LOBO", "Ale180306@")
      }
      
      expected_password = valid_users[params[:username]]
      return false unless expected_password
      
      secure_match?(params[:password], expected_password)
    end

    def secure_match?(candidate, expected)
      ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(candidate.to_s),
        Digest::SHA256.hexdigest(expected)
      )
    end
  end
end
