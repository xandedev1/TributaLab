class CreateEsocialCompanyTableRows < ActiveRecord::Migration[8.1]
	def change
		create_table :esocial_company_table_rows do |t|
			t.string :event_type, null: false
			t.string :event_id, null: false
			t.jsonb :attributes_payload, null: false, default: {}
			t.text :xml_content
			t.string :xml_filename
			t.string :source_path

			t.timestamps
		end

		add_index :esocial_company_table_rows, [ :event_type, :event_id ], unique: true
		add_index :esocial_company_table_rows, :event_type
	end
end