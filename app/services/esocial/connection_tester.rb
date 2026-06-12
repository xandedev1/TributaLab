require "net/http"
require "openssl"
require "socket"
require "timeout"
require "uri"

module Esocial
	class ConnectionTester
		HOST = "webservices.download.esocial.gov.br"
		PORT = 443
		SERVICE_PATH = "/servicos/empregador/dwlcirurgico/WsConsultarIdentificadoresEventos.svc"
		ENDPOINT = "https://#{HOST}#{SERVICE_PATH}"

		Result = Struct.new(:success?, :message, keyword_init: true)

		def self.call(certificate:)
			new(certificate: certificate).call
		end

		def initialize(certificate:)
			@certificate = certificate
		end

		def call
			raise ArgumentError, "Certificado nao encontrado." unless @certificate
			raise ArgumentError, "Senha do certificado nao esta salva." if @certificate.password.blank?
			raise ArgumentError, "Arquivo do certificado nao foi encontrado." unless File.exist?(@certificate.storage_path.to_s)

			OpenSslLegacyProvider.load
			pkcs12 = OpenSSL::PKCS12.new(File.binread(@certificate.storage_path), @certificate.password)
			raise ArgumentError, "O PFX salvo nao contem chave privada." unless pkcs12.key

			tls_result = connect_tls(pkcs12)
			message = "Conexao TLS validada com o host oficial do eSocial usando este certificado. Nao executou consulta SOAP e nao confirma procuracao."

			persist_result(
				success: true,
				message: message,
				tls_verified: true,
				test_kind: "tls_handshake",
				details: tls_result
			)
			Result.new(success?: true, message: message)
		rescue OpenSSL::SSL::SSLError => error
			message = ssl_error_message(error)
			persist_result(success: false, message: message)
			Result.new(success?: false, message: message)
		rescue OpenSSL::PKCS12::PKCS12Error => error
			message = pkcs12_error_message(error)
			persist_result(success: false, message: message)
			Result.new(success?: false, message: message)
		rescue StandardError => error
			message = error.message
			persist_result(success: false, message: message)
			Result.new(success?: false, message: message)
		end

		private

		def pkcs12_error_message(error)
			if error.message.include?("unsupported") && error.message.include?("RC2")
				"Este PFX usa criptografia antiga RC2. O provider legacy do OpenSSL nao carregou neste ambiente."
			else
				"Nao foi possivel abrir o PFX salvo: #{error.message}"
			end
		end

		def ssl_error_message(error)
			return "O Ruby/OpenSSL nao conseguiu validar a cadeia de confianca HTTPS do servidor do eSocial. O teste parou antes do HTTP e nao foi repetido sem validacao." if error.message.include?("unable to get local issuer certificate")

			"Falha SSL: #{error.message}"
		end

		def connect_tls(pkcs12)
			Timeout.timeout(15) do
				tcp_socket = TCPSocket.new(HOST, PORT)
				ssl_socket = nil

				begin
					ssl_context = OpenSSL::SSL::SSLContext.new
					ssl_context.cert = pkcs12.certificate
					ssl_context.key = pkcs12.key
					ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
					ssl_context.cert_store = cert_store
					ssl_context.verify_hostname = true if ssl_context.respond_to?(:verify_hostname=)

					ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
					ssl_socket.hostname = HOST if ssl_socket.respond_to?(:hostname=)
					ssl_socket.connect
					ssl_socket.post_connection_check(HOST)

					{
						"peer_subject" => ssl_socket.peer_cert&.subject&.to_s,
						"peer_issuer" => ssl_socket.peer_cert&.issuer&.to_s,
						"verify_result" => ssl_socket.verify_result
					}
				ensure
					ssl_socket&.close
					tcp_socket&.close
				end
			end
		rescue Timeout::Error
			raise Timeout::Error, "Tempo esgotado conectando ao host oficial do eSocial."
		end

		def cert_store
			store = OpenSSL::X509::Store.new
			store.set_default_paths
			windows_bundle_path = WindowsCertificateBundle.path
			store.add_file(windows_bundle_path) if windows_bundle_path.present?
			store
		end

		def response_body_preview(response_body)
			response_body.to_s.gsub(/\s+/, " ").strip.truncate(500)
		end

		def persist_result(success:, message:, http_status: nil, tls_verified: nil, response_body: nil, test_kind: nil, details: {})
			metadata = @certificate.metadata.to_h
			last_connection_test = {
				"success" => success,
				"message" => message,
				"http_status" => http_status,
				"tested_at" => Time.current.iso8601,
				"endpoint" => ENDPOINT
			}
			last_connection_test["tls_verified"] = tls_verified unless tls_verified.nil?
			last_connection_test["test_kind"] = test_kind if test_kind.present?
			last_connection_test["response_body_preview"] = response_body_preview(response_body) if response_body.present?
			details.each { |key, value| last_connection_test[key] = value }
			metadata["last_connection_test"] = last_connection_test
			@certificate.update!(metadata: metadata)
		rescue StandardError
			nil
		end
	end
end
