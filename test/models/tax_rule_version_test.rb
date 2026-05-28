require "test_helper"

class TaxRuleVersionTest < ActiveSupport::TestCase
  test "belongs to a tax module" do
    version = tax_rule_versions(:real_estate_tax_reform_v1)

    assert_equal tax_modules(:real_estate_tax_reform), version.tax_module
    assert_equal "pending_validation", version.status
  end

  test "requires valid status" do
    version = tax_rule_versions(:real_estate_tax_reform_v1).dup
    version.code = "invalid_status_version"
    version.status = "draft"

    assert_not version.valid?
    assert_includes version.errors[:status], "is not included in the list"
  end
end
