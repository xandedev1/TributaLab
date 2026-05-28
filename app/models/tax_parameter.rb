class TaxParameter < ApplicationRecord
  VALIDATION_STATUSES = %w[validated pending divergent replaced].freeze
  PARAMETER_TYPES = %w[rate reduction deduction money flag].freeze

  belongs_to :tax_module
  belongs_to :operation, optional: true

  validates :code, :name, :parameter_type, :unit, :validation_status, presence: true
  validates :code, uniqueness: { scope: [:tax_module_id, :operation_id] }
  validates :parameter_type, inclusion: { in: PARAMETER_TYPES }
  validates :validation_status, inclusion: { in: VALIDATION_STATUSES }
  validates :value_decimal, numericality: true

  scope :open_for_validation, -> { where(validation_status: %w[pending divergent]) }

  def open_for_validation?
    validation_status.in?(%w[pending divergent])
  end
end
