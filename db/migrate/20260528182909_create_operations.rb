class CreateOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :operations do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.references :tax_module, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :operations, [:tax_module_id, :code], unique: true
  end
end
