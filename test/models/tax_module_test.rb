require "test_helper"

class TaxModuleTest < ActiveSupport::TestCase
  test "belongs to product area and sector" do
    tax_module = tax_modules(:real_estate_tax_reform)

    assert_equal product_areas(:tax_reform), tax_module.product_area
    assert_equal sectors(:real_estate_construction), tax_module.sector
  end

  test "has ordered operations" do
    tax_module = tax_modules(:real_estate_tax_reform)

    assert_includes tax_module.operations, operations(:sale_property)
  end
end
