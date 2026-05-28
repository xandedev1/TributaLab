class Simulation < ApplicationRecord
  belongs_to :tax_module
  belongs_to :operation
  belongs_to :tax_rule_version, optional: true

  has_one :simulation_result, dependent: :destroy

  validates :name, :rule_version, presence: true
  validate :json_payloads_are_hashes

  private

  def json_payloads_are_hashes
    [:input_data, :output_data, :parameters_snapshot, :rule_version_snapshot].each do |attribute|
      errors.add(attribute, "must be a JSON object") unless public_send(attribute).is_a?(Hash)
    end

    [:assumptions_snapshot, :alerts_snapshot, :legal_bases_snapshot].each do |attribute|
      errors.add(attribute, "must be a JSON array") unless public_send(attribute).is_a?(Array)
    end
  end
end
