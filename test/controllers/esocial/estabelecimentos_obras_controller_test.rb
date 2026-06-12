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
			assert_select "body", /S-1005 XML|S-5011 oficial|Nenhuma fonte real carregada/
			if Rails.root.join("tmp", "estabelecimentos_s1005", "estabelecimentos_s1005_eventos.csv").exist?
				assert_select "body", /7112000/
				assert_select "body", /GILRAT\/RAT\s+3|RAT\s+3/
				assert_select "body", /64030638000158/
			end
			assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
		end
	end
end
