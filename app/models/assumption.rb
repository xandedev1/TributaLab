class Assumption < ApplicationRecord
  STATUSES = %w[pending validated divergent rejected].freeze

  belongs_to :tax_module
  belongs_to :operation, optional: true

  validates :code, :title, :status, presence: true
  validates :code, uniqueness: { scope: :tax_module_id }
  validates :status, inclusion: { in: STATUSES }

  scope :open_for_validation, -> { where(status: %w[pending divergent]) }
  scope :ordered, -> { order(:position, :title) }

  def open_for_validation?
    status.in?(%w[pending divergent])
  end
end
