class CreateLegalBases < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_bases do |t|
      t.string :code, null: false
      t.string :law, null: false
      t.string :article
      t.text :description, null: false
      t.string :source_reference
      t.string :status, null: false, default: "pending"
      t.text :notes

      t.timestamps
    end

    add_index :legal_bases, :code, unique: true
    add_index :legal_bases, :status
  end
end
