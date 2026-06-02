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

ActiveRecord::Schema[8.1].define(version: 2026_06_01_090000) do
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

  create_table "case_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.text "notes"
    t.string "reference_code"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["reference_code"], name: "index_case_files_on_reference_code", unique: true
    t.index ["status"], name: "index_case_files_on_status"
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

  create_table "esocial_natures", force: :cascade do |t|
    t.string "cod_inc_cp"
    t.string "cod_inc_fgts"
    t.string "cod_inc_irrf"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "exclusive_employee_incidence"
    t.string "name", null: false
    t.string "nature_code", null: false
    t.string "normalized_name"
    t.text "reason_source"
    t.string "source_file_hash", null: false
    t.integer "source_row", null: false
    t.string "source_sheet", null: false
    t.string "suggested_cp"
    t.string "suggested_fgts"
    t.string "suggested_irrf"
    t.datetime "updated_at", null: false
    t.string "valid_from"
    t.string "valid_to"
    t.index ["nature_code"], name: "index_esocial_natures_on_nature_code"
    t.index ["normalized_name"], name: "index_esocial_natures_on_normalized_name"
    t.index ["source_file_hash", "source_row"], name: "index_esocial_natures_on_source_file_hash_and_source_row", unique: true
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

  create_table "rubric_companies", force: :cascade do |t|
    t.string "cnpj_root"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "reference_code"
    t.datetime "updated_at", null: false
    t.index ["reference_code"], name: "index_rubric_companies_on_reference_code", unique: true
  end

  create_table "rubric_events", force: :cascade do |t|
    t.string "br"
    t.string "car"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "event_code", null: false
    t.string "fd"
    t.string "fdi"
    t.string "fn"
    t.string "fni"
    t.string "ind"
    t.string "inm"
    t.string "ir"
    t.string "ird"
    t.string "irf"
    t.string "irm"
    t.string "normalized_description"
    t.string "nt"
    t.string "reg"
    t.string "rub"
    t.bigint "rubric_company_id", null: false
    t.string "sl"
    t.string "source_file_hash", null: false
    t.integer "source_row", null: false
    t.string "source_sheet", null: false
    t.string "table_code"
    t.string "tp"
    t.datetime "updated_at", null: false
    t.index ["normalized_description"], name: "index_rubric_events_on_normalized_description"
    t.index ["rubric_company_id", "event_code"], name: "index_rubric_events_on_rubric_company_id_and_event_code", unique: true
    t.index ["rubric_company_id"], name: "index_rubric_events_on_rubric_company_id"
    t.index ["source_file_hash"], name: "index_rubric_events_on_source_file_hash"
  end

  create_table "rubric_nature_assignment_versions", force: :cascade do |t|
    t.string "changed_by", default: "sistema", null: false
    t.datetime "created_at", null: false
    t.jsonb "new_values", default: {}, null: false
    t.jsonb "previous_values", default: {}, null: false
    t.text "reason", null: false
    t.bigint "rubric_nature_assignment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["rubric_nature_assignment_id"], name: "idx_on_rubric_nature_assignment_id_4fe6181600"
  end

  create_table "rubric_nature_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "esocial_nature_id"
    t.text "justification"
    t.boolean "override_cp", default: false, null: false
    t.boolean "override_fgts", default: false, null: false
    t.boolean "override_irrf", default: false, null: false
    t.bigint "rubric_event_id", null: false
    t.string "selected_cod_inc_cp"
    t.string "selected_cod_inc_fgts"
    t.string "selected_cod_inc_irrf"
    t.decimal "selected_score", precision: 5, scale: 2
    t.string "selection_origin", default: "manual", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["esocial_nature_id"], name: "index_rubric_nature_assignments_on_esocial_nature_id"
    t.index ["rubric_event_id"], name: "index_rubric_nature_assignments_on_rubric_event_id", unique: true
    t.index ["selection_origin"], name: "index_rubric_nature_assignments_on_selection_origin"
    t.index ["status"], name: "index_rubric_nature_assignments_on_status"
  end

  create_table "rubric_nature_suggestions", force: :cascade do |t|
    t.string "algorithm_version", null: false
    t.string "confidence_label", null: false
    t.datetime "created_at", null: false
    t.bigint "esocial_nature_id", null: false
    t.jsonb "incidence_alignment", default: {}, null: false
    t.jsonb "penalties", default: [], null: false
    t.jsonb "positive_signals", default: [], null: false
    t.integer "rank", null: false
    t.bigint "rubric_event_id", null: false
    t.decimal "score", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["esocial_nature_id"], name: "index_rubric_nature_suggestions_on_esocial_nature_id"
    t.index ["rubric_event_id", "esocial_nature_id"], name: "idx_rubric_suggestions_event_nature", unique: true
    t.index ["rubric_event_id", "rank"], name: "index_rubric_nature_suggestions_on_rubric_event_id_and_rank", unique: true
    t.index ["rubric_event_id"], name: "index_rubric_nature_suggestions_on_rubric_event_id"
    t.index ["score"], name: "index_rubric_nature_suggestions_on_score"
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
    t.bigint "case_file_id"
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
    t.index ["case_file_id"], name: "index_simulations_on_case_file_id"
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
  add_foreign_key "rubric_events", "rubric_companies"
  add_foreign_key "rubric_nature_assignment_versions", "rubric_nature_assignments"
  add_foreign_key "rubric_nature_assignments", "esocial_natures"
  add_foreign_key "rubric_nature_assignments", "rubric_events"
  add_foreign_key "rubric_nature_suggestions", "esocial_natures"
  add_foreign_key "rubric_nature_suggestions", "rubric_events"
  add_foreign_key "simulation_results", "simulations"
  add_foreign_key "simulations", "case_files"
  add_foreign_key "simulations", "operations"
  add_foreign_key "simulations", "tax_modules"
  add_foreign_key "simulations", "tax_rule_versions"
  add_foreign_key "tax_modules", "product_areas"
  add_foreign_key "tax_modules", "sectors"
  add_foreign_key "tax_parameters", "operations"
  add_foreign_key "tax_parameters", "tax_modules"
  add_foreign_key "tax_rule_versions", "tax_modules"
end
