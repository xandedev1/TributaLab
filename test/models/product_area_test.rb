require "test_helper"

class ProductAreaTest < ActiveSupport::TestCase
  test "requires code and name" do
    product_area = ProductArea.new

    assert_not product_area.valid?
    assert_includes product_area.errors[:code], "can't be blank"
    assert_includes product_area.errors[:name], "can't be blank"
  end
end
