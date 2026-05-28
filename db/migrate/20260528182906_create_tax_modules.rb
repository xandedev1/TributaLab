class CreateTaxModules < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_modules do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.references :product_area, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :tax_modules, :code, unique: true
  end
end
