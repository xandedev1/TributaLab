require "test_helper"

class SimulationsControllerTest < ActionDispatch::IntegrationTest
  test "renders new simulation form" do
    get new_simulation_path

    assert_response :success
    assert_select "h1", "Nova simulacao fiscal"
    assert_select "select[name=operation_code]"
    assert_select "option[value=civil_construction]"
    assert_select "option[value=exchange_without_boot]"
    assert_select "body", /Parametros usados/
  end

  test "lists saved simulations" do
    get simulations_path

    assert_response :success
    assert_select "h1", "Simulacoes salvas"
    assert_select "table"
    assert_select "body", /Simulacao draft venda/
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
    assert_select "body", /Fita de calculo/
  end

  test "creates construction simulation associated with case file" do
    assert_difference -> { Simulation.count }, 1 do
      post simulations_path, params: {
        operation_code: "civil_construction",
        case_file_id: case_files(:validation_case).id,
        inputs: {
          contract_amount: "1000000",
          credits_amount: "150000"
        }
      }
    end

    simulation = Simulation.order(:created_at).last

    assert_redirected_to simulation_path(simulation)
    assert_equal case_files(:validation_case), simulation.case_file
    assert_equal BigDecimal("115000"), simulation.simulation_result.tax_due
  end
end
