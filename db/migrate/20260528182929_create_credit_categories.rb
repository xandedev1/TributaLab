class CreateCreditCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_categories do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.string :validation_status, null: false, default: "pending"
      t.string :source_reference
      t.references :tax_module, null: false, foreign_key: true

      t.timestamps
    end

    add_index :credit_categories, [:tax_module_id, :code], unique: true
    add_index :credit_categories, :validation_status
  end
end
