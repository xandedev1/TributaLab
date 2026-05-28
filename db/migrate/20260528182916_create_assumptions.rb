class CreateAssumptions < ActiveRecord::Migration[8.1]
  def change
    create_table :assumptions do |t|
      t.string :code, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.text :impact
      t.string :source_reference
      t.integer :position, null: false, default: 0
      t.references :tax_module, null: false, foreign_key: true
      t.references :operation, null: true, foreign_key: true

      t.timestamps
    end

    add_index :assumptions, [:tax_module_id, :code], unique: true
    add_index :assumptions, :status
  end
end
