require "test_helper"

class CaseFileTest < ActiveSupport::TestCase
  test "creates internal case without sensitive company fields" do
    case_file = CaseFile.new(
      name: "Validacao interna lote A",
      status: "active",
      reference_code: "RTI-CASE-NEW"
    )

    assert case_file.valid?
  end

  test "rejects unsupported status" do
    case_file = case_files(:validation_case)
    case_file.status = "client_ready"

    assert_not case_file.valid?
  end
end