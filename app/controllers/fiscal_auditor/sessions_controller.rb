require "digest"

module FiscalAuditor
  class SessionsController < BaseController
    skip_before_action :require_fiscal_auditor, only: %i[new create]
    rate_limit to: 8, within: 3.minutes, only: :create, with: -> { redirect_to fiscal_auditor_login_path, alert: "Muitas tentativas. Aguarde alguns minutos." }

    def new
      redirect_to fiscal_auditor_root_path if fiscal_auditor_signed_in?
    end

    def create
      user = User.active.find_by("LOWER(username) = ?", params[:username].to_s.downcase)

      if user&.authenticate(params[:password].to_s)
        reset_session
        session[:fiscal_auditor] = true
        session[:fiscal_auditor_user_id] = user.id
        session[:fiscal_auditor_username] = user.username
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
  end
end
