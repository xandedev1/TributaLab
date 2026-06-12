class CreateEsocialSyncControl < ActiveRecord::Migration[8.1]
	def change
		create_table :esocial_sync_runs do |t|
			t.string :company_cnpj, null: false, default: "64.030.638/0001-58"
			t.string :company_name, null: false, default: "CTE - CENTRO DE TECNOLOGIA DE EDIFICACOES E HOLDING LTDA"
			t.string :sync_scope, null: false, default: "registration_tables"
			t.string :environment, null: false, default: "production"
			t.string :status, null: false, default: "planned"
			t.integer :daily_limit, null: false, default: 10
			t.integer :planned_queries, null: false, default: 0
			t.integer :used_queries, null: false, default: 0
			t.jsonb :target_events, null: false, default: []
			t.text :notes
			t.datetime :started_at
			t.datetime :finished_at

			t.timestamps
		end

		add_index :esocial_sync_runs, [:status, :created_at]
		add_index :esocial_sync_runs, [:company_cnpj, :created_at]

		create_table :esocial_access_logs do |t|
			t.references :esocial_sync_run, null: false, foreign_key: true
			t.string :event_code, null: false
			t.string :table_name, null: false
			t.string :service_name, null: false
			t.string :operation_name, null: false
			t.string :endpoint
			t.string :status, null: false, default: "planned"
			t.integer :query_count, null: false, default: 0
			t.date :usage_date, null: false
			t.datetime :requested_at
			t.datetime :completed_at
			t.text :request_fingerprint
			t.text :response_summary
			t.text :error_message

			t.timestamps
		end

		add_index :esocial_access_logs, [:usage_date, :status]
		add_index :esocial_access_logs, [:event_code, :usage_date]
	end
end