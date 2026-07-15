class CreateInssPayrollTables < ActiveRecord::Migration[8.1]
  def change
    create_table :inss_payroll_imports do |t|
      t.string :filename, null: false
      t.string :content_hash, null: false
      t.string :competencia
      t.string :empresa
      t.string :status, null: false, default: "pending"
      t.integer :employees_count, null: false, default: 0
      t.integer :entries_count, null: false, default: 0
      t.text :error_message
      t.datetime :imported_at

      t.timestamps
    end
    add_index :inss_payroll_imports, :content_hash, unique: true
    add_index :inss_payroll_imports, :competencia

    create_table :inss_payroll_employees do |t|
      t.references :inss_payroll_import, null: false, foreign_key: true
      t.string :competencia
      t.string :empresa
      t.string :orgao_codigo
      t.string :orgao_nome
      t.string :contrato_codigo
      t.string :contrato_nome
      t.string :matricula
      t.string :nome
      t.string :cargo
      t.string :situacao_funcional
      t.date :admissao
      t.date :rescisao
      t.decimal :salario, precision: 15, scale: 2
      t.decimal :total_proventos, precision: 15, scale: 2
      t.decimal :total_descontos, precision: 15, scale: 2
      t.decimal :liquido, precision: 15, scale: 2

      t.timestamps
    end
    add_index :inss_payroll_employees, :matricula
    add_index :inss_payroll_employees, :situacao_funcional
    add_index :inss_payroll_employees, :contrato_codigo
    add_index :inss_payroll_employees, :competencia

    create_table :inss_payroll_entries do |t|
      t.references :inss_payroll_employee, null: false, foreign_key: true
      t.string :bloco, null: false
      t.string :codigo, null: false
      t.string :historico
      t.decimal :referencia, precision: 15, scale: 2, null: false, default: 0
      t.decimal :valor, precision: 15, scale: 2, null: false, default: 0

      t.timestamps
    end
    add_index :inss_payroll_entries, :bloco
    add_index :inss_payroll_entries, :codigo
    add_index :inss_payroll_entries, [:bloco, :codigo]
  end
end
