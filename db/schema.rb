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

ActiveRecord::Schema[8.1].define(version: 2026_06_12_120000) do
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

  create_table "esocial_access_logs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.text "error_message"
    t.bigint "esocial_sync_run_id", null: false
    t.string "event_code", null: false
    t.string "operation_name", null: false
    t.integer "query_count", default: 0, null: false
    t.text "request_fingerprint"
    t.datetime "requested_at"
    t.text "response_summary"
    t.string "service_name", null: false
    t.string "status", default: "planned", null: false
    t.string "table_name", null: false
    t.datetime "updated_at", null: false
    t.date "usage_date", null: false
    t.index ["esocial_sync_run_id"], name: "index_esocial_access_logs_on_esocial_sync_run_id"
    t.index ["event_code", "usage_date"], name: "index_esocial_access_logs_on_event_code_and_usage_date"
    t.index ["usage_date", "status"], name: "index_esocial_access_logs_on_usage_date_and_status"
  end

  create_table "esocial_certificates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "holder_cnpj"
    t.string "holder_cpf"
    t.string "holder_name"
    t.text "issuer"
    t.string "label", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "not_before"
    t.text "parse_error"
    t.string "parse_status", default: "ok", null: false
    t.text "password_ciphertext"
    t.string "serial_number"
    t.string "sha256", null: false
    t.string "source", default: "manual_upload", null: false
    t.string "status", default: "valid", null: false
    t.text "storage_path", null: false
    t.text "subject"
    t.datetime "updated_at", null: false
    t.index ["active", "expires_at"], name: "index_esocial_certificates_on_active_and_expires_at"
    t.index ["holder_cnpj"], name: "index_esocial_certificates_on_holder_cnpj"
    t.index ["sha256"], name: "index_esocial_certificates_on_sha256", unique: true
  end

  create_table "esocial_company_authorizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "esocial_certificate_id", null: false
    t.datetime "last_checked_at"
    t.text "notes"
    t.text "response_summary"
    t.string "status", default: "declared", null: false
    t.string "target_company_cnpj", null: false
    t.string "target_company_name"
    t.datetime "updated_at", null: false
    t.string "verification_method", default: "manual", null: false
    t.index ["esocial_certificate_id", "target_company_cnpj"], name: "idx_esocial_authorizations_cert_company"
    t.index ["esocial_certificate_id"], name: "index_esocial_company_authorizations_on_esocial_certificate_id"
    t.index ["target_company_cnpj", "status"], name: "idx_esocial_authorizations_company_status"
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

  create_table "esocial_sync_runs", force: :cascade do |t|
    t.string "company_cnpj", default: "64.030.638/0001-58", null: false
    t.string "company_name", default: "CTE - CENTRO DE TECNOLOGIA DE EDIFICACOES E HOLDING LTDA", null: false
    t.datetime "created_at", null: false
    t.integer "daily_limit", default: 10, null: false
    t.string "environment", default: "production", null: false
    t.datetime "finished_at"
    t.text "notes"
    t.integer "planned_queries", default: 0, null: false
    t.datetime "started_at"
    t.string "status", default: "planned", null: false
    t.string "sync_scope", default: "registration_tables", null: false
    t.jsonb "target_events", default: [], null: false
    t.datetime "updated_at", null: false
    t.integer "used_queries", default: 0, null: false
    t.index ["company_cnpj", "created_at"], name: "index_esocial_sync_runs_on_company_cnpj_and_created_at"
    t.index ["status", "created_at"], name: "index_esocial_sync_runs_on_status_and_created_at"
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

  create_table "rubricas_cte_catalog_rubrics", force: :cascade do |t|
    t.string "active_from"
    t.string "active_to"
    t.datetime "created_at", null: false
    t.string "cte_code", null: false
    t.string "description", null: false
    t.integer "first_source_row"
    t.integer "last_source_row"
    t.string "normalized_description"
    t.bigint "source_file_id", null: false
    t.integer "source_rows_count", default: 0, null: false
    t.string "table_code"
    t.datetime "updated_at", null: false
    t.index ["cte_code"], name: "idx_rcte_catalog_cte_code"
    t.index ["cte_code"], name: "idx_rcte_catalog_unique_cte_code", unique: true
    t.index ["normalized_description"], name: "idx_rcte_catalog_norm_desc"
    t.index ["source_file_id"], name: "idx_rcte_catalog_source"
  end

  create_table "rubricas_cte_expected_incidences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "expected_flag", default: "unknown", null: false
    t.bigint "expected_mapping_id", null: false
    t.string "indicator_code", null: false
    t.string "raw_value"
    t.string "tax_kind", null: false
    t.datetime "updated_at", null: false
    t.index ["expected_mapping_id", "tax_kind", "indicator_code"], name: "idx_rcte_incidences_unique", unique: true
    t.index ["expected_mapping_id"], name: "idx_rcte_incidences_mapping"
    t.index ["tax_kind", "expected_flag"], name: "idx_rcte_incidences_tax_flag"
  end

  create_table "rubricas_cte_expected_mappings", force: :cascade do |t|
    t.string "car"
    t.bigint "catalog_rubric_id", null: false
    t.string "cmp_inc"
    t.datetime "created_at", null: false
    t.string "esocial_nature_code"
    t.string "fd"
    t.string "fdi"
    t.string "fim"
    t.string "fn"
    t.string "fni"
    t.string "ina"
    t.jsonb "incidence_profile", default: {}, null: false
    t.string "ind"
    t.string "inicio"
    t.string "inm"
    t.string "ipd"
    t.string "ipf"
    t.string "ipm"
    t.string "ir"
    t.string "ira"
    t.string "ird"
    t.string "irf"
    t.string "irm"
    t.string "irr"
    t.string "pid"
    t.string "pis"
    t.jsonb "raw_values", default: {}, null: false
    t.string "rem"
    t.string "rp"
    t.string "seq"
    t.bigint "source_file_id", null: false
    t.integer "source_row", null: false
    t.string "source_sheet", null: false
    t.string "tp"
    t.string "tr"
    t.datetime "updated_at", null: false
    t.string "vinculo"
    t.index ["catalog_rubric_id"], name: "idx_rcte_mappings_catalog"
    t.index ["esocial_nature_code"], name: "idx_rcte_mappings_esoc"
    t.index ["source_file_id", "source_row"], name: "idx_rcte_mappings_source_row", unique: true
    t.index ["source_file_id"], name: "idx_rcte_mappings_source"
  end

  create_table "rubricas_cte_findings", force: :cascade do |t|
    t.bigint "catalog_rubric_id", null: false
    t.string "confidence", default: "needs_review", null: false
    t.boolean "cp_divergent", default: false, null: false
    t.datetime "created_at", null: false
    t.string "declared_cp_code"
    t.string "declared_fgts_code"
    t.string "declared_irrf_code"
    t.string "declared_nature_code"
    t.string "divergence_kind", default: "not_evaluated", null: false
    t.jsonb "divergence_kinds", default: [], null: false
    t.jsonb "evidence_json", default: {}, null: false
    t.string "expected_cp_indicator"
    t.string "expected_fgts_indicator"
    t.string "expected_irrf_indicator"
    t.bigint "expected_mapping_id"
    t.string "expected_nature_code"
    t.boolean "fgts_divergent", default: false, null: false
    t.boolean "irrf_divergent", default: false, null: false
    t.boolean "nature_divergent", default: false, null: false
    t.string "period_end"
    t.string "period_start"
    t.string "review_status", default: "pending", null: false
    t.bigint "rubric_identity_link_id"
    t.bigint "s1010_timeline_segment_id"
    t.datetime "updated_at", null: false
    t.index ["catalog_rubric_id"], name: "idx_rcte_findings_catalog"
    t.index ["cp_divergent"], name: "idx_rcte_findings_cp"
    t.index ["divergence_kind"], name: "idx_rcte_findings_kind"
    t.index ["expected_mapping_id"], name: "idx_rcte_findings_mapping"
    t.index ["fgts_divergent"], name: "idx_rcte_findings_fgts"
    t.index ["irrf_divergent"], name: "idx_rcte_findings_irrf"
    t.index ["nature_divergent"], name: "idx_rcte_findings_nature"
    t.index ["rubric_identity_link_id"], name: "idx_rcte_findings_link"
    t.index ["s1010_timeline_segment_id"], name: "idx_rcte_findings_segment"
  end

  create_table "rubricas_cte_import_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.string "kind", null: false
    t.integer "rows_read", default: 0, null: false
    t.integer "rows_written", default: 0, null: false
    t.bigint "source_file_id", null: false
    t.datetime "started_at", null: false
    t.jsonb "stats", default: {}, null: false
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.index ["source_file_id"], name: "idx_rcte_runs_source"
    t.index ["status"], name: "idx_rcte_runs_status"
  end

  create_table "rubricas_cte_rubric_identity_links", force: :cascade do |t|
    t.jsonb "candidates", default: [], null: false
    t.bigint "catalog_rubric_id", null: false
    t.string "cod_rubr_normalized"
    t.string "cod_rubr_raw"
    t.decimal "confidence", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "ide_tab_rubr"
    t.string "match_method", default: "unmatched", null: false
    t.string "review_status", default: "pending", null: false
    t.string "s1010_key"
    t.datetime "updated_at", null: false
    t.index ["catalog_rubric_id"], name: "idx_rcte_links_catalog", unique: true
    t.index ["review_status"], name: "idx_rcte_links_review"
    t.index ["s1010_key"], name: "idx_rcte_links_s1010_key"
  end

  create_table "rubricas_cte_s1010_events", force: :cascade do |t|
    t.string "cod_inc_cp"
    t.string "cod_inc_fgts"
    t.string "cod_inc_irrf"
    t.string "cod_rubr_normalized"
    t.string "cod_rubr_raw"
    t.datetime "created_at", null: false
    t.string "dsc_rubr"
    t.string "event_action"
    t.string "event_id"
    t.string "fim_valid"
    t.string "ide_tab_rubr"
    t.string "ini_valid"
    t.string "nat_rubr"
    t.string "nested_zip_path"
    t.string "normalized_description"
    t.string "nr_recibo"
    t.text "observacao"
    t.bigint "source_file_id", null: false
    t.string "tp_rubr"
    t.datetime "updated_at", null: false
    t.string "xml_path", null: false
    t.string "xml_sha256", null: false
    t.index ["cod_rubr_normalized"], name: "idx_rcte_s1010_norm_code"
    t.index ["ide_tab_rubr", "cod_rubr_raw", "ini_valid"], name: "idx_rcte_s1010_key_valid"
    t.index ["nat_rubr"], name: "idx_rcte_s1010_nat"
    t.index ["source_file_id"], name: "idx_rcte_s1010_source"
    t.index ["xml_sha256"], name: "idx_rcte_s1010_xml_sha", unique: true
  end

  create_table "rubricas_cte_s1010_timeline_segments", force: :cascade do |t|
    t.jsonb "changed_fields", default: [], null: false
    t.string "cod_inc_cp"
    t.string "cod_inc_fgts"
    t.string "cod_inc_irrf"
    t.string "cod_rubr_normalized"
    t.string "cod_rubr_raw"
    t.datetime "created_at", null: false
    t.string "dsc_rubr"
    t.string "ide_tab_rubr"
    t.string "nat_rubr"
    t.string "period_end"
    t.string "period_start"
    t.string "previous_signature"
    t.bigint "s1010_event_id", null: false
    t.string "s1010_key", null: false
    t.string "signature"
    t.bigint "source_file_id", null: false
    t.string "tp_rubr"
    t.datetime "updated_at", null: false
    t.index ["cod_rubr_normalized"], name: "idx_rcte_segments_norm_code"
    t.index ["s1010_event_id"], name: "idx_rcte_segments_event"
    t.index ["s1010_key", "period_start"], name: "idx_rcte_segments_key_period"
    t.index ["source_file_id"], name: "idx_rcte_segments_source"
  end

  create_table "rubricas_cte_source_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "file_size"
    t.string "kind", null: false
    t.datetime "loaded_at"
    t.text "notes"
    t.string "original_path"
    t.string "repo_path", null: false
    t.string "sha256", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "idx_rcte_sources_kind"
    t.index ["sha256"], name: "idx_rcte_sources_sha256", unique: true
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
  add_foreign_key "esocial_access_logs", "esocial_sync_runs"
  add_foreign_key "esocial_company_authorizations", "esocial_certificates"
  add_foreign_key "operations", "tax_modules"
  add_foreign_key "rubric_events", "rubric_companies"
  add_foreign_key "rubric_nature_assignment_versions", "rubric_nature_assignments"
  add_foreign_key "rubric_nature_assignments", "esocial_natures"
  add_foreign_key "rubric_nature_assignments", "rubric_events"
  add_foreign_key "rubric_nature_suggestions", "esocial_natures"
  add_foreign_key "rubric_nature_suggestions", "rubric_events"
  add_foreign_key "rubricas_cte_catalog_rubrics", "rubricas_cte_source_files", column: "source_file_id"
  add_foreign_key "rubricas_cte_expected_incidences", "rubricas_cte_expected_mappings", column: "expected_mapping_id"
  add_foreign_key "rubricas_cte_expected_mappings", "rubricas_cte_catalog_rubrics", column: "catalog_rubric_id"
  add_foreign_key "rubricas_cte_expected_mappings", "rubricas_cte_source_files", column: "source_file_id"
  add_foreign_key "rubricas_cte_findings", "rubricas_cte_catalog_rubrics", column: "catalog_rubric_id"
  add_foreign_key "rubricas_cte_findings", "rubricas_cte_expected_mappings", column: "expected_mapping_id"
  add_foreign_key "rubricas_cte_findings", "rubricas_cte_rubric_identity_links", column: "rubric_identity_link_id"
  add_foreign_key "rubricas_cte_findings", "rubricas_cte_s1010_timeline_segments", column: "s1010_timeline_segment_id"
  add_foreign_key "rubricas_cte_import_runs", "rubricas_cte_source_files", column: "source_file_id"
  add_foreign_key "rubricas_cte_rubric_identity_links", "rubricas_cte_catalog_rubrics", column: "catalog_rubric_id"
  add_foreign_key "rubricas_cte_s1010_events", "rubricas_cte_source_files", column: "source_file_id"
  add_foreign_key "rubricas_cte_s1010_timeline_segments", "rubricas_cte_s1010_events", column: "s1010_event_id"
  add_foreign_key "rubricas_cte_s1010_timeline_segments", "rubricas_cte_source_files", column: "source_file_id"
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
