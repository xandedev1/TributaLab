class CaseFile < ApplicationRecord
  STATUSES = %w[active paused completed archived].freeze

  has_many :simulations, dependent: :nullify

  before_validation :normalize_reference_code

  validates :name, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :reference_code, uniqueness: true, allow_blank: true

  scope :ordered, -> { order(created_at: :desc, name: :asc) }

  private

  def normalize_reference_code
    self.reference_code = reference_code.presence
  end
end