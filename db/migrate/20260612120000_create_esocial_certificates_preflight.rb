class CreateEsocialCertificatesPreflight < ActiveRecord::Migration[8.1]
	def change
		create_table :esocial_certificates do |t|
			t.string :label, null: false
			t.string :holder_name
			t.string :holder_cnpj
			t.string :holder_cpf
			t.text :subject
			t.text :issuer
			t.string :serial_number
			t.datetime :not_before
			t.datetime :expires_at
			t.string :sha256, null: false
			t.text :storage_path, null: false
			t.text :password_ciphertext
			t.string :status, null: false, default: "valid"
			t.string :parse_status, null: false, default: "ok"
			t.text :parse_error
			t.string :source, null: false, default: "manual_upload"
			t.boolean :active, null: false, default: true
			t.jsonb :metadata, null: false, default: {}

			t.timestamps
		end

		add_index :esocial_certificates, :sha256, unique: true
		add_index :esocial_certificates, :holder_cnpj
		add_index :esocial_certificates, [:active, :expires_at]

		create_table :esocial_company_authorizations do |t|
			t.references :esocial_certificate, null: false, foreign_key: true
			t.string :target_company_cnpj, null: false
			t.string :target_company_name
			t.string :status, null: false, default: "declared"
			t.string :verification_method, null: false, default: "manual"
			t.datetime :last_checked_at
			t.text :response_summary
			t.text :notes

			t.timestamps
		end

		add_index :esocial_company_authorizations, [:target_company_cnpj, :status], name: "idx_esocial_authorizations_company_status"
		add_index :esocial_company_authorizations, [:esocial_certificate_id, :target_company_cnpj], name: "idx_esocial_authorizations_cert_company"
	end
end