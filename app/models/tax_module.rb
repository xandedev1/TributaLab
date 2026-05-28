class TaxModule < ApplicationRecord
  STATUSES = %w[active planned archived].freeze

  belongs_to :product_area
  belongs_to :sector

  has_many :operations, dependent: :restrict_with_exception
  has_many :tax_parameters, dependent: :restrict_with_exception
  has_many :assumptions, dependent: :restrict_with_exception
  has_many :credit_categories, dependent: :restrict_with_exception
  has_many :tax_rule_versions, dependent: :restrict_with_exception
  has_many :simulations, dependent: :restrict_with_exception

  validates :code, :name, :status, presence: true
  validates :code, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :ordered, -> { order(:position, :name) }
end
