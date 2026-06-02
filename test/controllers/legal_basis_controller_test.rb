require "test_helper"

class LegalBasisControllerTest < ActionDispatch::IntegrationTest
	test "renders legal basis workbook tabs" do
		get legal_basis_path

		assert_response :success
		assert_select "h1", "Base Legal"
		assert_select "body", /Resumo/
		assert_select "body", /Rubricas/
		assert_select "body", /Art\. 18/
		assert_select "a", "Tela cheia"
		assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
	end

	test "renders selected workbook sheet" do
		get legal_basis_path(sheet: "IRPF")

		assert_response :success
		assert_select "h2", "IRPF"
		assert_select "body", /Terço Constitucional de Férias/
	end

	test "renders fullscreen table mode for selected workbook sheet" do
		get legal_basis_path(sheet: "FGTS", fullscreen: 1)

		assert_response :success
		assert_select ".tl-legal-panel--fullscreen"
		assert_select "a", "Sair da tela cheia"
		assert_select "a[href=?]", legal_basis_path(sheet: "IRPF", fullscreen: 1), "IRPF"
	end
end