require "test_helper"

class TaxParameterTest < ActiveSupport::TestCase
  test "keeps decimal parameters without float casting" do
    parameter = tax_parameters(:full_ibs_cbs_rate)

    assert_instance_of BigDecimal, parameter.value_decimal
    assert_equal BigDecimal("0.265"), parameter.value_decimal
  end

  test "module-level parameters do not require operation" do
    parameter = tax_parameters(:full_ibs_cbs_rate)

    assert_nil parameter.operation
    assert parameter.valid?
  end
end
