require "test_helper"

module Esocial
	class LotacoesControllerTest < ActionDispatch::IntegrationTest
		test "renders lotacoes dashboard" do
			get esocial_lotacoes_path

			assert_response :success
			assert_select "h1", "Lotacao Tributaria"
			assert_select "body", /S-1020/
			assert_select "body", /FPAS/
			assert_select "body", /0001/
			assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
		end
	end
end
