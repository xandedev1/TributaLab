module Esocial
	class SyncRunsController < ApplicationController
		DEFAULT_MAX_QUERIES = 2

		def create
			max_queries = requested_max_queries
			result = Esocial::OfficialTablesSyncExecutor.call(max_queries: max_queries)
			redirect_to esocial_sync_path, notice: "Execucao oficial finalizada: #{result.calls_used}/#{max_queries} chamadas usadas; XMLs S-1005=#{result.xml_counts["S-1005"]}, S-1020=#{result.xml_counts["S-1020"]}."
		rescue ArgumentError => error
			redirect_to esocial_certificado_path, alert: error.message
		rescue StandardError => error
			redirect_to esocial_sync_path, alert: "Falha na execucao oficial: #{error.message}"
		end

		private

		def requested_max_queries
			requested = params.fetch(:max_queries, DEFAULT_MAX_QUERIES).to_i
			requested.clamp(1, DEFAULT_MAX_QUERIES)
		end
	end
end