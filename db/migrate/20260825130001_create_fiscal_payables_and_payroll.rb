class CreateFiscalPayablesAndPayroll < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_payables do |t|
      t.references :fiscal_company, null: false, foreign_key: true

      t.string  :party
      t.string  :client
      t.string  :document
      t.string  :description
      t.string  :identification
      t.string  :source_sheet
      t.boolean :competence_expense, null: false, default: false

      t.date :due_date
      t.virtual :due_year,  type: :integer, as: "EXTRACT(YEAR  FROM due_date)", stored: true
      t.virtual :due_month, type: :integer, as: "EXTRACT(MONTH FROM due_date)", stored: true

      t.date :payment_date
      t.virtual :paid_year,  type: :integer, as: "EXTRACT(YEAR  FROM payment_date)", stored: true
      t.virtual :paid_month, type: :integer, as: "EXTRACT(MONTH FROM payment_date)", stored: true

      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0

      t.string  :source_file
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_payables, [ :fiscal_company_id, :paid_year, :paid_month ], name: "idx_fiscal_payables_paid"

    create_table :fiscal_payroll_entries do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_client, foreign_key: true

      t.string :employer_code
      t.string :client_code
      t.string :client_name
      t.string :event_code
      t.string :event_type
      t.string :event_description

      t.date :competencia
      t.virtual :competencia_year,  type: :integer, as: "EXTRACT(YEAR  FROM competencia)", stored: true
      t.virtual :competencia_month, type: :integer, as: "EXTRACT(MONTH FROM competencia)", stored: true

      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0

      t.string  :source_file
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_payroll_entries, [ :fiscal_company_id, :client_code, :competencia_year, :competencia_month ], name: "idx_fiscal_payroll_scope"

    create_table :fiscal_payroll_charges do |t|
      t.references :fiscal_company, null: false, foreign_key: true

      t.string :kind
      t.string :code
      t.string :description
      t.string :source_column
      t.string :formula

      t.date :competencia
      t.virtual :competencia_year,  type: :integer, as: "EXTRACT(YEAR  FROM competencia)", stored: true
      t.virtual :competencia_month, type: :integer, as: "EXTRACT(MONTH FROM competencia)", stored: true

      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0

      t.string  :source_file
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_payroll_charges, [ :fiscal_company_id, :kind, :competencia_year, :competencia_month ], name: "idx_fiscal_payroll_charges_scope"
  end
end
