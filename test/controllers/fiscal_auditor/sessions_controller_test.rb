require "test_helper"

module FiscalAuditor
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "protects dashboard and renders independent login" do
      get fiscal_auditor_root_path

      assert_redirected_to fiscal_auditor_login_path

      follow_redirect!
      assert_response :success
      assert_select "h2", "Acessar auditoria"
      assert_select "link[rel='stylesheet']", count: 1
    end

    test "rejects invalid credentials" do
      post fiscal_auditor_login_path, params: { username: "Xande", password: "invalid" }

      assert_response :unprocessable_entity
      assert_select ".fa-toast--alert", "Usuário ou senha inválidos."
    end

    test "creates and destroys fiscal auditor session" do
      post fiscal_auditor_login_path, params: { username: "Xande", password: "123321" }
      assert_redirected_to fiscal_auditor_root_path

      follow_redirect!
      assert_response :success
      assert_select "h1", "Painel de retenções"

      delete fiscal_auditor_logout_path
      assert_redirected_to fiscal_auditor_login_path

      get fiscal_auditor_root_path
      assert_redirected_to fiscal_auditor_login_path
    end
  end
end
