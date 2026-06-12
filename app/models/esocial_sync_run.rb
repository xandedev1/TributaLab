class EsocialSyncRun < ApplicationRecord
	STATUSES = %w[planned blocked ready running completed failed].freeze

	has_many :esocial_access_logs, dependent: :destroy

	validates :company_cnpj, :company_name, :sync_scope, :environment, :status, presence: true
	validates :status, inclusion: { in: STATUSES }
	validates :daily_limit, numericality: { only_integer: true, greater_than: 0 }
	validates :planned_queries, :used_queries, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

	def blocked?
		status == "blocked"
	end

	def ready?
		status == "ready"
	end

	def target_events_label
		Array(target_events).join(", ")
	end
end