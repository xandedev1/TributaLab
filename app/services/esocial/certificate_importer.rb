require "fileutils"

module Esocial
	class CertificateImporter
		STORAGE_DIR = Rails.root.join("storage", "private", "esocial", "certificates")

		def self.call(file:, password:, label: nil, certificate_kind: "company")
			new(file: file, password: password, label: label, certificate_kind: certificate_kind).call
		end

		def initialize(file:, password:, label: nil, certificate_kind: "company")
			@file = file
			@password = password.to_s
			@label = label.to_s.strip
			@certificate_kind = certificate_kind.to_s == "personal" ? "personal" : "company"
		end

		def call
			raise ArgumentError, "Informe um arquivo PFX." if @file.blank?
			raise ArgumentError, "Informe a senha do certificado." if @password.blank?

			pfx_data = @file.read
			inspection = CertificateInspector.call(pfx_data: pfx_data, password: @password)
			raise ArgumentError, inspection.error_message unless inspection.success?

			attributes = inspection.attributes
			storage_path = storage_path_for(attributes[:sha256])
			FileUtils.mkdir_p(STORAGE_DIR)
			File.binwrite(storage_path, pfx_data)

			certificate = EsocialCertificate.find_or_initialize_by(sha256: attributes[:sha256])
			metadata = attributes[:metadata].to_h.merge(certificate_kind: @certificate_kind)

			certificate.assign_attributes(
				attributes.merge(
					label: @label.presence || attributes[:holder_name].presence || "Certificado eSocial",
					storage_path: storage_path.to_s,
					password_ciphertext: EsocialCertificate.encrypt_password(@password),
					parse_status: "ok",
					parse_error: nil,
					source: "manual_upload",
					active: true,
					metadata: metadata
				)
			)
			certificate.save!
			certificate
		ensure
			@file.rewind if @file.respond_to?(:rewind)
		end

		private

		def storage_path_for(sha256)
			STORAGE_DIR.join("#{sha256}.pfx")
		end
	end
end