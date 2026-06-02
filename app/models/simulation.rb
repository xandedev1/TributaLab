class Simulation < ApplicationRecord
  PRIMARY_AMOUNT_KEYS = {
    "sale_property" => "sale_amount",
    "sale_residential_lot" => "sale_amount",
    "lease_property" => "monthly_rent",
    "civil_construction" => "contract_amount",
    "management_brokerage" => "service_amount",
    "rights_assignment" => "assignment_amount",
    "exchange_with_boot" => "boot_amount",
    "exchange_without_boot" => nil
  }.freeze

  belongs_to :case_file, optional: true
  belongs_to :tax_module
  belongs_to :operation
  belongs_to :tax_rule_version, optional: true

  has_one :simulation_result, dependent: :destroy

  validates :name, :rule_version, presence: true
  validate :json_payloads_are_hashes

  def primary_amount
    input_key = PRIMARY_AMOUNT_KEYS.fetch(operation.code, nil)
    return BigDecimal("0") if input_key.blank?

    BigDecimal(input_data.fetch(input_key, 0).to_s)
  rescue ArgumentError
    BigDecimal("0")
  end

  def alert_count
    alerts_snapshot.size
  end

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
