class CreateSimulationResults < ActiveRecord::Migration[8.1]
  def change
    create_table :simulation_results do |t|
      t.references :simulation, null: false, foreign_key: true
      t.decimal :base_gross, precision: 18, scale: 2, null: false, default: 0
      t.decimal :applied_deduction, precision: 18, scale: 2, null: false, default: 0
      t.decimal :base_net, precision: 18, scale: 2, null: false, default: 0
      t.decimal :full_rate, precision: 10, scale: 6, null: false, default: 0
      t.decimal :applied_reduction, precision: 10, scale: 6, null: false, default: 0
      t.decimal :effective_rate, precision: 10, scale: 6, null: false, default: 0
      t.decimal :tax_debit, precision: 18, scale: 2, null: false, default: 0
      t.decimal :credits, precision: 18, scale: 2, null: false, default: 0
      t.decimal :tax_due, precision: 18, scale: 2, null: false, default: 0
      t.jsonb :validation_alerts, null: false, default: []

      t.timestamps
    end
  end
end
