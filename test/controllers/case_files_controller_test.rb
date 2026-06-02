require "test_helper"

class CaseFilesControllerTest < ActionDispatch::IntegrationTest
  test "renders case file index" do
    get case_files_path

    assert_response :success
    assert_select "h1", "Casos internos"
    assert_select "body", /Caso interno de validacao/
  end

  test "creates case file" do
    assert_difference -> { CaseFile.count }, 1 do
      post case_files_path, params: {
        case_file: {
          name: "Caso de validacao B",
          reference_code: "RTI-TEST-002",
          status: "active",
          description: "Caso interno sem dados sensiveis."
        }
      }
    end

    assert_redirected_to case_file_path(CaseFile.order(:created_at).last)
  end

  test "renders case file detail" do
    get case_file_path(case_files(:validation_case))

    assert_response :success
    assert_select "h1", "Caso interno de validacao"
    assert_select "body", /Simulacao draft venda/
  end
end