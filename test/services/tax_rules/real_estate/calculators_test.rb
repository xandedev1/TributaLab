require "test_helper"

class TaxRules::RealEstate::CalculatorsTest < ActiveSupport::TestCase
  setup do
    @tax_module = tax_modules(:real_estate_tax_reform)
    @tax_rule_version = tax_rule_versions(:real_estate_tax_reform_v1)
  end

  test "calculates sale property with social deduction and reduced rate" do
    calculation = TaxRules::RealEstate::SalePropertyCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: { sale_amount: "500000" }
    ).call

    result = calculation.fetch(:result)

    assert_equal "sale_property", calculation.fetch(:operation_code)
    assert_equal BigDecimal("500000"), result.fetch(:gross_base)
    assert_equal BigDecimal("100000"), result.fetch(:deductions_amount)
    assert_equal BigDecimal("400000"), result.fetch(:net_base)
    assert_equal BigDecimal("0.1325"), result.fetch(:effective_rate)
    assert_equal BigDecimal("53000"), result.fetch(:tax_due)
  end

  test "calculates residential lot sale with lot deduction" do
    calculation = TaxRules::RealEstate::SaleResidentialLotCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: { sale_amount: "200000" }
    ).call

    result = calculation.fetch(:result)

    assert_equal "sale_residential_lot", calculation.fetch(:operation_code)
    assert_equal BigDecimal("170000"), result.fetch(:net_base)
    assert_equal BigDecimal("22525"), result.fetch(:tax_due)
  end

  test "calculates lease using formula that deducts iptu and condominium and keeps alert" do
    calculation = TaxRules::RealEstate::LeasePropertyCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: { monthly_rent: "3000", iptu_amount: "300", condominium_amount: "500" }
    ).call

    result = calculation.fetch(:result)
    alert_codes = calculation.fetch(:alerts).map { |alert| alert.fetch(:code) }

    assert_equal "lease_property", calculation.fetch(:operation_code)
    assert_equal BigDecimal("2200"), result.fetch(:gross_base)
    assert_equal BigDecimal("1600"), result.fetch(:net_base)
    assert_equal BigDecimal("0.0795"), result.fetch(:effective_rate)
    assert_equal BigDecimal("127.2"), result.fetch(:tax_due)
    assert_includes alert_codes, "lease_deduct_iptu_condo"
    assert_equal "deduct_iptu_and_condominium", calculation.fetch(:calculation_details).fetch(:lease_base_path)
  end

  test "calculates exchange with boot using credits and floors tax due at zero" do
    calculation = TaxRules::RealEstate::ExchangeWithBootCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: { boot_amount: "50000", credits_amount: "2000" }
    ).call

    result = calculation.fetch(:result)

    assert_equal "exchange_with_boot", calculation.fetch(:operation_code)
    assert_equal BigDecimal("50000"), result.fetch(:gross_base)
    assert_equal BigDecimal("13250"), result.fetch(:debit_amount)
    assert_equal BigDecimal("2000"), result.fetch(:credits_amount)
    assert_equal BigDecimal("11250"), result.fetch(:tax_due)
  end
end
