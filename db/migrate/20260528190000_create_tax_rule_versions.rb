class CreateTaxRuleVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_rule_versions do |t|
      t.references :tax_module, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "pending_validation"
      t.date :effective_from
      t.date :effective_until
      t.text :source_summary
      t.text :notes

      t.timestamps
    end

    add_index :tax_rule_versions, [:tax_module_id, :code], unique: true
    add_index :tax_rule_versions, :status
  end
end