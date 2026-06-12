require "json"
require "fileutils"
require "open3"
require "shellwords"

module Esocial
	class OfficialTablesSyncExecutor
		MAX_QUERIES = 5
		COMPANY_CNPJ = OfficialTablesSyncPlan::COMPANY_CNPJ
		COMPANY_NAME = OfficialTablesSyncPlan::COMPANY_NAME

		IdentifierRequest = Struct.new(:event_code, :table_name, :event_key, :start_at, :end_at, :label, keyword_init: true)
		Result = Struct.new(:run, :calls_used, :xml_counts, keyword_init: true) do
			def success?
				run&.status == "completed"
			end
		end

		IDENTIFIER_REQUESTS = [
			IdentifierRequest.new(
				event_code: "S-1005",
				table_name: "Estabelecimentos/Obras",
				event_key: "tpInsc=1;nrInsc=64030638000158;iniValid=2023-01;fimValid=;",
				start_at: "2023-01-18T00:00:00-03:00",
				end_at: "2023-01-19T23:59:59-03:00",
				label: "S-1005 estabelecimento CTE chave completa 2023-01"
			),
			IdentifierRequest.new(
				event_code: "S-1020",
				table_name: "Lotacao Tributaria",
				event_key: "codLotacao=SECTECENT200000000000000000008;iniValid=2025-04;fimValid=;",
				start_at: "2025-04-01T00:00:00-03:00",
				end_at: "2025-04-02T23:59:59-03:00",
				label: "S-1020 lotacao CTE chave completa 2025-04"
			),
			IdentifierRequest.new(
				event_code: "S-1020",
				table_name: "Lotacao Tributaria",
				event_key: "codLotacao=SECTECENT200000000000000000008;iniValid=2025-01;fimValid=2025-03;",
				start_at: "2025-04-02T00:00:00-03:00",
				end_at: "2025-04-03T23:59:59-03:00",
				label: "S-1020 lotacao CTE chave completa 2025-01"
			),
			IdentifierRequest.new(
				event_code: "S-1020",
				table_name: "Lotacao Tributaria",
				event_key: "codLotacao=SECTECENT200000000000000000008;iniValid=2018-07;fimValid=2024-12;",
				start_at: "2025-03-31T00:00:00-03:00",
				end_at: "2025-04-01T23:59:59-03:00",
				label: "S-1020 lotacao CTE chave completa 2018-07"
			),
			IdentifierRequest.new(
				event_code: "S-1005",
				table_name: "Estabelecimentos/Obras",
				event_key: "tpInsc=1;nrInsc=64030638000158;iniValid=2022-01;fimValid=;",
				start_at: "2022-02-02T00:00:00-03:00",
				end_at: "2022-02-03T23:59:59-03:00",
				label: "S-1005 estabelecimento CTE chave completa 2022-01"
			)
		].freeze

		def self.call(max_queries: MAX_QUERIES)
			new(max_queries: max_queries).call
		end

		def initialize(max_queries: MAX_QUERIES)
			@max_queries = [max_queries.to_i, MAX_QUERIES].select(&:positive?).min || MAX_QUERIES
			@output_root = Rails.root.join("storage", "esocial_official", "cte", Date.current.strftime("%Y%m%d"))
			@downloaded_xml_paths = Hash.new { |hash, key| hash[key] = [] }
			@found_event_codes = {}
			@calls_used = 0
		end

		def call
			certificate = certificate_for_execution
			remaining_today = OfficialTablesSyncPlan.remaining_queries(Date.current)
			raise ArgumentError, "Saldo local insuficiente para chamadas oficiais hoje." if remaining_today <= 0

			@budget = [@max_queries, remaining_today].min
			run = create_run!

			IDENTIFIER_REQUESTS.each do |request|
				break if budget_exhausted?
				next if @found_event_codes[request.event_code]
				next if already_attempted_today?(request)

				identifier_payload = execute_identifier(run, certificate, request)
				events = Array(identifier_payload["events"])
				next if events.empty?

				@found_event_codes[request.event_code] = true
				execute_download(run, certificate, request, events) unless budget_exhausted?
			end

			postprocess_downloaded_xmls
			finish_run!(run)
			Result.new(run: run, calls_used: @calls_used, xml_counts: xml_counts)
		rescue StandardError => error
			run&.update!(status: "failed", notes: error.message)
			raise
		end

		private

		def certificate_for_execution
			certificate = EsocialCertificate.includes(:esocial_company_authorizations).order(active: :desc, expires_at: :desc, created_at: :desc).first
			raise ArgumentError, "Nenhum certificado eSocial salvo." unless certificate
			raise ArgumentError, "Certificado salvo nao esta valido agora." unless certificate.valid_now?
			raise ArgumentError, "Senha criptografada do certificado nao abriu." if certificate.password.blank?
			raise ArgumentError, "Arquivo PFX salvo nao foi encontrado." unless File.file?(certificate.storage_path.to_s)

			certificate
		end

		def create_run!
			EsocialSyncRun.create!(
				company_cnpj: COMPANY_CNPJ,
				company_name: COMPANY_NAME,
				sync_scope: "registration_tables",
				environment: "production",
				status: "running",
				daily_limit: OfficialTablesSyncPlan::DAILY_LIMIT,
				planned_queries: @budget,
				used_queries: OfficialTablesSyncPlan.used_queries(Date.current),
				target_events: ["S-1005", "S-1020"],
				notes: "Execucao oficial autorizada pelo usuario: ate #{@budget} chamadas para S-1005/S-1020."
			)
		end

		def execute_identifier(run, certificate, request)
			payload = call_bridge(
				certificate,
				[
					"ident-tabela",
					"--event-code", request.event_code,
					"--event-key", request.event_key,
					"--start", request.start_at,
					"--end", request.end_at,
					"--company-cnpj", COMPANY_CNPJ,
					"--output-dir", output_dir_for(request.event_code, "identificadores").to_s,
					"--production"
				]
			)

			record_log!(
				run: run,
				request: request,
				service_name: "ConsultarIdentificadoresEventosTabela",
				operation_name: "consultar identificadores #{request.label}",
				endpoint: "WsConsultarIdentificadoresEventos",
				payload: payload
			)
			payload
		end

		def execute_download(run, certificate, request, events)
			ids = events.filter_map { |event| event["id"].presence }.uniq
			return if ids.empty?

			payload = call_bridge(
				certificate,
				[
					"download-ids",
					"--ids", ids.first(50).join(","),
					"--company-cnpj", COMPANY_CNPJ,
					"--output-dir", output_dir_for(request.event_code, "downloads").to_s,
					"--production"
				]
			)

			@downloaded_xml_paths[request.event_code].concat(Array(payload["event_xml_paths"]))
			record_log!(
				run: run,
				request: request,
				service_name: "SolicitarDownloadEventosPorId",
				operation_name: "baixar XMLs #{request.event_code} por ID oficial",
				endpoint: "WsSolicitarDownloadEventos",
				payload: payload
			)
		end

		def call_bridge(certificate, arguments)
			stdout, stderr, status = Open3.capture3(bridge_env(certificate), python_executable, Rails.root.join("script", "esocial_official_bridge.py").to_s, *arguments)
			payload = JSON.parse(stdout.lines.last.to_s)
			payload["process_success"] = status.success?
			payload["stderr"] = stderr.to_s.truncate(800) if stderr.present?
			payload
		rescue JSON::ParserError => error
			{
				"success" => false,
				"official_request_attempted" => false,
				"consumed_query" => false,
				"erro" => "Ponte oficial nao retornou JSON valido: #{error.message}",
				"stderr" => stderr.to_s.truncate(800),
				"stdout" => stdout.to_s.truncate(800)
			}
		end

		def bridge_env(certificate)
			env = {
				"TRIBUTALAB_ESOCIAL_PFX_PATH" => certificate.storage_path.to_s,
				"TRIBUTALAB_ESOCIAL_PFX_PASSWORD" => certificate.password.to_s,
				"TRIBUTALAB_ESOCIAL_HOLDER_DOCUMENT" => certificate.holder_document.to_s,
				"TRIBUTALAB_ESOCIAL_DUMP_REQUEST_DIR" => @output_root.join("requests").to_s
			}
			windows_bundle_path = WindowsCertificateBundle.path
			env["REQUESTS_CA_BUNDLE"] = windows_bundle_path if windows_bundle_path.present?
			env
		end

		def python_executable
			ENV.fetch("PYTHON", "python")
		end

		def record_log!(run:, request:, service_name:, operation_name:, endpoint:, payload:)
			consumed = consumed_query?(payload)
			@calls_used += 1 if consumed
			status = payload["success"] ? "completed" : "failed"
			message = response_message(payload)

			run.esocial_access_logs.create!(
				event_code: request.event_code,
				table_name: request.table_name,
				service_name: service_name,
				operation_name: operation_name,
				endpoint: endpoint,
				status: status,
				query_count: consumed ? 1 : 0,
				usage_date: Date.current,
				requested_at: parse_time(payload["requested_at"]),
				completed_at: Time.current,
				request_fingerprint: request_fingerprint(request, service_name, payload),
				response_summary: message,
				error_message: payload["success"] ? nil : message
			)

			write_result_payload(request, service_name, payload)
		end

		def consumed_query?(payload)
			return false unless payload["consumed_query"]

			!payload["erro"].to_s.include?("PRE_REQUEST")
		end

		def response_message(payload)
			parts = []
			parts << "codigo #{safe_text(payload["codigo_resposta"])}" if safe_text(payload["codigo_resposta"]).present?
			parts << safe_text(payload["descricao"]) if safe_text(payload["descricao"]).present?
			parts << safe_text(payload["erro"]) if safe_text(payload["erro"]).present?
			parts << "#{payload["event_count"]} identificadores" if payload.key?("event_count")
			parts << "#{payload["arquivo_count"]} arquivos" if payload.key?("arquivo_count")
			parts.compact_blank.join(" | ").presence || "sem detalhe"
		end

		def safe_text(value)
			value.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
		end

		def request_fingerprint(request, service_name, payload)
			[
				request.event_code,
				service_name,
				request.event_key,
				request.start_at,
				request.end_at,
				payload["raw_xml_path"],
				Time.current.to_i
			].compact.join("|")
		end

		def write_result_payload(request, service_name, payload)
			FileUtils.mkdir_p(output_dir_for(request.event_code, "resultados"))
			path = output_dir_for(request.event_code, "resultados").join("#{service_name.parameterize}_#{Time.current.strftime("%H%M%S")}.json")
			File.write(path, JSON.pretty_generate(sanitize_payload(payload)))
		end

		def sanitize_payload(value)
			case value
			when Hash
				value.transform_values { |item| sanitize_payload(item) }
			when Array
				value.map { |item| sanitize_payload(item) }
			when String
				safe_text(value)
			else
				value
			end
		end

		def already_attempted_today?(request)
			EsocialAccessLog
				.where(event_code: request.event_code, service_name: "ConsultarIdentificadoresEventosTabela")
				.where("operation_name LIKE ?", "%#{request.label}%")
				.where("query_count > 0")
				.exists?
		end

		def postprocess_downloaded_xmls
			if @downloaded_xml_paths["S-1005"].any?
				EstabelecimentosObrasExtractor.call(
					source_paths: @downloaded_xml_paths["S-1005"],
					output_dir: Rails.root.join("tmp", "estabelecimentos_s1005_oficial"),
					current_on: Date.current
				)
			end

			if @downloaded_xml_paths["S-1020"].any?
				LotacaoTributariaExtractor.call(
					source_paths: @downloaded_xml_paths["S-1020"],
					output_dir: Rails.root.join("tmp", "lotacoes_s1020_oficial"),
					current_on: Date.current
				)
			end
		end

		def finish_run!(run)
			failed_calls = run.esocial_access_logs.where(status: "failed").count
			completed_calls = run.esocial_access_logs.where(status: "completed").count
			status = completed_calls.positive? ? "completed" : "failed"
			run.update!(
				status: status,
				used_queries: OfficialTablesSyncPlan.used_queries(Date.current),
				notes: "Execucao oficial finalizada: #{@calls_used}/#{@budget} chamadas consumidas; #{completed_calls} concluidas; #{failed_calls} falharam; XMLs oficiais S-1005=#{xml_counts["S-1005"]}, S-1020=#{xml_counts["S-1020"]}."
			)
		end

		def xml_counts
			{
				"S-1005" => @downloaded_xml_paths["S-1005"].size,
				"S-1020" => @downloaded_xml_paths["S-1020"].size
			}
		end

		def output_dir_for(event_code, kind)
			@output_root.join(event_code.downcase.delete("-"), kind)
		end

		def budget_exhausted?
			@calls_used >= @budget
		end

		def parse_time(value)
			Time.zone.parse(value.to_s)
		rescue ArgumentError, TypeError
			Time.current
		end
	end
end
