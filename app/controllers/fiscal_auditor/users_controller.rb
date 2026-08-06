module FiscalAuditor
  class UsersController < BaseController
    before_action :set_user, only: %i[edit update destroy]

    def index
      @users = User.order(:username)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to fiscal_auditor_users_path, notice: "Usuário #{@user.username} criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = user_params
      attrs.delete(:password) if attrs[:password].blank?

      if @user.update(attrs)
        redirect_to fiscal_auditor_users_path, notice: "Usuário #{@user.username} atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if User.active.count <= 1
        redirect_to fiscal_auditor_users_path, alert: "Não é possível remover o último usuário ativo."
        return
      end

      @user.update(active: false)
      redirect_to fiscal_auditor_users_path, notice: "Usuário #{@user.username} desativado."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:fiscal_auditor_user).permit(:username, :password, :name, :active)
    end
  end
end
