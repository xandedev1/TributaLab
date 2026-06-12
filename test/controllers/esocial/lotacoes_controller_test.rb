require "test_helper"

module Esocial
	class LotacoesControllerTest < ActionDispatch::IntegrationTest
		test "renders lotacoes dashboard" do
			get esocial_lotacoes_path

			assert_response :success
			assert_select "h1", "Lotacao Tributaria"
			assert_select "body", /S-1020/
			assert_select "body", /FPAS/
			assert_match(/Nenhuma fonte real S-1020 carregada|XML CTE ZIP|CSV capturado|SECTECENT200/, response.body)
			if Rails.root.join("tmp", "lotacoes_s1020_cte_zips", "lotacoes_s1020_eventos.csv").exist?
				assert_match(/XML CTE ZIP/, response.body)
				assert_match(/SECTECENT200/, response.body)
			elsif Rails.root.join("tmp", "lotacoes_s1020", "lotacoes_s1020_eventos.csv").exist?
				assert_match(/000200000000/, response.body)
				assert_match(/SECTECENT20000000000000000008/, response.body)
				assert_match(/90\.021\.78582\/78/, response.body)
				assert_match(/exclusao/, response.body)
			end
			assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
		end
	end
end
