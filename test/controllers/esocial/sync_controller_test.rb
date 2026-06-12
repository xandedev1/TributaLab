require "test_helper"

module Esocial
	class SyncControllerTest < ActionDispatch::IntegrationTest
		test "renders official sync dashboard" do
			get esocial_sync_path

			assert_response :success
			assert_select "h1", "Tabelas da CTE"
			assert_select "body", /0\/10 registrado no TributaLab/
			assert_select "body", /S-1005/
			assert_select "body", /S-1020/
			assert_select "body", /Disparo eSocial hoje/
			assert_select "body", /Fonte oficial/
			assert_select "body", /Download Cirurgico/
			assert_select "body", /WsConsultarIdentificadoresEventos\.svc/
			assert_select "body", /WsSolicitarDownloadEventos\.svc/
			assert_select "body", /Nao e mock/
			assert_select "body", /A tela foi povoada com dois XMLs oficiais do eSocial/
			assert_select "body", /O CSV e cache tecnico do XML, nao fonte inventada/
			assert_select "body", /Nenhum disparo eSocial hoje|O eSocial nao devolveu XML no disparo de hoje|Pelo eSocial, o disparo de hoje falhou|Estabelecimentos\/Obras ainda nao/
			assert_select "input[value='Executar ate 2 consultas']"
			assert_no_match(/\bblocked\b|bloquead/i, response.body)
			assert_no_match(/autom[aá]tic/i, response.body)
			assert_no_match(/Nao houve chamada oficial para S-1005/i, response.body)
			assert_no_match(/Reservados|Alvo agora|Operacoes planejadas|Ledger de acessos/i, response.body)
		end

		test "does not render internal blocked status" do
			usage_date = Date.current
			run = EsocialSyncRun.create!(
				company_cnpj: OfficialTablesSyncPlan::COMPANY_CNPJ,
				company_name: OfficialTablesSyncPlan::COMPANY_NAME,
				daily_limit: OfficialTablesSyncPlan::DAILY_LIMIT,
				status: "completed",
				planned_queries: 0,
				used_queries: 8,
				target_events: []
			)

			8.times do |index|
				run.esocial_access_logs.create!(
					event_code: "S-1020",
					table_name: "Lotacao Tributaria",
					service_name: "SolicitarDownloadEventos",
					operation_name: "consulta consumida #{index}",
					status: "completed",
					query_count: 1,
					usage_date: usage_date
				)
			end

			blocked_run = OfficialTablesSyncPlan.create!(usage_date: usage_date)
			assert_equal "blocked", blocked_run.status

			get esocial_sync_path

			assert_response :success
			assert_no_match(/\bblocked\b|bloquead/i, response.body)
			assert_no_match(/autom[aá]tic/i, response.body)
			assert_no_match(/Nao houve chamada oficial para S-1005/i, response.body)
			assert_match(/ficou nao executada para preservar a cota diaria/i, response.body)
		end

		test "calls official executor from dashboard with capped budget" do
			captured_max_queries = nil
			result = Struct.new(:calls_used, :xml_counts).new(0, { "S-1005" => 0, "S-1020" => 0 })

			with_stubbed_executor(result, ->(value) { captured_max_queries = value }) do
				assert_no_difference -> { EsocialSyncRun.count } do
					assert_no_difference -> { EsocialAccessLog.count } do
						post esocial_sync_runs_path
					end
				end
			end

			assert_equal 2, captured_max_queries
			assert_redirected_to esocial_sync_path
		end

		test "caps requested dashboard budget at two calls" do
			captured_max_queries = nil
			result = Struct.new(:calls_used, :xml_counts).new(0, { "S-1005" => 0, "S-1020" => 0 })

			with_stubbed_executor(result, ->(value) { captured_max_queries = value }) do
				assert_no_difference -> { EsocialSyncRun.count } do
					assert_no_difference -> { EsocialAccessLog.count } do
						post esocial_sync_runs_path, params: { max_queries: 5 }
					end
				end
			end

			assert_equal 2, captured_max_queries
			assert_redirected_to esocial_sync_path
		end

		test "does not execute official run without certificate candidate" do
			assert_no_difference -> { EsocialSyncRun.count } do
				assert_no_difference -> { EsocialAccessLog.count } do
					post esocial_sync_runs_path
				end
			end

			assert_redirected_to esocial_certificado_path
			follow_redirect!
			assert_response :success
			assert_select "h1", "Certificado"
			assert_select "body", /Nenhum certificado eSocial salvo|Nenhum certificado salvo/
		end

		private

		def with_stubbed_executor(result, capture)
			original_call = Esocial::OfficialTablesSyncExecutor.method(:call)
			Esocial::OfficialTablesSyncExecutor.define_singleton_method(:call) do |max_queries:|
				capture.call(max_queries)
				result
			end
			yield
		ensure
			Esocial::OfficialTablesSyncExecutor.define_singleton_method(:call, original_call)
		end

	end
end