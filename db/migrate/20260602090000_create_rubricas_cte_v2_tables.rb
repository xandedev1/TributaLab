class CreateRubricasCteV2Tables < ActiveRecord::Migration[8.1]
	def change
		create_table :rubricas_cte_source_files do |t|
			t.string :kind, null: false
			t.string :original_path
			t.string :repo_path, null: false
			t.string :sha256, null: false
			t.bigint :file_size
			t.datetime :loaded_at
			t.text :notes

			t.timestamps
		end

		add_index :rubricas_cte_source_files, :kind, name: "idx_rcte_sources_kind"
		add_index :rubricas_cte_source_files, :sha256, unique: true, name: "idx_rcte_sources_sha256"

		create_table :rubricas_cte_import_runs do |t|
			t.references :source_file, null: false, foreign_key: { to_table: :rubricas_cte_source_files }, index: { name: "idx_rcte_runs_source" }
			t.string :kind, null: false
			t.string :status, null: false, default: "running"
			t.datetime :started_at, null: false
			t.datetime :finished_at
			t.integer :rows_read, null: false, default: 0
			t.integer :rows_written, null: false, default: 0
			t.text :error_message
			t.jsonb :stats, null: false, default: {}

			t.timestamps
		end

		add_index :rubricas_cte_import_runs, :status, name: "idx_rcte_runs_status"

		create_table :rubricas_cte_catalog_rubrics do |t|
			t.references :source_file, null: false, foreign_key: { to_table: :rubricas_cte_source_files }, index: { name: "idx_rcte_catalog_source" }
			t.string :table_code
			t.string :cte_code, null: false
			t.string :description, null: false
			t.string :normalized_description
			t.integer :first_source_row
			t.integer :last_source_row
			t.integer :source_rows_count, null: false, default: 0
			t.string :active_from
			t.string :active_to

			t.timestamps
		end

		add_index :rubricas_cte_catalog_rubrics, [:table_code, :cte_code], unique: true, name: "idx_rcte_catalog_table_code"
		add_index :rubricas_cte_catalog_rubrics, :cte_code, name: "idx_rcte_catalog_cte_code"
		add_index :rubricas_cte_catalog_rubrics, :normalized_description, name: "idx_rcte_catalog_norm_desc"

		create_table :rubricas_cte_expected_mappings do |t|
			t.references :catalog_rubric, null: false, foreign_key: { to_table: :rubricas_cte_catalog_rubrics }, index: { name: "idx_rcte_mappings_catalog" }
			t.references :source_file, null: false, foreign_key: { to_table: :rubricas_cte_source_files }, index: { name: "idx_rcte_mappings_source" }
			t.string :source_sheet, null: false
			t.integer :source_row, null: false
			t.string :esocial_nature_code
			t.string :car
			t.string :tp
			t.string :cmp_inc
			t.string :seq
			t.string :fn
			t.string :fd
			t.string :fni
			t.string :fdi
			t.string :inm
			t.string :ind
			t.string :ina
			t.string :irr
			t.string :irm
			t.string :irf
			t.string :ird
			t.string :ir
			t.string :ira
			t.string :pis
			t.string :pid
			t.string :ipm
			t.string :ipd
			t.string :ipf
			t.string :rp
			t.string :tr
			t.string :rem
			t.string :vinculo
			t.string :inicio
			t.string :fim
			t.jsonb :incidence_profile, null: false, default: {}
			t.jsonb :raw_values, null: false, default: {}

			t.timestamps
		end

		add_index :rubricas_cte_expected_mappings, [:source_file_id, :source_row], unique: true, name: "idx_rcte_mappings_source_row"
		add_index :rubricas_cte_expected_mappings, :esocial_nature_code, name: "idx_rcte_mappings_esoc"

		create_table :rubricas_cte_expected_incidences do |t|
			t.references :expected_mapping, null: false, foreign_key: { to_table: :rubricas_cte_expected_mappings }, index: { name: "idx_rcte_incidences_mapping" }
			t.string :tax_kind, null: false
			t.string :indicator_code, null: false
			t.string :raw_value
			t.string :expected_flag, null: false, default: "unknown"

			t.timestamps
		end

		add_index :rubricas_cte_expected_incidences, [:expected_mapping_id, :tax_kind, :indicator_code], unique: true, name: "idx_rcte_incidences_unique"
		add_index :rubricas_cte_expected_incidences, [:tax_kind, :expected_flag], name: "idx_rcte_incidences_tax_flag"

		create_table :rubricas_cte_s1010_events do |t|
			t.references :source_file, null: false, foreign_key: { to_table: :rubricas_cte_source_files }, index: { name: "idx_rcte_s1010_source" }
			t.string :nested_zip_path
			t.string :xml_path, null: false
			t.string :xml_sha256, null: false
			t.string :event_action
			t.string :event_id
			t.string :nr_recibo
			t.string :ide_tab_rubr
			t.string :cod_rubr_raw
			t.string :cod_rubr_normalized
			t.string :dsc_rubr
			t.string :normalized_description
			t.string :ini_valid
			t.string :fim_valid
			t.string :nat_rubr
			t.string :tp_rubr
			t.string :cod_inc_cp
			t.string :cod_inc_irrf
			t.string :cod_inc_fgts
			t.text :observacao

			t.timestamps
		end

		add_index :rubricas_cte_s1010_events, :xml_sha256, unique: true, name: "idx_rcte_s1010_xml_sha"
		add_index :rubricas_cte_s1010_events, [:ide_tab_rubr, :cod_rubr_raw, :ini_valid], name: "idx_rcte_s1010_key_valid"
		add_index :rubricas_cte_s1010_events, :cod_rubr_normalized, name: "idx_rcte_s1010_norm_code"
		add_index :rubricas_cte_s1010_events, :nat_rubr, name: "idx_rcte_s1010_nat"

		create_table :rubricas_cte_s1010_timeline_segments do |t|
			t.references :source_file, null: false, foreign_key: { to_table: :rubricas_cte_source_files }, index: { name: "idx_rcte_segments_source" }
			t.references :s1010_event, null: false, foreign_key: { to_table: :rubricas_cte_s1010_events }, index: { name: "idx_rcte_segments_event" }
			t.string :s1010_key, null: false
			t.string :ide_tab_rubr
			t.string :cod_rubr_raw
			t.string :cod_rubr_normalized
			t.string :dsc_rubr
			t.string :period_start
			t.string :period_end
			t.string :nat_rubr
			t.string :tp_rubr
			t.string :cod_inc_cp
			t.string :cod_inc_irrf
			t.string :cod_inc_fgts
			t.jsonb :changed_fields, null: false, default: []
			t.string :previous_signature
			t.string :signature

			t.timestamps
		end

		add_index :rubricas_cte_s1010_timeline_segments, [:s1010_key, :period_start], name: "idx_rcte_segments_key_period"
		add_index :rubricas_cte_s1010_timeline_segments, :cod_rubr_normalized, name: "idx_rcte_segments_norm_code"

		create_table :rubricas_cte_rubric_identity_links do |t|
			t.references :catalog_rubric, null: false, foreign_key: { to_table: :rubricas_cte_catalog_rubrics }, index: { unique: true, name: "idx_rcte_links_catalog" }
			t.string :s1010_key
			t.string :ide_tab_rubr
			t.string :cod_rubr_raw
			t.string :cod_rubr_normalized
			t.string :match_method, null: false, default: "unmatched"
			t.decimal :confidence, precision: 5, scale: 2, null: false, default: 0
			t.string :review_status, null: false, default: "pending"
			t.jsonb :candidates, null: false, default: []

			t.timestamps
		end

		add_index :rubricas_cte_rubric_identity_links, :s1010_key, name: "idx_rcte_links_s1010_key"
		add_index :rubricas_cte_rubric_identity_links, :review_status, name: "idx_rcte_links_review"

		create_table :rubricas_cte_findings do |t|
			t.references :catalog_rubric, null: false, foreign_key: { to_table: :rubricas_cte_catalog_rubrics }, index: { name: "idx_rcte_findings_catalog" }
			t.references :expected_mapping, foreign_key: { to_table: :rubricas_cte_expected_mappings }, index: { name: "idx_rcte_findings_mapping" }
			t.references :rubric_identity_link, foreign_key: { to_table: :rubricas_cte_rubric_identity_links }, index: { name: "idx_rcte_findings_link" }
			t.references :s1010_timeline_segment, foreign_key: { to_table: :rubricas_cte_s1010_timeline_segments }, index: { name: "idx_rcte_findings_segment" }
			t.string :period_start
			t.string :period_end
			t.string :expected_nature_code
			t.string :declared_nature_code
			t.string :expected_cp_indicator
			t.string :declared_cp_code
			t.string :expected_irrf_indicator
			t.string :declared_irrf_code
			t.string :expected_fgts_indicator
			t.string :declared_fgts_code
			t.boolean :nature_divergent, null: false, default: false
			t.boolean :cp_divergent, null: false, default: false
			t.boolean :irrf_divergent, null: false, default: false
			t.boolean :fgts_divergent, null: false, default: false
			t.string :divergence_kind, null: false, default: "not_evaluated"
			t.jsonb :divergence_kinds, null: false, default: []
			t.string :confidence, null: false, default: "needs_review"
			t.jsonb :evidence_json, null: false, default: {}
			t.string :review_status, null: false, default: "pending"

			t.timestamps
		end

		add_index :rubricas_cte_findings, :divergence_kind, name: "idx_rcte_findings_kind"
		add_index :rubricas_cte_findings, :nature_divergent, name: "idx_rcte_findings_nature"
		add_index :rubricas_cte_findings, :cp_divergent, name: "idx_rcte_findings_cp"
		add_index :rubricas_cte_findings, :irrf_divergent, name: "idx_rcte_findings_irrf"
		add_index :rubricas_cte_findings, :fgts_divergent, name: "idx_rcte_findings_fgts"
	end
end