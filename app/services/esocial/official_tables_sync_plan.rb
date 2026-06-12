module Esocial
	class OfficialTablesSyncPlan
		DAILY_LIMIT = 10
		COMPANY_CNPJ = "64.030.638/0001-58"
		COMPANY_NAME = "CTE - CENTRO DE TECNOLOGIA DE EDIFICACOES E HOLDING LTDA"

		Operation = Struct.new(:event_code, :table_name, :service_name, :operation_name, :endpoint, keyword_init: true)

		OPERATIONS = [
			Operation.new(
				event_code: "S-1005",
				table_name: "Estabelecimentos/Obras",
				service_name: "ConsultarIdentificadoresEventos",
				operation_name: "listar identificadores S-1005",
				endpoint: "WsConsultarIdentificadoresEventos"
			),
			Operation.new(
				event_code: "S-1005",
				table_name: "Estabelecimentos/Obras",
				service_name: "SolicitarDownloadEventos",
				operation_name: "baixar XMLs S-1005",
				endpoint: "WsSolicitarDownloadEventos"
			),
			Operation.new(
				event_code: "S-1020",
				table_name: "Lotacao Tributaria",
				service_name: "ConsultarIdentificadoresEventos",
				operation_name: "listar identificadores S-1020",
				endpoint: "WsConsultarIdentificadoresEventos"
			),
			Operation.new(
				event_code: "S-1020",
				table_name: "Lotacao Tributaria",
				service_name: "SolicitarDownloadEventos",
				operation_name: "baixar XMLs S-1020",
				endpoint: "WsSolicitarDownloadEventos"
			)
		].freeze

		def self.create!(usage_date: Date.current)
			new(usage_date: usage_date).create!
		end

		def initialize(usage_date: Date.current)
			@usage_date = usage_date
		end

		def create!
			used_today = self.class.used_queries(@usage_date)
			planned_queries = OPERATIONS.size
			status = used_today + planned_queries > DAILY_LIMIT ? "blocked" : "ready"

			EsocialSyncRun.transaction do
				run = EsocialSyncRun.create!(
					company_cnpj: COMPANY_CNPJ,
					company_name: COMPANY_NAME,
					sync_scope: "registration_tables",
					environment: "production",
					status: status,
					daily_limit: DAILY_LIMIT,
					planned_queries: planned_queries,
					used_queries: used_today,
					target_events: target_events,
					notes: notes_for(status, used_today, planned_queries)
				)

				OPERATIONS.each do |operation|
					run.esocial_access_logs.create!(
						event_code: operation.event_code,
						table_name: operation.table_name,
						service_name: operation.service_name,
						operation_name: operation.operation_name,
						endpoint: operation.endpoint,
						status: status == "blocked" ? "blocked" : "planned",
						query_count: 0,
						usage_date: @usage_date,
						request_fingerprint: "#{COMPANY_CNPJ}|#{operation.event_code}|#{operation.service_name}|#{@usage_date}"
					)
				end

				run
			end
		end

		def self.used_queries(usage_date = Date.current)
			EsocialAccessLog.for_date(usage_date).consumed.sum(:query_count)
		end

		def self.reserved_queries(usage_date = Date.current)
			EsocialAccessLog.for_date(usage_date).planned_or_ready.count
		end

		def self.remaining_queries(usage_date = Date.current)
			[DAILY_LIMIT - used_queries(usage_date), 0].max
		end

		private

		def target_events
			OPERATIONS.map(&:event_code).uniq
		end

		def notes_for(status, used_today, planned_queries)
			if status == "blocked"
				"Plano bloqueado: #{used_today}/#{DAILY_LIMIT} acessos usados hoje e #{planned_queries} seriam planejados."
			else
				"Plano pronto para tabelas S-1005 e S-1020. Cliente SOAP/certificado ainda precisa executar as chamadas oficiais."
			end
		end
	end
end