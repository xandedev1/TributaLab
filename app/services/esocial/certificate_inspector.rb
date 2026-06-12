require "digest"
require "openssl"

module Esocial
	class CertificateInspector
		Result = Struct.new(:success?, :attributes, :error_message, keyword_init: true)

		def self.call(pfx_data:, password:)
			new(pfx_data: pfx_data, password: password).call
		end

		def initialize(pfx_data:, password:)
			@pfx_data = pfx_data.to_s.b
			@password = password.to_s
		end

		def call
			OpenSslLegacyProvider.load
			pkcs12 = OpenSSL::PKCS12.new(@pfx_data, @password)
			certificate = pkcs12.certificate

			Result.new(success?: true, attributes: attributes_for(certificate), error_message: nil)
		rescue OpenSSL::PKCS12::PKCS12Error, ArgumentError => error
			Result.new(success?: false, attributes: {}, error_message: error_message_for(error))
		end

		private

		def error_message_for(error)
			if error.message.include?("unsupported") && error.message.include?("RC2")
				"Este PFX usa criptografia antiga RC2. Ative o provider legacy do OpenSSL no ambiente ou exporte o certificado novamente em formato PFX/A1 atual. Detalhe tecnico: #{error.message}"
			else
				"Nao foi possivel abrir o PFX com a senha informada: #{error.message}"
			end
		end

		def attributes_for(certificate)
			identity_text = identity_text_for(certificate)
			cnpjs = identity_text.scan(/\b\d{14}\b/).uniq
			cpfs = identity_text.scan(/\b\d{11}\b/).uniq

			{
				holder_name: common_name(certificate),
				holder_cnpj: cnpjs.first,
				holder_cpf: cpfs.first,
				subject: certificate.subject.to_s,
				issuer: certificate.issuer.to_s,
				serial_number: certificate.serial.to_s,
				not_before: certificate.not_before,
				expires_at: certificate.not_after,
				sha256: Digest::SHA256.hexdigest(@pfx_data),
				metadata: {
					fingerprint_sha256: OpenSSL::Digest::SHA256.hexdigest(certificate.to_der),
					identity_numbers_found: (cnpjs + cpfs).uniq
				}
			}
		end

		def identity_text_for(certificate)
			([certificate.subject.to_s, certificate.issuer.to_s] + certificate.extensions.map(&:to_s)).join(" ")
		end

		def common_name(certificate)
			certificate.subject.to_a.find { |name, _value, _type| name == "CN" }&.second
		end
	end
end