require "test_helper"

module Esocial
	class EstabelecimentosObrasControllerTest < ActionDispatch::IntegrationTest
		test "renders estabelecimentos e obras dashboard" do
			get esocial_estabelecimentos_obras_path

			assert_response :success
			assert_select "h1", "Estabelecimentos e Obras"
			assert_select "body", /S-1005/
			assert_select "body", /CNAE/
			assert_select "body", /FAP/
			assert_select "body", /2023-01/
			assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
		end
	end
end
