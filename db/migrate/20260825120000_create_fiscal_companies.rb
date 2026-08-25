class CreateFiscalCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_companies do |t|
      t.string :slug,       null: false
      t.string :legal_name, null: false
      t.string :trade_name
      t.string :cnpj,       null: false, limit: 14
      t.string :status,     null: false, default: "active"
      t.jsonb  :settings,   null: false, default: {}
      t.timestamps
    end

    add_index :fiscal_companies, :slug, unique: true
    add_index :fiscal_companies, :cnpj, unique: true
    add_index :fiscal_companies, :status
  end
end
