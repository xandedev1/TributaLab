class EsocialCertificate < ApplicationRecord
	STATUSES = %w[valid expired not_yet_valid invalid].freeze
	PARSE_STATUSES = %w[ok failed].freeze

	has_many :esocial_company_authorizations, dependent: :destroy

	validates :label, :sha256, :storage_path, :status, :parse_status, :source, presence: true
	validates :sha256, uniqueness: true
	validates :status, inclusion: { in: STATUSES }
	validates :parse_status, inclusion: { in: PARSE_STATUSES }

	before_validation :refresh_status_from_dates

	def self.clean_digits(value)
		value.to_s.gsub(/\D/, "")
	end

	def self.encrypt_password(password)
		return if password.blank?

		secret_box.encrypt_and_sign(password)
	end

	def self.decrypt_password(ciphertext)
		return if ciphertext.blank?

		secret_box.decrypt_and_verify(ciphertext)
	rescue ActiveSupport::MessageEncryptor::InvalidMessage
		nil
	end

	def self.secret_box
		key = Rails.application.key_generator.generate_key("tributalab esocial certificate password", 32)
		ActiveSupport::MessageEncryptor.new(key)
	end

	def password
		self.class.decrypt_password(password_ciphertext)
	end

	def holder_document
		holder_cnpj.presence || holder_cpf.presence || "nao identificado"
	end

	def holder_label
		[holder_name.presence || "Titular nao identificado", holder_document].join(" / ")
	end

	def select_label
		"#{label} - #{holder_document}"
	end

	def valid_now?
		status == "valid" && parse_status == "ok" && expires_at.present? && expires_at.future? && (not_before.blank? || not_before <= Time.current)
	end

	def expires_in_days
		return unless expires_at

		(expires_at.to_date - Date.current).to_i
	end

	def direct_holder_for?(company_cnpj)
		holder_cnpj.present? && self.class.clean_digits(holder_cnpj) == self.class.clean_digits(company_cnpj)
	end

	def authorization_for(company_cnpj)
		company_digits = self.class.clean_digits(company_cnpj)
		esocial_company_authorizations.order(updated_at: :desc).detect do |authorization|
			EsocialCertificate.clean_digits(authorization.target_company_cnpj) == company_digits
		end
	end

	def verified_authorization_for?(company_cnpj)
		authorization_for(company_cnpj)&.verified?
	end

	def declared_authorization_for?(company_cnpj)
		authorization_for(company_cnpj)&.declared?
	end

	def last_connection_test
		metadata.to_h["last_connection_test"].to_h
	end

	def last_connection_test_success?
		last_connection_test["success"] == true && !last_connection_test_unverified_server?
	end

	def last_connection_test_present?
		last_connection_test.present?
	end

	def last_connection_test_message
		message = last_connection_test["message"].to_s
		message = "Sem teste registrado." if message.blank?
		message.gsub("cadeia CA local do Ruby", "cadeia de confianca do servidor no Ruby")
			.gsub("CA local", "cadeia de confianca do servidor")
	end

	def last_connection_test_endpoint
		last_connection_test["endpoint"].presence || Esocial::ConnectionTester::ENDPOINT
	end

	def last_connection_test_http_status
		last_connection_test["http_status"]
	end

	def last_connection_test_kind
		last_connection_test["test_kind"].presence || (last_connection_test_http_status.present? ? "http_wsdl" : "tls_handshake")
	end

	def last_connection_test_kind_label
		case last_connection_test_kind
		when "tls_handshake"
			"TLS/mTLS"
		when "http_wsdl"
			"HTTP/WSDL"
		else
			last_connection_test_kind.to_s
		end
	end

	def last_connection_test_response_preview
		last_connection_test["response_body_preview"].to_s
	end

	def last_connection_tested_at
		raw_timestamp = last_connection_test["tested_at"]
		return if raw_timestamp.blank?

		Time.zone.parse(raw_timestamp)
	rescue ArgumentError, TypeError
		nil
	end

	def last_connection_test_unverified_server?
		return true if last_connection_test["tls_verified"] == false

		message = last_connection_test["message"].to_s
		message.include?("sem validar") || message.include?("sem validacao") || message.include?("CA local")
	end

	def last_connection_test_status_label
		return "OK verificado" if last_connection_test_success?
		return "Servidor nao validado" if last_connection_test_unverified_server?
		return "Falhou" if last_connection_test_present?

		"Nao testado"
	end

	def last_connection_test_tls_label
		return "Servidor validado" if last_connection_test["tls_verified"] == true
		return "Servidor nao validado" if last_connection_test_unverified_server?

		"Sem teste"
	end

	def storage_filename
		File.basename(storage_path.to_s)
	end

	def short_sha256
		sha256.to_s.first(12)
	end

	def certificate_kind
		metadata.to_h["certificate_kind"].presence || "company"
	end

	def company_certificate?
		certificate_kind == "company"
	end

	def personal_certificate?
		certificate_kind == "personal"
	end

	def certificate_kind_label
		personal_certificate? ? "Pessoal/procurador" : "Empresa"
	end

	private

	def refresh_status_from_dates
		return if parse_status == "failed"
		return if expires_at.blank?

		self.status = if expires_at <= Time.current
			"expired"
		elsif not_before.present? && not_before > Time.current
			"not_yet_valid"
		else
			"valid"
		end
	end
end