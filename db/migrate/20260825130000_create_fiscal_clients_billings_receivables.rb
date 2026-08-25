class CreateFiscalClientsBillingsReceivables < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_clients do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.string :code, null: false
      t.string :cnpj, limit: 14
      t.string :name
      t.timestamps
    end
    add_index :fiscal_clients, [ :fiscal_company_id, :code ], unique: true, name: "idx_fiscal_clients_company_code"
    add_index :fiscal_clients, [ :fiscal_company_id, :name ], name: "idx_fiscal_clients_company_name"

    create_table :fiscal_billings do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_client, foreign_key: true

      t.string :client_code
      t.string :client_name
      t.string :client_cnpj, limit: 14
      t.string :invoice_number
      t.string :rps
      t.string :status

      t.date :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true

      t.date :competencia
      t.virtual :competencia_year,  type: :integer, as: "EXTRACT(YEAR  FROM competencia)", stored: true
      t.virtual :competencia_month, type: :integer, as: "EXTRACT(MONTH FROM competencia)", stored: true

      t.decimal :gross_amount, precision: 15, scale: 2, null: false, default: 0
      t.decimal :inss,   precision: 15, scale: 2, null: false, default: 0
      t.decimal :irrf,   precision: 15, scale: 2, null: false, default: 0
      t.decimal :pis,    precision: 15, scale: 2, null: false, default: 0
      t.decimal :cofins, precision: 15, scale: 2, null: false, default: 0
      t.decimal :csll,   precision: 15, scale: 2, null: false, default: 0
      t.decimal :iss,    precision: 15, scale: 2, null: false, default: 0
      t.decimal :net_amount, precision: 15, scale: 2, null: false, default: 0

      t.string  :source_file
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_billings, [ :fiscal_company_id, :client_code, :invoice_number ], name: "idx_fiscal_billings_cross_key"
    add_index :fiscal_billings, [ :fiscal_company_id, :competencia_year, :competencia_month ], name: "idx_fiscal_billings_competencia"
    add_index :fiscal_billings, [ :fiscal_company_id, :issued_year, :issued_month ], name: "idx_fiscal_billings_issued"

    create_table :fiscal_receivables do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_client, foreign_key: true

      t.string :client_code
      t.string :client_name
      t.string :invoice_number
      t.string :rps
      t.string :cost_center
      t.string :bank
      t.string :situation
      t.string :reconciliation_status

      t.date :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true

      t.date :competencia
      t.virtual :competencia_year,  type: :integer, as: "EXTRACT(YEAR  FROM competencia)", stored: true
      t.virtual :competencia_month, type: :integer, as: "EXTRACT(MONTH FROM competencia)", stored: true

      t.date :payment_date
      t.virtual :paid_year,  type: :integer, as: "EXTRACT(YEAR  FROM payment_date)", stored: true
      t.virtual :paid_month, type: :integer, as: "EXTRACT(MONTH FROM payment_date)", stored: true

      t.decimal :gross_amount, precision: 15, scale: 2, null: false, default: 0
      t.decimal :contingency,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :outstanding,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :paid_amount,  precision: 15, scale: 2, null: false, default: 0

      t.string  :source_file
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_receivables, [ :fiscal_company_id, :client_code, :invoice_number ], name: "idx_fiscal_receivables_cross_key"
    add_index :fiscal_receivables, [ :fiscal_company_id, :competencia_year, :competencia_month ], name: "idx_fiscal_receivables_competencia"
    add_index :fiscal_receivables, [ :fiscal_company_id, :paid_year, :paid_month ], name: "idx_fiscal_receivables_paid"
  end
end
