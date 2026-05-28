class CreateProductAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :product_areas do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :product_areas, :code, unique: true
  end
end
