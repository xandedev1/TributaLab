class CreditCategory < ApplicationRecord
  VALIDATION_STATUSES = %w[validated pending divergent replaced].freeze

  belongs_to :tax_module

  validates :code, :name, :validation_status, presence: true
  validates :code, uniqueness: { scope: :tax_module_id }
  validates :validation_status, inclusion: { in: VALIDATION_STATUSES }
end
