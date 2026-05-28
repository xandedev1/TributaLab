class CreateSimulations < ActiveRecord::Migration[8.1]
  def change
    create_table :simulations do |t|
      t.string :name, null: false
      t.references :tax_module, null: false, foreign_key: true
      t.references :operation, null: false, foreign_key: true
      t.jsonb :input_data, null: false, default: {}
      t.jsonb :output_data, null: false, default: {}
      t.jsonb :parameters_snapshot, null: false, default: {}
      t.string :rule_version, null: false, default: "mvp-001"
      t.text :notes

      t.timestamps
    end

    add_index :simulations, :rule_version
  end
end
