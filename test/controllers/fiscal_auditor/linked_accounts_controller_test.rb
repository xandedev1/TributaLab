require "test_helper"

module FiscalAuditor
  class LinkedAccountsControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated users to login" do
      get fiscal_auditor_linked_accounts_path
      assert_redirected_to fiscal_auditor_login_path
    end

    test "renders dashboard for authenticated user" do
      post fiscal_auditor_login_path, params: { username: "Xande", password: "123321" }
      follow_redirect!
      assert_response :success

      get fiscal_auditor_linked_accounts_path
      assert_response :success
      assert_match "Extrato Conta Vinculada", response.body
      assert_match "fa-sidebar", response.body
      assert_match "fa-kpis", response.body
    end
  end
end
