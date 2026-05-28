require "test_helper"

class Simulations::RunSimulationTest < ActiveSupport::TestCase
  test "persists simulation result and audit snapshots" do
    assert_difference -> { Simulation.count }, 1 do
      assert_difference -> { SimulationResult.count }, 1 do
        @simulation = Simulations::RunSimulation.new(
          operation_code: "sale_property",
          name: "Teste venda imovel",
          inputs: { sale_amount: "500000" },
          tax_module: tax_modules(:real_estate_tax_reform),
          tax_rule_version: tax_rule_versions(:real_estate_tax_reform_v1)
        ).call
      end
    end

    simulation = @simulation
    result = simulation.simulation_result

    assert_equal "Teste venda imovel", simulation.name
    assert_equal tax_rule_versions(:real_estate_tax_reform_v1), simulation.tax_rule_version
    assert_equal "real_estate_tax_reform_v1", simulation.rule_version
    assert_equal "500000.0", simulation.input_data.fetch("sale_amount")
    assert_equal "0.265", simulation.parameters_snapshot.fetch("full_ibs_cbs_rate").fetch("value_decimal")
    assert_includes simulation.assumptions_snapshot.map { |assumption| assumption.fetch("code") }, "legal_basis_lc_version"
    assert_includes simulation.alerts_snapshot.map { |alert| alert.fetch("code") }, "full_ibs_cbs_rate"
    assert_equal "53000.0", simulation.output_data.fetch("result").fetch("tax_due")
    assert_equal BigDecimal("53000"), result.tax_due
  end

  test "persists lease divergence alert in snapshots" do
    simulation = Simulations::RunSimulation.new(
      operation_code: "lease_property",
      inputs: { monthly_rent: "3000", iptu_amount: "300", condominium_amount: "500" },
      tax_module: tax_modules(:real_estate_tax_reform),
      tax_rule_version: tax_rule_versions(:real_estate_tax_reform_v1)
    ).call

    alert_codes = simulation.alerts_snapshot.map { |alert| alert.fetch("code") }

    assert_includes alert_codes, "lease_deduct_iptu_condo"
    assert_equal "deduct_iptu_and_condominium", simulation.simulation_result.calculation_details.fetch("lease_base_path")
  end
end
