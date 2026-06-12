require "test_helper"

module Esocial
	class PreflightControllerTest < ActionDispatch::IntegrationTest
		test "renders simple certificate page" do
			get esocial_certificado_path

			assert_response :success
			assert_select "h1", "Certificado"
			assert_select "body", /Salvar certificado/
			assert_select "body", /Arquivo \.pfx ou \.p12/
			assert_select "body", /Senha/
			assert_select "input[value='Salvar']"
			assert_select "body", /Nenhum certificado salvo/
			assert_no_match(/Testar este certificado/i, response.body)
			assert_no_match(/Pre-voo|pre-voo|Checklist da CTE|Vinculo CTE|Procuracao para CTE|Inventario legado/i, response.body)
		end

		test "shows saved certificate as ready" do
			EsocialCertificate.create!(
				label: "Certificado A1",
				holder_name: "EMPRESA TESTE:64030638000158",
				holder_cnpj: "64030638000158",
				sha256: "a" * 64,
				storage_path: Rails.root.join("tmp", "cte.pfx").to_s,
				not_before: 1.day.ago,
				expires_at: 1.year.from_now,
				status: "valid",
				parse_status: "ok"
			)
			get esocial_certificado_path

			assert_response :success
			assert_select "body", /Certificado A1/
			assert_select "body", /EMPRESA TESTE/
			assert_select "body", /Pronto/
			assert_select "body", /Teste oficial/
			assert_select "button", "Testar este certificado"
		end
	end
end