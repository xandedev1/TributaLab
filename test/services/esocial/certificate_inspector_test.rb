require "test_helper"
require "openssl"

module Esocial
	class CertificateInspectorTest < ActiveSupport::TestCase
		test "reads holder metadata from a valid pfx" do
			pfx_data = build_pfx(common_name: "CTE TESTE:64030638000158", password: "secret123")

			result = CertificateInspector.call(pfx_data: pfx_data, password: "secret123")

			assert result.success?
			assert_equal "CTE TESTE:64030638000158", result.attributes[:holder_name]
			assert_equal "64030638000158", result.attributes[:holder_cnpj]
			assert_equal 64, result.attributes[:sha256].length
		end

		test "rejects pfx with wrong password" do
			pfx_data = build_pfx(common_name: "CTE TESTE:64030638000158", password: "secret123")

			result = CertificateInspector.call(pfx_data: pfx_data, password: "wrong")

			assert_not result.success?
			assert_match(/Nao foi possivel abrir o PFX/, result.error_message)
		end

		private

		def build_pfx(common_name:, password:)
			key = OpenSSL::PKey::RSA.new(2048)
			certificate = OpenSSL::X509::Certificate.new
			certificate.version = 2
			certificate.serial = 1
			certificate.subject = OpenSSL::X509::Name.parse("/CN=#{common_name}/O=ICP-Brasil/C=BR")
			certificate.issuer = certificate.subject
			certificate.public_key = key.public_key
			certificate.not_before = 1.day.ago
			certificate.not_after = 1.year.from_now
			certificate.sign(key, OpenSSL::Digest.new("SHA256"))

			OpenSSL::PKCS12.create(password, "cte", key, certificate).to_der
		end
	end
end