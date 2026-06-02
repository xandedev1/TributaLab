require "test_helper"

class TaxParametersControllerTest < ActionDispatch::IntegrationTest
  test "renders tax parameters index" do
    get tax_parameters_path

    assert_response :success
    assert_select "h1", "Parametros"
    assert_select "body", /Aliquota cheia IBS\/CBS/
    assert_select "body", /Reducao cessao de direitos/
  end
end