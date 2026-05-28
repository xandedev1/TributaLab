require "test_helper"

class TaxRules::ValidationAlertsTest < ActiveSupport::TestCase
  test "returns pending parameters and assumptions for the module" do
    alerts = TaxRules::ValidationAlerts.new(tax_module: tax_modules(:real_estate_tax_reform)).call
    codes = alerts.map { |alert| alert[:code] }

    assert_includes codes, "full_ibs_cbs_rate"
    assert_includes codes, "legal_basis_lc_version"
  end

  test "can scope alerts to an operation" do
    alerts = TaxRules::ValidationAlerts.new(
      tax_module: tax_modules(:real_estate_tax_reform),
      operation: operations(:lease_property)
    ).call
    codes = alerts.map { |alert| alert[:code] }

    assert_includes codes, "lease_reduction"
    assert_includes codes, "lease_deduct_iptu_condo"
    assert_includes codes, "full_ibs_cbs_rate"
  end
end