class CreateFiscalLinkedAndEfd < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_linked_accounts do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.string :client_code
      t.string :client_name
      t.string :uf
      t.string :contrato
      t.string :banco
      t.string :conta
      t.string :status
      t.string :obs
      t.timestamps
    end
    add_index :fiscal_linked_accounts, [ :fiscal_company_id, :status ], name: "idx_fiscal_linked_accounts_scope"

    create_table :fiscal_linked_account_balances do |t|
      t.references :fiscal_linked_account, null: false, foreign_key: true
      t.references :fiscal_company, null: false, foreign_key: true
      t.date :reference, null: false
      t.virtual :reference_year,  type: :integer, as: "EXTRACT(YEAR  FROM reference)", stored: true
      t.virtual :reference_month, type: :integer, as: "EXTRACT(MONTH FROM reference)", stored: true
      t.decimal :balance, precision: 15, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :fiscal_linked_account_balances, [ :fiscal_linked_account_id, :reference ], unique: true, name: "idx_fiscal_lab_account_reference"

    create_table :fiscal_efd_records do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.string :doc_type
      t.string :codigo
      t.string :num_nf
      t.date   :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true
      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.string  :source_file
      t.integer :page
      t.timestamps
    end
    add_index :fiscal_efd_records, [ :fiscal_company_id, :doc_type, :issued_year, :issued_month ], name: "idx_fiscal_efd_scope"

    create_table :fiscal_razao_records do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.string :kind
      t.string :num_nf
      t.date   :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true
      t.decimal :credit, precision: 15, scale: 2, null: false, default: 0
      t.string  :source_file
      t.integer :page
      t.timestamps
    end
    add_index :fiscal_razao_records, [ :fiscal_company_id, :issued_year, :issued_month ], name: "idx_fiscal_razao_scope"

    create_table :fiscal_devolucoes do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.string :num_nf
      t.date   :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true
      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.string  :source_file
      t.integer :page
      t.timestamps
    end
    add_index :fiscal_devolucoes, [ :fiscal_company_id, :issued_year, :issued_month ], name: "idx_fiscal_devolucoes_scope"
  end
end
