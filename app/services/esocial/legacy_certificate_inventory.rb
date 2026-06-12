require "json"
require "open3"

module Esocial
	class LegacyCertificateInventory
		BRIDGE_PATH = Rails.root.join("script", "esocial_official_bridge.py")

		Result = Struct.new(:available?, :success?, :payload, :error_message, keyword_init: true) do
			def holder_cnpj
				payload["holder_cnpj"].presence || "nao identificado"
			end

			def common_name
				payload["common_name"].presence || "titular nao identificado"
			end

			def cert_path
				payload["cert_path"].to_s
			end

			def expires_at
				Time.zone.parse(payload["not_after"].to_s)
			rescue ArgumentError, TypeError
				nil
			end

			def expires_in_days
				return unless expires_at

				(expires_at.to_date - Date.current).to_i
			end

			def cnpjs_found
				Array(payload["cnpjs_found"])
			end

			def file_sha256
				payload["file_sha256"].to_s
			end
		end

		def self.call
			new.call
		end

		def call
			stdout, stderr, status = Open3.capture3("python", BRIDGE_PATH.to_s, "cert-status")
			return Result.new(available?: false, success?: false, payload: {}, error_message: stderr.presence || "Bridge retornou codigo #{status.exitstatus}") unless status.success?

			payload = JSON.parse(stdout.delete_prefix("\uFEFF"))
			Result.new(available?: true, success?: payload["success"] == true, payload: payload, error_message: payload["erro"])
		rescue JSON::ParserError, Errno::ENOENT => error
			Result.new(available?: false, success?: false, payload: {}, error_message: error.message)
		end
	end
end