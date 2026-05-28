require "test_helper"

class SimulationsControllerTest < ActionDispatch::IntegrationTest
  test "renders new simulation form" do
    get new_simulation_path

    assert_response :success
    assert_select "h1", "Nova simulacao"
    assert_select "select[name=operation_code]"
  end

  test "creates lease simulation and redirects to result" do
    assert_difference -> { Simulation.count }, 1 do
      assert_difference -> { SimulationResult.count }, 1 do
        post simulations_path, params: {
          operation_code: "lease_property",
          inputs: {
            monthly_rent: "3000",
            iptu_amount: "300",
            condominium_amount: "500"
          }
        }
      end
    end

    simulation = Simulation.order(:created_at).last

    assert_redirected_to simulation_path(simulation)
    follow_redirect!
    assert_response :success
    assert_select "h1", /Simulacao - Locacao de imoveis/
    assert_select "body", /Confirmar deducao de IPTU e condominio/
  end
end
