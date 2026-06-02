class CreateRubricAdequacyTables < ActiveRecord::Migration[8.1]
	def change
		create_table :rubric_companies do |t|
			t.string :name, null: false
			t.string :reference_code
			t.string :cnpj_root
			t.text :notes

			t.timestamps
		end

		add_index :rubric_companies, :reference_code, unique: true

		create_table :rubric_events do |t|
			t.references :rubric_company, null: false, foreign_key: true
			t.string :source_file_hash, null: false
			t.string :source_sheet, null: false
			t.integer :source_row, null: false
			t.string :table_code
			t.string :event_code, null: false
			t.string :description, null: false
			t.string :car
			t.string :reg
			t.string :tp
			t.string :nt
			t.string :sl
			t.string :rub
			t.string :br
			t.string :fn
			t.string :fd
			t.string :fni
			t.string :fdi
			t.string :inm
			t.string :ind
			t.string :irm
			t.string :irf
			t.string :ird
			t.string :ir
			t.string :normalized_description

			t.timestamps
		end

		add_index :rubric_events, [:rubric_company_id, :event_code], unique: true
		add_index :rubric_events, :source_file_hash
		add_index :rubric_events, :normalized_description

		create_table :esocial_natures do |t|
			t.string :source_file_hash, null: false
			t.string :source_sheet, null: false
			t.integer :source_row, null: false
			t.string :nature_code, null: false
			t.string :name, null: false
			t.string :normalized_name
			t.string :valid_from
			t.string :valid_to
			t.text :description
			t.string :exclusive_employee_incidence
			t.string :cod_inc_cp
			t.string :cod_inc_irrf
			t.string :cod_inc_fgts
			t.string :suggested_cp
			t.string :suggested_irrf
			t.string :suggested_fgts
			t.text :reason_source

			t.timestamps
		end

		add_index :esocial_natures, [:source_file_hash, :source_row], unique: true
		add_index :esocial_natures, :nature_code
		add_index :esocial_natures, :normalized_name

		create_table :rubric_nature_suggestions do |t|
			t.references :rubric_event, null: false, foreign_key: true
			t.references :esocial_nature, null: false, foreign_key: true
			t.integer :rank, null: false
			t.decimal :score, precision: 5, scale: 2, null: false
			t.string :confidence_label, null: false
			t.jsonb :positive_signals, null: false, default: []
			t.jsonb :penalties, null: false, default: []
			t.jsonb :incidence_alignment, null: false, default: {}
			t.string :algorithm_version, null: false

			t.timestamps
		end

		add_index :rubric_nature_suggestions, [:rubric_event_id, :rank], unique: true
		add_index :rubric_nature_suggestions, [:rubric_event_id, :esocial_nature_id], unique: true, name: "idx_rubric_suggestions_event_nature"
		add_index :rubric_nature_suggestions, :score

		create_table :rubric_nature_assignments do |t|
			t.references :rubric_event, null: false, foreign_key: true, index: { unique: true }
			t.references :esocial_nature, foreign_key: true
			t.decimal :selected_score, precision: 5, scale: 2
			t.string :selection_origin, null: false, default: "manual"
			t.string :selected_cod_inc_cp
			t.string :selected_cod_inc_irrf
			t.string :selected_cod_inc_fgts
			t.boolean :override_cp, null: false, default: false
			t.boolean :override_irrf, null: false, default: false
			t.boolean :override_fgts, null: false, default: false
			t.text :justification
			t.string :status, null: false, default: "pending"

			t.timestamps
		end

		add_index :rubric_nature_assignments, :status
		add_index :rubric_nature_assignments, :selection_origin

		create_table :rubric_nature_assignment_versions do |t|
			t.references :rubric_nature_assignment, null: false, foreign_key: true
			t.jsonb :previous_values, null: false, default: {}
			t.jsonb :new_values, null: false, default: {}
			t.text :reason, null: false
			t.string :changed_by, null: false, default: "sistema"

			t.timestamps
		end
	end
end