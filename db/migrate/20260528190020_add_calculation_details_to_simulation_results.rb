class AddCalculationDetailsToSimulationResults < ActiveRecord::Migration[8.1]
  def change
    add_column :simulation_results, :calculation_details, :jsonb, null: false, default: {}
  end
end