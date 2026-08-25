# BÍBLIA — Construção do Banco de Dados do Auditor Fiscal

> Guia de implementação **completo e copiável**, do zero ao produto multiempresa em produção.
> Companion do design em [`banco_dados_auditor_fiscal.md`](./banco_dados_auditor_fiscal.md). Aqui está o **como fazer**, com migrations, models, importadores, verificação de paridade e deploy no VPS.

---

## Sumário

1. [Convenções obrigatórias](#1-convenções-obrigatórias)
2. [Pré-requisitos e checagem do ambiente](#2-pré-requisitos)
3. [Fase 0 — Empresas (raiz multiempresa)](#3-fase-0--empresas)
4. [Fase 1 — Schema completo (migrations)](#4-fase-1--schema-completo)
5. [Fase 2 — Models ActiveRecord](#5-fase-2--models)
6. [Fase 3 — Importadores (arquivo → banco)](#6-fase-3--importadores)
7. [Fase 4 — Verificação de paridade](#7-fase-4--paridade)
8. [Fase 5 — Ligar dashboards no banco](#8-fase-5--dashboards)
9. [Fase 6 — Deploy no VPS e rollback](#9-fase-6--deploy)
10. [Checklist final](#10-checklist-final)

---

## 1. Convenções obrigatórias

| Assunto | Regra |
|---|---|
| Nome de tabela | `snake_case`, prefixo `fiscal_`, plural. Ex.: `fiscal_billings` |
| Dinheiro | `decimal precision: 15, scale: 2, null: false, default: 0` |
| Percentual | `decimal precision: 7, scale: 4` |
| Data | `date` (competência = sempre dia 01) |
| Ano/Mês | **coluna gerada `stored`** a partir da data (`smallint`) — nunca preenchida à mão |
| Multiempresa | **`company_id` FK em toda tabela de dado**, com índice |
| Rastreio | `source_file_id`, `source_row`, `import_run_id` em toda tabela importada |
| Timestamps | `t.timestamps` (created_at/updated_at) em tudo |
| FK | sempre com índice; `on_delete: :cascade` em filhas, `:restrict` em dados |

**Coluna gerada (o padrão de tempo).** No Rails 8 + PostgreSQL:

```ruby
t.date    :issued_on, null: false
t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true
```

> `stored: true` grava fisicamente e permite **índice**. `EXTRACT` garante que ano/mês **nunca** divergem da data.

---

## 2. Pré-requisitos

```powershell
# Postgres em produção já existe (tributa_lab_production). Local:
#   host 127.0.0.1:5432, user postgres, senha 123321 (dev)
ruby bin/rails db:version          # confirma conexão
ruby bin/rails runner "puts ActiveRecord::Base.connection.adapter_name"  # PostgreSQL
```

Gere cada migration com:

```powershell
ruby bin/rails generate migration CreateFiscalCompanies
# cole o conteúdo das seções abaixo em cada arquivo gerado (db/migrate/*.rb)
```

---

## 3. Fase 0 — Empresas

### 3.1 Migration `fiscal_companies`

```ruby
class CreateFiscalCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_companies do |t|
      t.string  :slug,       null: false
      t.string  :legal_name, null: false
      t.string  :trade_name
      t.string  :cnpj,       null: false, limit: 14
      t.string  :status,     null: false, default: "active"
      t.jsonb   :settings,   null: false, default: {}
      t.timestamps
    end
    add_index :fiscal_companies, :slug, unique: true
    add_index :fiscal_companies, :cnpj, unique: true
    add_index :fiscal_companies, :status
  end
end
```

### 3.2 Seed das empresas atuais (`db/seeds/fiscal_companies.rb` ou no `seeds.rb`)

```ruby
FiscalCompany.find_or_create_by!(slug: "appa") do |c|
  c.legal_name = "APPA Servicos Temporarios e Efetivos LTDA"
  c.trade_name = "APPA Facilities"
  c.cnpj       = "05969071000110"
end
FiscalCompany.find_or_create_by!(slug: "solucoes") do |c|
  c.legal_name = "SOLUCOES SERVICOS TERCEIRIZADOS LTDA."
  c.trade_name = "Solucoes"
  c.cnpj       = "09445502000109"
end
```

> Os CNPJs saem do `CompaniesController::COMPANIES` atual.

---

## 4. Fase 1 — Schema completo

### 4.1 `fiscal_clients`

```ruby
class CreateFiscalClients < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_clients do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.string :code, null: false          # código do cliente (chave do cruzamento)
      t.string :cnpj, limit: 14
      t.string :name, null: false
      t.timestamps
    end
    add_index :fiscal_clients, [:fiscal_company_id, :code], unique: true
    add_index :fiscal_clients, [:fiscal_company_id, :name]
  end
end
```

### 4.2 `fiscal_source_files` e `fiscal_import_runs`

```ruby
class CreateFiscalImportInfra < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_source_files do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.string   :module_name, null: false      # billing, receivables, payables, ...
      t.string   :filename,    null: false
      t.string   :sha256,      null: false
      t.bigint   :byte_size
      t.datetime :imported_at
      t.timestamps
    end
    add_index :fiscal_source_files, [:fiscal_company_id, :sha256], unique: true

    create_table :fiscal_import_runs do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_source_file, foreign_key: true
      t.string   :module_name,   null: false
      t.string   :status,        null: false, default: "running"  # running/completed/failed
      t.integer  :rows_imported, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.text     :error_message
      t.timestamps
    end
    add_index :fiscal_import_runs, [:fiscal_company_id, :module_name, :status]
  end
end
```

### 4.3 `fiscal_billings` (Faturamento)

```ruby
class CreateFiscalBillings < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_billings do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_client,  foreign_key: true            # nullable até resolver
      t.references :fiscal_source_file, foreign_key: true
      t.references :fiscal_import_run,  foreign_key: true

      t.string :client_code
      t.string :client_name
      t.string :client_cnpj, limit: 14
      t.string :invoice_number          # Nº NF-e
      t.string :rps
      t.string :status
      t.string :filial

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

      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_billings, [:fiscal_company_id, :client_code, :invoice_number],
              name: "idx_fiscal_billings_cross_key"
    add_index :fiscal_billings, [:fiscal_company_id, :competencia_year, :competencia_month],
              name: "idx_fiscal_billings_competencia"
    add_index :fiscal_billings, [:fiscal_company_id, :issued_year, :issued_month],
              name: "idx_fiscal_billings_issued"
  end
end
```

### 4.4 `fiscal_receivables` (Contas a receber)

```ruby
class CreateFiscalReceivables < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_receivables do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_client,  foreign_key: true
      t.references :fiscal_source_file, foreign_key: true
      t.references :fiscal_import_run,  foreign_key: true

      t.string :client_code
      t.string :invoice_number
      t.string :situation

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
      t.decimal :paid_amount,  precision: 15, scale: 2, null: false, default: 0

      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_receivables, [:fiscal_company_id, :client_code, :invoice_number],
              name: "idx_fiscal_receivables_cross_key"
    add_index :fiscal_receivables, [:fiscal_company_id, :competencia_year, :competencia_month],
              name: "idx_fiscal_receivables_competencia"
    add_index :fiscal_receivables, [:fiscal_company_id, :paid_year, :paid_month],
              name: "idx_fiscal_receivables_paid"
  end
end
```

### 4.5 `fiscal_payables` (Contas a pagar / despesas)

```ruby
class CreateFiscalPayables < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_payables do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_source_file, foreign_key: true
      t.references :fiscal_import_run,  foreign_key: true

      t.string  :identification
      t.string  :source_sheet
      t.boolean :competence_expense, null: false, default: false

      t.date :payment_date
      t.virtual :paid_year,  type: :integer, as: "EXTRACT(YEAR  FROM payment_date)", stored: true
      t.virtual :paid_month, type: :integer, as: "EXTRACT(MONTH FROM payment_date)", stored: true

      t.date :competencia
      t.virtual :competencia_year,  type: :integer, as: "EXTRACT(YEAR  FROM competencia)", stored: true
      t.virtual :competencia_month, type: :integer, as: "EXTRACT(MONTH FROM competencia)", stored: true

      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_payables, [:fiscal_company_id, :paid_year, :paid_month],
              name: "idx_fiscal_payables_paid"
  end
end
```

### 4.6 `fiscal_payroll_entries` (Folha) e `fiscal_payroll_charges` (Encargos)

```ruby
class CreateFiscalPayroll < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_payroll_entries do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_client,  foreign_key: true
      t.references :fiscal_source_file, foreign_key: true
      t.references :fiscal_import_run,  foreign_key: true

      t.string :client_code
      t.string :employee_name
      t.string :event_code
      t.string :event_type          # Vencimento / Desconto
      t.string :event_description
      t.string :status

      t.date :competencia
      t.virtual :competencia_year,  type: :integer, as: "EXTRACT(YEAR  FROM competencia)", stored: true
      t.virtual :competencia_month, type: :integer, as: "EXTRACT(MONTH FROM competencia)", stored: true

      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_payroll_entries,
              [:fiscal_company_id, :client_code, :competencia_year, :competencia_month],
              name: "idx_fiscal_payroll_scope"

    create_table :fiscal_payroll_charges do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_source_file, foreign_key: true
      t.references :fiscal_import_run,  foreign_key: true

      t.string :kind                # inss / fgts_monthly / fgts_thirteenth
      t.string :code
      t.string :description
      t.string :source_column

      t.date :competencia
      t.virtual :competencia_year,  type: :integer, as: "EXTRACT(YEAR  FROM competencia)", stored: true
      t.virtual :competencia_month, type: :integer, as: "EXTRACT(MONTH FROM competencia)", stored: true

      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.integer :source_row
      t.timestamps
    end
    add_index :fiscal_payroll_charges,
              [:fiscal_company_id, :kind, :competencia_year, :competencia_month],
              name: "idx_fiscal_payroll_charges_scope"
  end
end
```

### 4.7 `fiscal_linked_accounts` (+ saldos)

```ruby
class CreateFiscalLinkedAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_linked_accounts do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_client,  foreign_key: true
      t.string :client_code
      t.string :uf
      t.string :contrato
      t.string :banco
      t.string :conta
      t.string :status
      t.timestamps
    end
    add_index :fiscal_linked_accounts, [:fiscal_company_id, :status]

    create_table :fiscal_linked_account_balances do |t|
      t.references :fiscal_linked_account, null: false, foreign_key: true
      t.references :fiscal_company,         null: false, foreign_key: true
      t.date :reference, null: false        # 1º dia do mês
      t.virtual :reference_year,  type: :integer, as: "EXTRACT(YEAR  FROM reference)", stored: true
      t.virtual :reference_month, type: :integer, as: "EXTRACT(MONTH FROM reference)", stored: true
      t.decimal :balance, precision: 15, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :fiscal_linked_account_balances,
              [:fiscal_linked_account_id, :reference], unique: true,
              name: "idx_fiscal_lab_account_reference"
  end
end
```

### 4.8 `fiscal_efd_records`, `fiscal_razao_records`, `fiscal_devolucoes` (Soluções)

```ruby
class CreateFiscalEfdRazao < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_efd_records do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_import_run, foreign_key: true
      t.string :doc_type            # a100 / c100
      t.string :codigo
      t.string :num_nf
      t.date   :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true
      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.string :source_file
      t.integer :page
      t.timestamps
    end
    add_index :fiscal_efd_records, [:fiscal_company_id, :doc_type, :issued_year, :issued_month],
              name: "idx_fiscal_efd_scope"

    create_table :fiscal_razao_records do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_import_run, foreign_key: true
      t.string :num_nf
      t.date   :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true
      t.decimal :credit, precision: 15, scale: 2, null: false, default: 0
      t.string :source_file
      t.integer :page
      t.timestamps
    end
    add_index :fiscal_razao_records, [:fiscal_company_id, :issued_year, :issued_month],
              name: "idx_fiscal_razao_scope"

    create_table :fiscal_devolucoes do |t|
      t.references :fiscal_company, null: false, foreign_key: true
      t.references :fiscal_import_run, foreign_key: true
      t.string :num_nf
      t.date   :issued_on
      t.virtual :issued_year,  type: :integer, as: "EXTRACT(YEAR  FROM issued_on)", stored: true
      t.virtual :issued_month, type: :integer, as: "EXTRACT(MONTH FROM issued_on)", stored: true
      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0
      t.string :source_file
      t.integer :page
      t.timestamps
    end
    add_index :fiscal_devolucoes, [:fiscal_company_id, :issued_year, :issued_month],
              name: "idx_fiscal_devolucoes_scope"
  end
end
```

Rode tudo:

```powershell
ruby bin/rails db:migrate
ruby bin/rails runner "load Rails.root.join('db/seeds/fiscal_companies.rb')"
```

---

## 5. Fase 2 — Models

Namespace `Fiscal::` em `app/models/fiscal/`.

```ruby
# app/models/fiscal/company.rb
module Fiscal
  class Company < ApplicationRecord
    self.table_name = "fiscal_companies"
    has_many :clients,     class_name: "Fiscal::Client",     foreign_key: :fiscal_company_id
    has_many :billings,    class_name: "Fiscal::Billing",    foreign_key: :fiscal_company_id
    has_many :receivables, class_name: "Fiscal::Receivable", foreign_key: :fiscal_company_id
    validates :slug, :legal_name, :cnpj, presence: true
    validates :slug, :cnpj, uniqueness: true
  end
end
```

```ruby
# app/models/fiscal/billing.rb
module Fiscal
  class Billing < ApplicationRecord
    self.table_name = "fiscal_billings"
    belongs_to :company, class_name: "Fiscal::Company", foreign_key: :fiscal_company_id
    belongs_to :client,  class_name: "Fiscal::Client",  foreign_key: :fiscal_client_id, optional: true

    scope :for_company, ->(id) { where(fiscal_company_id: id) }
    scope :in_year,     ->(y)  { where(competencia_year: y) }
    scope :in_month,    ->(y, m) { where(competencia_year: y, competencia_month: m) }
  end
end
```

> Repita o padrão (`for_company`, `in_year`, `in_month`) em `Receivable`, `Payable`, `PayrollEntry`, etc. `issued_year/month` e `competencia_year/month` são **somente leitura** (colunas geradas) — nunca setar no código.

O cruzamento vira:

```ruby
# app/models/fiscal/reconciliation.rb  (consulta)
Fiscal::Billing.for_company(company_id)
  .joins("LEFT JOIN fiscal_receivables r
            ON  r.fiscal_company_id = fiscal_billings.fiscal_company_id
            AND r.client_code       = fiscal_billings.client_code
            AND r.invoice_number    = fiscal_billings.invoice_number")
  .select("fiscal_billings.*, r.paid_amount, r.gross_amount AS receivable_gross")
```

---

## 6. Fase 3 — Importadores

Padrão: **um serviço por módulo**, idempotente por `sha256`, reaproveitando os parsers atuais.

```ruby
# app/services/fiscal/importers/base_importer.rb
module Fiscal
  module Importers
    class BaseImporter
      def initialize(company:, path:)
        @company = company
        @path    = Pathname(path)
      end

      def call
        sha = Digest::SHA256.file(@path).hexdigest
        file = Fiscal::SourceFile.find_or_create_by!(fiscal_company_id: @company.id, sha256: sha) do |f|
          f.module_name = module_name
          f.filename    = @path.basename.to_s
          f.byte_size   = @path.size
        end
        return if file.imported_at.present?   # idempotente: já importado

        run = Fiscal::ImportRun.create!(fiscal_company_id: @company.id, fiscal_source_file_id: file.id,
                                        module_name: module_name, status: "running", started_at: Time.current)
        begin
          count = import_rows(file, run)
          run.update!(status: "completed", rows_imported: count, finished_at: Time.current)
          file.update!(imported_at: Time.current)
        rescue => e
          run.update!(status: "failed", error_message: e.message, finished_at: Time.current)
          raise
        end
      end

      private

      def module_name = raise NotImplementedError
      def import_rows(_file, _run) = raise NotImplementedError
    end
  end
end
```

Exemplo concreto — Faturamento (reaproveita `RetentionWorkbook`):

```ruby
# app/services/fiscal/importers/billing_importer.rb
module Fiscal
  module Importers
    class BillingImporter < BaseImporter
      def module_name = "billing"

      def import_rows(file, run)
        records = FiscalAuditor::RetentionWorkbook.new(@path).records   # parser já existente
        rows = records.map do |r|
          {
            fiscal_company_id:     @company.id,
            fiscal_source_file_id: file.id,
            fiscal_import_run_id:  run.id,
            client_code: r.client_code, client_name: r.client, client_cnpj: digits(r.cnpj),
            invoice_number: r.invoice_number, rps: r.rps, status: r.status, filial: r.filial,
            issued_on: r.emission_date, competencia: month_floor(r.competence),
            gross_amount: r.billed, inss: r.inss, irrf: r.irrf, pis: r.pis,
            cofins: r.cofins, csll: r.csll, iss: r.iss, net_amount: r.net,
            source_row: r.source_row, created_at: Time.current, updated_at: Time.current
          }
        end
        Fiscal::Billing.insert_all(rows) if rows.any?   # bulk, rápido
        link_clients!                                   # resolve fiscal_client_id
        rows.size
      end

      def month_floor(date) = date&.beginning_of_month
      def digits(v) = v.to_s.gsub(/\D/, "").presence

      def link_clients!
        # cria/atualiza fiscal_clients e liga por (company, code)
        codes = Fiscal::Billing.for_company(@company.id).distinct.pluck(:client_code, :client_name)
        codes.each do |code, name|
          next if code.blank?
          Fiscal::Client.find_or_create_by!(fiscal_company_id: @company.id, code: code) { |c| c.name = name }
        end
        Fiscal::Billing.for_company(@company.id).where(fiscal_client_id: nil).find_each do |b|
          cli = Fiscal::Client.find_by(fiscal_company_id: @company.id, code: b.client_code)
          b.update_column(:fiscal_client_id, cli.id) if cli
        end
      end
    end
  end
end
```

> Faça o mesmo para `ReceivableImporter` (usa `ReceivableSnapshot`), `PayableImporter`, `PayrollImporter`, `PayrollChargesImporter`, `LinkedAccountsImporter`, `EfdRazaoImporter`. Cada um mapeia colunas do parser → colunas da tabela.

**Orquestrador** (varre as pastas atuais e importa tudo):

```ruby
# lib/tasks/fiscal_import.rake
namespace :fiscal do
  task import: :environment do
    Fiscal::Company.find_each do |company|
      base = Rails.root.join("storage/private/fiscal_auditor", company.slug)
      Dir[base.join("source/**/*.xlsx")].each { |p| Fiscal::Importers::BillingImporter.new(company:, path: p).call }
      Dir[base.join("receivables/*.xlsb")].each { |p| Fiscal::Importers::ReceivableImporter.new(company:, path: p).call }
      Dir[base.join("payables/*.xlsb")].each   { |p| Fiscal::Importers::PayableImporter.new(company:, path: p).call }
      Dir[base.join("payroll/*.xlsx")].each    { |p| Fiscal::Importers::PayrollImporter.new(company:, path: p).call }
      Dir[base.join("payroll_charges/*.xlsx")].each { |p| Fiscal::Importers::PayrollChargesImporter.new(company:, path: p).call }
      # linked_accounts, efd_razao...
    end
  end
end
```

```powershell
ruby bin/rails fiscal:import
```

---

## 7. Fase 4 — Paridade (trava de segurança)

Não vira a chave sem bater com o arquivo. Alvos conhecidos (APPA):

| Módulo | Arquivo (hoje) | Banco (esperado) |
|---|---|---|
| Faturamento | 16.800 | `Fiscal::Billing.for_company(appa).count` |
| Contas a receber | 25.664 | `Fiscal::Receivable...count` |
| Contas a pagar | 37.590 | `Fiscal::Payable...count` |
| Folha | 48.771 | `Fiscal::PayrollEntry...count` |
| Conta vinculada | 61 | `Fiscal::LinkedAccount...count` |
| Encargos | 12 competências | `Fiscal::PayrollCharge.distinct...` |

```ruby
# script/fiscal_parity.rb  (roda com: ruby bin/rails runner script/fiscal_parity.rb)
appa = Fiscal::Company.find_by!(slug: "appa")
def ok(label, file_count, db_count)
  status = file_count == db_count ? "OK" : "DIVERGENTE"
  puts format("%-22s arquivo=%-7d banco=%-7d %s", label, file_count, db_count, status)
end
ok "Faturamento",     FiscalAuditor::Dashboard.records("appa").size,           Fiscal::Billing.for_company(appa.id).count
ok "Contas a receber", FiscalAuditor::ReceivablesDashboard.records("appa").size, Fiscal::Receivable.for_company(appa.id).count
# ... demais módulos
```

Também confira **somas** (não só contagem):

```ruby
soma_arquivo = FiscalAuditor::Dashboard.records("appa").sum(&:billed)
soma_banco   = Fiscal::Billing.for_company(appa.id).sum(:gross_amount)
puts (soma_arquivo - soma_banco).abs < 0.01 ? "SOMA OK" : "SOMA DIVERGENTE"
```

---

## 8. Fase 5 — Ligar dashboards no banco

Trocar a fonte **sem mudar a tela**. Dentro de cada dashboard, onde hoje lê `self.class.records(company)` (arquivo), passa a consultar o model:

```ruby
# antes (arquivo)
def all_records
  @all_records ||= self.class.records(company)     # marshal.gz
end

# depois (banco), com flag de segurança
def all_records
  @all_records ||= if Fiscal::Billing.for_company(company_id).exists?
    Fiscal::Billing.for_company(company_id).to_a    # banco
  else
    self.class.records(company)                      # fallback arquivo
  end
end
```

> Faça módulo por módulo, sempre com o **fallback para arquivo** até a paridade estar 100% e estável em produção. Só depois remova o caminho de arquivo.

---

## 9. Fase 6 — Deploy no VPS e rollback

**Deploy (Kamal, já usado no projeto):**

```powershell
# 1. Sobe o código com as migrations
git add -A; git commit -m "feat: banco relacional do auditor fiscal (schema + import)"
git push

# 2. No release, roda migrations no VPS
bin/kamal deploy            # ou o fluxo de deploy do projeto
# migrations rodam em tributa_lab_production

# 3. Importa os dados (uma vez), dentro do container
bin/kamal app exec "bin/rails fiscal:import"

# 4. Confere paridade
bin/kamal app exec "bin/rails runner script/fiscal_parity.rb"
```

**Rollback seguro:**
- O schema é **aditivo** (só cria tabelas novas). O app continua lendo arquivo até você virar a flag.
- Se algo der errado: `bin/rails db:rollback STEP=n` remove as tabelas; nada do fluxo atual quebra, porque o arquivo continua intacto.
- Os arquivos originais **nunca são apagados** — são a evidência e o fallback.

---

## 10. Checklist final

- [ ] `fiscal_companies` criada e semeada (APPA + Soluções, CNPJs reais)
- [ ] Todas as migrations aplicadas (`db:migrate` limpo, `schema.rb` versionado)
- [ ] `company_id` (FK) em toda tabela de dado + índice
- [ ] Colunas `*_year` / `*_month` **geradas** em toda data + indexadas
- [ ] Chave de cruzamento `(company_id, client_code, invoice_number)` indexada em billing e receivables
- [ ] Rastreio (`source_file_id`, `source_row`, `import_run_id`) em toda tabela importada
- [ ] Importadores idempotentes (sha256) para os 7 módulos
- [ ] Paridade 100% (contagem **e** soma) antes de virar leitura
- [ ] Dashboards lendo do banco com fallback para arquivo
- [ ] Deploy no VPS + `fiscal:import` + paridade conferida em produção
- [ ] Arquivos originais preservados como evidência

> Regra de ouro: **nada é removido antes da paridade**. O produto funciona o tempo todo; o banco entra por baixo, empresa por empresa, com dados íntegros e prontos para cruzamento.
