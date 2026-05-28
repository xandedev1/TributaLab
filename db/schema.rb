# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_28_190020) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assumptions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "impact"
    t.bigint "operation_id"
    t.integer "position", default: 0, null: false
    t.string "source_reference"
    t.string "status", default: "pending", null: false
    t.bigint "tax_module_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["operation_id"], name: "index_assumptions_on_operation_id"
    t.index ["status"], name: "index_assumptions_on_status"
    t.index ["tax_module_id", "code"], name: "index_assumptions_on_tax_module_id_and_code", unique: true
    t.index ["tax_module_id"], name: "index_assumptions_on_tax_module_id"
  end

  create_table "credit_categories", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "source_reference"
    t.bigint "tax_module_id", null: false
    t.datetime "updated_at", null: false
    t.string "validation_status", default: "pending", null: false
    t.index ["tax_module_id", "code"], name: "index_credit_categories_on_tax_module_id_and_code", unique: true
    t.index ["tax_module_id"], name: "index_credit_categories_on_tax_module_id"
    t.index ["validation_status"], name: "index_credit_categories_on_validation_status"
  end

  create_table "legal_bases", force: :cascade do |t|
    t.string "article"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "law", null: false
    t.text "notes"
    t.string "source_reference"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_legal_bases_on_code", unique: true
    t.index ["status"], name: "index_legal_bases_on_status"
  end

  create_table "operations", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "status", default: "active", null: false
    t.bigint "tax_module_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_module_id", "code"], name: "index_operations_on_tax_module_id_and_code", unique: true
    t.index ["tax_module_id"], name: "index_operations_on_tax_module_id"
  end

  create_table "product_areas", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_product_areas_on_code", unique: true
  end

  create_table "sectors", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_sectors_on_code", unique: true
  end

  create_table "simulation_results", force: :cascade do |t|
    t.decimal "applied_deduction", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "applied_reduction", precision: 10, scale: 6, default: "0.0", null: false
    t.decimal "base_gross", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "base_net", precision: 18, scale: 2, default: "0.0", null: false
    t.jsonb "calculation_details", default: {}, null: false
    t.datetime "created_at", null: false
    t.decimal "credits", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "effective_rate", precision: 10, scale: 6, default: "0.0", null: false
    t.decimal "full_rate", precision: 10, scale: 6, default: "0.0", null: false
    t.bigint "simulation_id", null: false
    t.decimal "tax_debit", precision: 18, scale: 2, default: "0.0", null: false
    t.decimal "tax_due", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.jsonb "validation_alerts", default: [], null: false
    t.index ["simulation_id"], name: "index_simulation_results_on_simulation_id"
  end

  create_table "simulations", force: :cascade do |t|
    t.jsonb "alerts_snapshot", default: [], null: false
    t.jsonb "assumptions_snapshot", default: [], null: false
    t.datetime "created_at", null: false
    t.jsonb "input_data", default: {}, null: false
    t.jsonb "legal_bases_snapshot", default: [], null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "operation_id", null: false
    t.jsonb "output_data", default: {}, null: false
    t.jsonb "parameters_snapshot", default: {}, null: false
    t.string "rule_version", default: "mvp-001", null: false
    t.jsonb "rule_version_snapshot", default: {}, null: false
    t.bigint "tax_module_id", null: false
    t.bigint "tax_rule_version_id"
    t.datetime "updated_at", null: false
    t.index ["operation_id"], name: "index_simulations_on_operation_id"
    t.index ["rule_version"], name: "index_simulations_on_rule_version"
    t.index ["tax_module_id"], name: "index_simulations_on_tax_module_id"
    t.index ["tax_rule_version_id"], name: "index_simulations_on_tax_rule_version_id"
  end

  create_table "tax_modules", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.bigint "product_area_id", null: false
    t.bigint "sector_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tax_modules_on_code", unique: true
    t.index ["product_area_id"], name: "index_tax_modules_on_product_area_id"
    t.index ["sector_id"], name: "index_tax_modules_on_sector_id"
  end

  create_table "tax_parameters", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.date "effective_from"
    t.date "effective_until"
    t.string "legal_reference"
    t.string "name", null: false
    t.text "notes"
    t.bigint "operation_id"
    t.string "parameter_type", null: false
    t.bigint "tax_module_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.string "validation_status", default: "pending", null: false
    t.decimal "value_decimal", precision: 18, scale: 6, default: "0.0", null: false
    t.index ["operation_id"], name: "index_tax_parameters_on_operation_id"
    t.index ["tax_module_id", "code", "operation_id"], name: "index_tax_parameters_on_module_code_operation", unique: true
    t.index ["tax_module_id"], name: "index_tax_parameters_on_tax_module_id"
    t.index ["validation_status"], name: "index_tax_parameters_on_validation_status"
  end

  create_table "tax_rule_versions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.date "effective_from"
    t.date "effective_until"
    t.string "name", null: false
    t.text "notes"
    t.text "source_summary"
    t.string "status", default: "pending_validation", null: false
    t.bigint "tax_module_id", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_tax_rule_versions_on_status"
    t.index ["tax_module_id", "code"], name: "index_tax_rule_versions_on_tax_module_id_and_code", unique: true
    t.index ["tax_module_id"], name: "index_tax_rule_versions_on_tax_module_id"
  end

  add_foreign_key "assumptions", "operations"
  add_foreign_key "assumptions", "tax_modules"
  add_foreign_key "credit_categories", "tax_modules"
  add_foreign_key "operations", "tax_modules"
  add_foreign_key "simulation_results", "simulations"
  add_foreign_key "simulations", "operations"
  add_foreign_key "simulations", "tax_modules"
  add_foreign_key "simulations", "tax_rule_versions"
  add_foreign_key "tax_modules", "product_areas"
  add_foreign_key "tax_modules", "sectors"
  add_foreign_key "tax_parameters", "operations"
  add_foreign_key "tax_parameters", "tax_modules"
  add_foreign_key "tax_rule_versions", "tax_modules"
end
