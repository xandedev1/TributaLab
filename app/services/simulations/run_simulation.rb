module Simulations
  class RunSimulation
    CALCULATORS = {
      "sale_property" => TaxRules::RealEstate::SalePropertyCalculator,
      "sale_residential_lot" => TaxRules::RealEstate::SaleResidentialLotCalculator,
      "lease_property" => TaxRules::RealEstate::LeasePropertyCalculator,
      "civil_construction" => TaxRules::RealEstate::ConstructionContractCalculator,
      "management_brokerage" => TaxRules::RealEstate::BrokerageAdministrationCalculator,
      "rights_assignment" => TaxRules::RealEstate::AssignmentRightsCalculator,
      "exchange_without_boot" => TaxRules::RealEstate::ExchangeWithoutBootCalculator,
      "exchange_with_boot" => TaxRules::RealEstate::ExchangeWithBootCalculator
    }.freeze

    def initialize(operation_code:, inputs:, name: nil, tax_module: nil, tax_rule_version: nil, case_file: nil)
      @operation_code = operation_code
      @inputs = inputs.to_h
      @name = name.presence
      @tax_module = tax_module || TaxModule.find_by!(code: "real_estate_tax_reform")
      @tax_rule_version = tax_rule_version || @tax_module.tax_rule_versions.ordered.first
      @case_file = case_file
    end

    def call
      raise ActiveRecord::RecordNotFound, "TaxRuleVersion not found for #{tax_module.code}" unless tax_rule_version

      calculation = calculator.new(tax_module:, tax_rule_version:, inputs:).call
      operation = tax_module.operations.find_by!(code: operation_code)

      Simulation.transaction do
        simulation = Simulation.create!(
          name: name || default_name(operation),
          case_file:,
          tax_module:,
          operation:,
          tax_rule_version:,
          input_data: serialize(calculation[:inputs]),
          output_data: serialize({ result: calculation[:result], calculation_details: calculation[:calculation_details] }),
          parameters_snapshot: serialize(calculation[:parameters]),
          assumptions_snapshot: serialize(calculation[:assumptions]),
          alerts_snapshot: serialize(calculation[:alerts]),
          legal_bases_snapshot: serialize(calculation[:legal_bases]),
          rule_version: tax_rule_version.code,
          rule_version_snapshot: serialize(calculation[:rule_version])
        )

        result = calculation[:result]
        SimulationResult.create!(
          simulation:,
          base_gross: result.fetch(:gross_base),
          applied_deduction: result.fetch(:deductions_amount),
          base_net: result.fetch(:net_base),
          full_rate: result.fetch(:full_rate),
          applied_reduction: result.fetch(:reduction_rate),
          effective_rate: result.fetch(:effective_rate),
          tax_debit: result.fetch(:debit_amount),
          credits: result.fetch(:credits_amount),
          tax_due: result.fetch(:tax_due),
          validation_alerts: serialize(calculation[:alerts]),
          calculation_details: serialize(calculation[:calculation_details])
        )

        simulation
      end
    end

    private

    attr_reader :operation_code, :inputs, :name, :tax_module, :tax_rule_version, :case_file

    def calculator
      CALCULATORS.fetch(operation_code)
    rescue KeyError
      raise ArgumentError, "Unsupported operation for Etapa 003: #{operation_code}"
    end

    def default_name(operation)
      "Simulacao - #{operation.name} - #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    end

    def serialize(value)
      case value
      when BigDecimal
        value.to_s("F")
      when Date, Time, ActiveSupport::TimeWithZone
        value.iso8601
      when Hash
        value.transform_values { |nested_value| serialize(nested_value) }
      when Array
        value.map { |nested_value| serialize(nested_value) }
      else
        value
      end
    end
  end
end