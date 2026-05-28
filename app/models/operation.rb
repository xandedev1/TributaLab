class Operation < ApplicationRecord
  STATUSES = %w[active informational planned archived].freeze

  belongs_to :tax_module

  has_many :tax_parameters, dependent: :restrict_with_exception
  has_many :assumptions, dependent: :restrict_with_exception
  has_many :simulations, dependent: :restrict_with_exception

  validates :code, :name, :status, presence: true
  validates :code, uniqueness: { scope: :tax_module_id }
  validates :status, inclusion: { in: STATUSES }

  scope :ordered, -> { order(:position, :name) }
end
