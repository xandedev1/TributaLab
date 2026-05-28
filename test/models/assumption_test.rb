require "test_helper"

class AssumptionTest < ActiveSupport::TestCase
  test "tracks pending rule validation" do
    assumption = assumptions(:lease_deduct_iptu_condo)

    assert_equal "pending", assumption.status
    assert assumption.open_for_validation?
  end
end
