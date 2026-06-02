require "test_helper"

class SimulationTest < ActiveSupport::TestCase
  test "case file association is optional" do
    simulation = simulations(:sale_draft)
    simulation.case_file = nil

    assert simulation.valid?
  end

  test "exposes primary amount and alert count for listings" do
    simulation = simulations(:sale_draft)
    simulation.input_data = { sale_amount: "500000" }
    simulation.alerts_snapshot = [{ code: "full_ibs_cbs_rate" }]

    assert_equal BigDecimal("500000"), simulation.primary_amount
    assert_equal 1, simulation.alert_count
  end
end
