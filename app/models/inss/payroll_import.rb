module Inss
  class PayrollImport < ApplicationRecord
    self.table_name = "inss_payroll_imports"

    STATUSES = %w[pending processing completed failed].freeze

    has_many :employees,
      class_name: "Inss::PayrollEmployee",
      foreign_key: :inss_payroll_import_id,
      dependent: :destroy,
      inverse_of: :import

    validates :filename, :content_hash, presence: true
    validates :content_hash, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    scope :ordered, -> { order(created_at: :desc) }

    def self.available?
      connection.data_source_exists?(table_name)
    rescue StandardError
      false
    end
  end
end
