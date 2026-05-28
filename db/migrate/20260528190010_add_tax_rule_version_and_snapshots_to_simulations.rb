class AddTaxRuleVersionAndSnapshotsToSimulations < ActiveRecord::Migration[8.1]
  def change
    add_reference :simulations, :tax_rule_version, null: true, foreign_key: true
    add_column :simulations, :assumptions_snapshot, :jsonb, null: false, default: []
    add_column :simulations, :alerts_snapshot, :jsonb, null: false, default: []
    add_column :simulations, :legal_bases_snapshot, :jsonb, null: false, default: []
    add_column :simulations, :rule_version_snapshot, :jsonb, null: false, default: {}
  end
end