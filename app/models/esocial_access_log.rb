class EsocialAccessLog < ApplicationRecord
	STATUSES = %w[planned blocked running completed failed skipped].freeze
	CONSUMED_STATUSES = %w[completed failed].freeze

	belongs_to :esocial_sync_run

	validates :event_code, :table_name, :service_name, :operation_name, :usage_date, :status, presence: true
	validates :status, inclusion: { in: STATUSES }
	validates :query_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

	scope :for_date, ->(date) { where(usage_date: date) }
	scope :consumed, -> { where(status: CONSUMED_STATUSES) }
	scope :planned_or_ready, -> { where(status: %w[planned running]) }
end