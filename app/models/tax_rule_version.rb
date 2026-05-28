class TaxRuleVersion < ApplicationRecord
  STATUSES = %w[pending_validation active archived].freeze

  belongs_to :tax_module

  has_many :simulations, dependent: :restrict_with_exception

  validates :code, :name, :status, presence: true
  validates :code, uniqueness: { scope: :tax_module_id }
  validates :status, inclusion: { in: STATUSES }

  scope :ordered, -> { order(effective_from: :desc, created_at: :desc) }
end