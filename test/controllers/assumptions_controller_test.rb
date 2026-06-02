require "test_helper"

class AssumptionsControllerTest < ActionDispatch::IntegrationTest
  test "renders assumptions index" do
    get assumptions_path

    assert_response :success
    assert_select "h1", "Premissas"
    assert_select "body", /Confirmar aliquota de cessao de direitos/
  end
end