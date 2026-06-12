require "csv"

module Esocial
	class SyncDashboardSnapshot
		Metric = Struct.new(:label, :value, :detail, keyword_init: true)
		SourceDisclosure = Struct.new(:headline, :items, :source_paths, keyword_init: true)
		TableStatus = Struct.new(:event_code, :label, :path, :source_label, :source_detail, :rows_count, :official_status, :official_detail, :result_label, :result_detail, :source_disclosure, keyword_init: true) do
			def loaded?
				rows_count.to_i.positive?
			end
		end

		attr_reader :usage_date

		def initialize(usage_date: Date.current)
			@usage_date = usage_date
		end

		def metrics
			[
				Metric.new(label: "Acessos registrados", value: "#{used_queries}/#{daily_limit}", detail: "tentativas registradas no TributaLab hoje"),
				Metric.new(label: "Reservados", value: reserved_queries, detail: "operacoes planejadas e ainda nao executadas"),
				Metric.new(label: "Restantes", value: remaining_queries, detail: "saldo estimado para #{usage_date.strftime("%d/%m/%Y")}"),
				Metric.new(label: "Alvo agora", value: "S-1005 + S-1020", detail: "sem S-1000 e sem S-1070 neste MVP")
			]
		end

		def operations
			OfficialTablesSyncPlan::OPERATIONS
		end

		def preflight
			@preflight ||= PreflightDashboardSnapshot.new
		end

		def table_statuses
			estabelecimentos = EstabelecimentosObrasDashboardSnapshot.new
			lotacoes = LotacoesDashboardSnapshot.new

			[
				table_status(
					event_code: "S-1005",
					label: "Estabelecimentos/Obras",
					path: Rails.application.routes.url_helpers.esocial_estabelecimentos_obras_path,
					snapshot: estabelecimentos
				),
				table_status(
					event_code: "S-1020",
					label: "Lotacao Tributaria",
					path: Rails.application.routes.url_helpers.esocial_lotacoes_path,
					snapshot: lotacoes
				)
			]
		end

		def latest_runs
			@latest_runs ||= EsocialSyncRun.includes(:esocial_access_logs).order(created_at: :desc).limit(8)
		end

		def today_logs
			@today_logs ||= EsocialAccessLog.for_date(usage_date).order(created_at: :desc).limit(20)
		end

		def official_used_label
			"#{used_queries}/#{daily_limit} registrado no TributaLab"
		end

		def official_title
			return "Disparos eSocial falharam" if consumed_logs.any? && consumed_logs.all? { |log| log.status == "failed" }
			return "Disparo eSocial registrado" if consumed_logs.any?

			"Nenhum disparo eSocial hoje"
		end

		def official_detail
			return "Ainda nao houve disparo contra o eSocial hoje." if consumed_logs.empty?

			failed_count = consumed_logs.count { |log| log.status == "failed" }
			completed_count = consumed_logs.count { |log| log.status == "completed" }
			if failed_count.positive? && completed_count.zero?
				events = consumed_logs.map(&:event_code).uniq.join(", ")
				"Foram feitos #{failed_count} disparos oficiais hoje (#{events}). #{official_failure_summary} O eSocial nao devolveu XML. O contador mostra so o que o TributaLab registrou; a cota real do eSocial e compartilhada e pode ter sido gasta fora do sistema."
			else
				"Disparos oficiais registrados hoje: #{completed_count} concluidos, #{failed_count} falharam."
			end
		end

		def official_attempt_status
			official_attempt&.status || "sem chamada"
		end

		def used_queries
			OfficialTablesSyncPlan.used_queries(usage_date)
		end

		def reserved_queries
			OfficialTablesSyncPlan.reserved_queries(usage_date)
		end

		def remaining_queries
			OfficialTablesSyncPlan.remaining_queries(usage_date)
		end

		def daily_limit
			OfficialTablesSyncPlan::DAILY_LIMIT
		end

		private

		def table_status(event_code:, label:, path:, snapshot:)
			rows_count = snapshot.events_count
			official_log = EsocialAccessLog.for_date(usage_date).where(event_code: event_code).order(updated_at: :desc).first

			TableStatus.new(
				event_code: event_code,
				label: label,
				path: path,
				source_label: snapshot.source_label,
				source_detail: snapshot.source_detail,
				rows_count: rows_count,
				official_status: official_log&.status || "nao planejado",
				official_detail: official_log&.response_summary.presence || official_log&.error_message.presence || "sem chamada oficial registrada",
				result_label: rows_count.positive? ? "Encontrado" : "Nao encontrado",
				result_detail: table_result_detail(event_code, snapshot, rows_count),
				source_disclosure: source_disclosure(event_code, snapshot, official_log)
			)
		end

		def source_disclosure(event_code, snapshot, official_log)
			SourceDisclosure.new(
				headline: source_headline(event_code, snapshot),
				items: [
					[ "Base real que povoou a tela", source_base_description(event_code, snapshot) ],
					[ "Como entrou no sistema", source_pipeline_description(event_code, snapshot) ],
					[ "Arquivo interno", snapshot.source_detail ],
					[ "Disparo eSocial hoje", esocial_trigger_description(event_code, snapshot, official_log) ],
					[ "Canal oficial para novas buscas", official_endpoint_description ],
					[ "Informacoes puxadas", extracted_information_description(event_code, snapshot) ],
					[ "Aviso de confianca", "Nao e mock, nao e seed e nao e dado demonstrativo. Se o XML/CSV real nao existir, o status fica como nao encontrado." ]
				],
				source_paths: source_paths(snapshot)
			)
		end

		def source_headline(event_code, snapshot)
			return "Fonte oficial: XML S-1005 da CTE encontrado localmente" if event_code == "S-1005" && snapshot.source_label == "S-1005 XML"
			return "Fonte oficial: totalizador S-5011 da CTE usado como evidencia" if event_code == "S-1005" && snapshot.source_label == "S-5011 oficial"
			return "Fonte oficial: XML S-1020 dentro dos ZIPs da CTE" if event_code == "S-1020" && snapshot.source_label == "XML CTE ZIP"

			"Fonte oficial: #{snapshot.source_label}"
		end

		def source_base_description(event_code, snapshot)
			case event_code
			when "S-1005"
				return "A tela foi povoada com dois XMLs oficiais do eSocial ja baixados em Downloads, ambos com retornoEventoCompleto/evtTabEstab S-1005 da CTE. Empregador 64030638, estabelecimento 64030638000158." if snapshot.source_label == "S-1005 XML"
				return "Linhas ideEstab/infoEstab de totalizadores S-5011 oficiais dos ZIPs da CTE; usada apenas quando o S-1005 direto nao esta carregado." if snapshot.source_label == "S-5011 oficial"

				"CSV local gerado a partir de arquivos informados ao extrator S-1005."
			when "S-1020"
				"XMLs evtTabLotacao S-1020 extraidos dos ZIPs locais da CTE, preservando codigo de lotacao como texto."
			else
				"Arquivos locais processados pelo extrator da tabela."
			end
		end

		def source_pipeline_description(event_code, snapshot)
			case event_code
			when "S-1005"
				return "O extrator local leu os XMLs oficiais eSocial, gravou tmp/estabelecimentos_s1005/estabelecimentos_s1005_eventos.csv e a tela le esse CSV. O CSV e cache tecnico do XML, nao fonte inventada." if snapshot.source_label == "S-1005 XML"

				"O extrator local leu totalizadores oficiais e gravou o CSV tecnico usado pela tela."
			when "S-1020"
				"O extrator local leu os XMLs S-1020 dentro dos ZIPs oficiais da CTE, gravou tmp/lotacoes_s1020_cte_zips/lotacoes_s1020_eventos.csv e a tela le esse CSV."
			else
				"O extrator local leu arquivos reais e gravou o CSV tecnico usado pela tela."
			end
		end

		def esocial_trigger_description(event_code, snapshot, official_log)
			if snapshot.data_from_csv?
				return loaded_source_trigger_description(event_code, official_log)
			end

			if official_log.present?
				return official_log_description(event_code, official_log)
			end

			"Nenhum disparo eSocial foi executado para preencher esta tabela."
		end

		def loaded_source_trigger_description(event_code, official_log)
			base = "O preenchimento desta tabela veio dos XMLs/ZIPs oficiais ja baixados e listados em Caminho fonte. O disparo eSocial de hoje nao foi a fonte desses dados."

			return base unless official_log.present?

			case official_log.status
			when "blocked"
				"#{base} A busca de novas versoes para #{event_code} ficou nao executada para preservar a cota diaria do Download Cirurgico."
			when "planned"
				"#{base} Existe uma busca planejada para #{event_code}, mas ela ainda nao foi disparada."
			when "failed"
				"#{base} Houve disparo para #{event_code}, ele consumiu acesso e falhou: #{official_log.response_summary.presence || official_log.error_message.presence}."
			when "completed"
				"#{base} Tambem ha registro de disparo concluido para #{event_code}: #{official_log.response_summary.presence || official_log.error_message.presence || "sem detalhe adicional"}."
			else
				base
			end
		end

		def official_log_description(event_code, official_log)
			case official_log.status
			when "blocked"
				"A operacao de #{event_code} ficou nao executada porque o plano ultrapassaria a cota diaria de #{daily_limit} consultas do Download Cirurgico."
			when "planned"
				"Disparo eSocial para #{event_code} apenas planejado; ainda nao foi executado."
			when "running"
				"Disparo eSocial para #{event_code} em execucao."
			when "completed"
				"Disparo eSocial para #{event_code} concluido. #{official_log.response_summary.presence || official_log.error_message.presence}".strip
			when "failed"
				"Disparo eSocial para #{event_code} consumiu acesso, mas falhou. #{official_log.response_summary.presence || official_log.error_message.presence}".strip
			when "skipped"
				"Disparo eSocial para #{event_code} pulado pelo controle de execucao. #{official_log.response_summary.presence || official_log.error_message.presence}".strip
			else
				"Registro tecnico do disparo eSocial para #{event_code}: #{official_log.response_summary.presence || official_log.error_message.presence || "sem detalhe adicional"}."
			end
		end

		def official_endpoint_description
			"XMLs com tpAmb=1 (producao). O conector oficial usa Download Cirurgico do eSocial por certificado: WsConsultarIdentificadoresEventos.svc para localizar recibos/identificadores e WsSolicitarDownloadEventos.svc para baixar os XMLs."
		end

		def extracted_information_description(event_code, snapshot)
			case event_code
			when "S-1005"
				return "CNPJ do estabelecimento, inicio/fim de validade, CNAE preponderante, GILRAT/RAT, recibo oficial, ID do evento, hash SHA-256 e caminho do XML. O RAT veio do retorno infoEstabelecimento/aliqRat quando nao existe aliqGilrat dentro de dadosEstab." if snapshot.source_label == "S-1005 XML"

				"CNPJ do estabelecimento, CNAE, RAT, FAP, RAT ajustado, recibo e periodo de apuracao quando a fonte for S-5011."
			when "S-1020"
				"Codigo da lotacao, acao do evento, inicio/fim de validade, tipo de lotacao, FPAS, codigo de terceiros, processo/suspensao quando existir, CNO/CNPJ vinculado, recibo oficial, ID do evento, hash SHA-256 e caminho do XML."
			else
				"Campos oficiais extraidos do XML e exibidos na tabela correspondente."
			end
		end

		def source_paths(snapshot)
			snapshot.all_rows.filter_map do |row|
				source_path = row.respond_to?(:source_path) ? row.source_path.to_s : ""
				xml_path = row.respond_to?(:xml_path) ? row.xml_path.to_s : ""
				next if source_path.blank? && xml_path.blank?

				[ source_path.presence, xml_path.presence ].compact.join(" -> ")
			end.uniq.first(6)
		end

		def table_result_detail(event_code, snapshot, rows_count)
			if rows_count.positive?
				return "Encontrei #{rows_count} eventos S-1005 reais da CTE em XML. A tabela ja tem estabelecimento, CNAE, RAT e recibos oficiais." if event_code == "S-1005" && snapshot.source_label == "S-1005 XML"
				return "Encontrei #{rows_count} evidencias reais de estabelecimento/obra nos totalizadores S-5011 da CTE. O XML S-1005 direto ainda nao apareceu, mas a aba ja tem CNPJ, CNAE, RAT, FAP e RAT ajustado oficiais." if event_code == "S-1005" && snapshot.source_label == "S-5011 oficial"
				return "#{rows_count} eventos reais lidos dos ZIPs locais da CTE." if event_code == "S-1020" && snapshot.source_label == "XML CTE ZIP"

				"#{rows_count} eventos reais carregados de #{snapshot.source_label}."
			elsif event_code == "S-1005"
				"Nao apareceu S-1005 nos ZIPs locais da CTE. O disparo eSocial de hoje tambem nao trouxe XML porque o eSocial respondeu ServiceActivationException."
			else
				"Nenhum XML ou CSV real foi carregado para esta tabela."
			end
		end

		def official_attempt
			@official_attempt ||= today_logs.find { |log| log.query_count.to_i.positive? }
		end

		def consumed_logs
			@consumed_logs ||= today_logs.select { |log| log.query_count.to_i.positive? }
		end

		def official_failure_summary
			messages = consumed_logs.filter_map do |log|
				[ log.response_summary, log.error_message ].compact_blank.join(" ").presence
			end

			parts = []
			service_activation_count = messages.count { |message| message.include?("ServiceActivationException") }
			invalid_request_count = messages.count { |message| message.include?("402") || message.include?("Solicita") }
			interval_count = messages.count { |message| message.include?("410") || message.include?("Intervalo") }

			parts << "#{service_activation_count} retornaram 500 ServiceActivationException" if service_activation_count.positive?
			parts << "#{interval_count} retornou 410 intervalo maximo de 31 dias" if interval_count == 1
			parts << "#{interval_count} retornaram 410 intervalo maximo de 31 dias" if interval_count > 1
			parts << "#{invalid_request_count} retornou 402 solicitacao invalida" if invalid_request_count == 1
			parts << "#{invalid_request_count} retornaram 402 solicitacao invalida" if invalid_request_count > 1

			return "O eSocial retornou falhas sem detalhe consolidado." if parts.empty?

			"O eSocial respondeu: #{parts.to_sentence}."
		end
	end
end