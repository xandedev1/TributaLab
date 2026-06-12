require "test_helper"

module Esocial
	class OfficialTablesSyncPlanTest < ActiveSupport::TestCase
		test "creates a ready plan only for requested registration tables" do
			run = OfficialTablesSyncPlan.create!(usage_date: Date.new(2026, 6, 10))

			assert_equal "ready", run.status
			assert_equal ["S-1005", "S-1020"], run.target_events
			assert_equal 4, run.planned_queries
			assert_equal 0, run.used_queries
			assert_equal 4, run.esocial_access_logs.count
			assert_equal ["S-1005", "S-1020"], run.esocial_access_logs.distinct.order(:event_code).pluck(:event_code)
			assert_empty run.esocial_access_logs.where(event_code: ["S-1000", "S-1070"])
		end

		test "blocks a plan that would pass the daily limit" do
			usage_date = Date.new(2026, 6, 10)
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
			assert_equal 8, blocked_run.used_queries
			assert_equal 4, blocked_run.esocial_access_logs.where(status: "blocked").count
		end
	end
end