class SimulationResult < ApplicationRecord
  belongs_to :simulation

  validates :base_gross, :applied_deduction, :base_net, :full_rate, :applied_reduction,
    :effective_rate, :tax_debit, :credits, :tax_due, numericality: true
  validate :calculation_details_is_hash

  private

  def calculation_details_is_hash
    errors.add(:calculation_details, "must be a JSON object") unless calculation_details.is_a?(Hash)
  end
end
