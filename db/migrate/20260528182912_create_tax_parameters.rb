class CreateTaxParameters < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_parameters do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :parameter_type, null: false
      t.decimal :value_decimal, precision: 18, scale: 6, null: false, default: 0
      t.string :unit, null: false
      t.string :validation_status, null: false, default: "pending"
      t.date :effective_from
      t.date :effective_until
      t.string :legal_reference
      t.text :notes
      t.references :tax_module, null: false, foreign_key: true
      t.references :operation, null: true, foreign_key: true

      t.timestamps
    end

    add_index :tax_parameters, [:tax_module_id, :code, :operation_id], unique: true, name: "index_tax_parameters_on_module_code_operation"
    add_index :tax_parameters, :validation_status
  end
end
