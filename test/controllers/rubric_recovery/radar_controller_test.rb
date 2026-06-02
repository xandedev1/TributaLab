require "test_helper"

module RubricRecovery
	class RadarControllerTest < ActionDispatch::IntegrationTest
		test "renders read only radar with real workbook numbers" do
			get rubric_recovery_radar_path

			assert_response :success
			assert_select "h1", "Radar de Recuperacao - Rubricas eSocial"
			assert_select "body", /Etapa 004B/
			assert_select "body", /464 eventos analisados/
			assert_select "body", /247 com pelo menos uma divergencia/
			assert_select "body", /224 registros\/eventos divergentes com confianca alta\/media/
			assert_select "body", /140 divergencias CP\/INSS/
			assert_select "body", /245 divergencias IRRF/
			assert_select "body", /126 divergencias FGTS/
			assert_select "body", /217 sem divergencia CP\/IRRF\/FGTS/
			assert_select "body", /247 registros no filtro/
			assert_select "body", /Horas Férias Diurnas/
			assert_select "body", /MEDIA VALORES/
			assert_select "body", /CTE\/enquadramento presente/
			assert_select "body", /S-1010 pendente/
			assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
		end

		test "filters real workbook rows by tax" do
			get rubric_recovery_radar_path(tax: "fgts")

			assert_response :success
			assert_select "body", /126 registros no filtro/
			assert_select "body", /Pró-Labore/
		end
	end
end