class CreateCaseFilesAndLinkSimulations < ActiveRecord::Migration[8.1]
  def change
    create_table :case_files do |t|
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "active"
      t.string :reference_code
      t.text :notes

      t.timestamps
    end

    add_index :case_files, :status
    add_index :case_files, :reference_code, unique: true

    add_reference :simulations, :case_file, foreign_key: true
  end
end