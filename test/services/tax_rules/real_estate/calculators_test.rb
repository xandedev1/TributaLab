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

  test "calculates construction contract with full rate and credits" do
    calculation = TaxRules::RealEstate::ConstructionContractCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: { contract_amount: "1000000", credits_amount: "150000" }
    ).call

    result = calculation.fetch(:result)
    alert_codes = calculation.fetch(:alerts).map { |alert| alert.fetch(:code) }

    assert_equal "civil_construction", calculation.fetch(:operation_code)
    assert_equal BigDecimal("1000000"), result.fetch(:gross_base)
    assert_equal BigDecimal("265000"), result.fetch(:debit_amount)
    assert_equal BigDecimal("150000"), result.fetch(:credits_amount)
    assert_equal BigDecimal("115000"), result.fetch(:tax_due)
    assert_includes alert_codes, "civil_construction_full_rate"
  end

  test "calculates brokerage administration with full rate and credits" do
    calculation = TaxRules::RealEstate::BrokerageAdministrationCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: { service_amount: "50000", credits_amount: "5000" }
    ).call

    result = calculation.fetch(:result)
    alert_codes = calculation.fetch(:alerts).map { |alert| alert.fetch(:code) }

    assert_equal "management_brokerage", calculation.fetch(:operation_code)
    assert_equal BigDecimal("13250"), result.fetch(:debit_amount)
    assert_equal BigDecimal("8250"), result.fetch(:tax_due)
    assert_includes alert_codes, "management_brokerage_full_rate"
  end

  test "calculates rights assignment with parameterized divergent reduction" do
    calculation = TaxRules::RealEstate::AssignmentRightsCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: { assignment_amount: "50000", credits_amount: "500" }
    ).call

    result = calculation.fetch(:result)
    alert_codes = calculation.fetch(:alerts).map { |alert| alert.fetch(:code) }

    assert_equal "rights_assignment", calculation.fetch(:operation_code)
    assert_equal BigDecimal("0.0795"), result.fetch(:effective_rate)
    assert_equal BigDecimal("3975"), result.fetch(:debit_amount)
    assert_equal BigDecimal("3475"), result.fetch(:tax_due)
    assert_includes alert_codes, "rights_assignment_reduction"
    assert_includes alert_codes, "rights_assignment_rate"
    assert_equal "apply_parameterized_reduction_pending_validation", calculation.fetch(:calculation_details).fetch(:rights_assignment_rate_path)
  end

  test "calculates exchange without boot as informational zero tax operation" do
    calculation = TaxRules::RealEstate::ExchangeWithoutBootCalculator.new(
      tax_module: @tax_module,
      tax_rule_version: @tax_rule_version,
      inputs: {}
    ).call

    result = calculation.fetch(:result)
    alert_codes = calculation.fetch(:alerts).map { |alert| alert.fetch(:code) }

    assert_equal "exchange_without_boot", calculation.fetch(:operation_code)
    assert_equal BigDecimal("0"), result.fetch(:gross_base)
    assert_equal BigDecimal("0"), result.fetch(:tax_due)
    assert_includes alert_codes, "exchange_without_boot_screen"
    assert calculation.fetch(:calculation_details).fetch(:informational_operation)
  end
end
