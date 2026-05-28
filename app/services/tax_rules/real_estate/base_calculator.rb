module TaxRules
  module RealEstate
    class BaseCalculator
      ZERO = BigDecimal("0")
      ONE = BigDecimal("1")

      def initialize(tax_module:, tax_rule_version:, inputs: {})
        @tax_module = tax_module
        @tax_rule_version = tax_rule_version
        @inputs = inputs.to_h.with_indifferent_access
      end

      def call
        {
          operation_code: operation_code,
          inputs: normalized_inputs,
          parameters: parameter_snapshot,
          assumptions: assumption_snapshot,
          alerts: alerts,
          legal_bases: legal_basis_snapshot,
          rule_version: rule_version_snapshot,
          result: calculate,
          calculation_details: calculation_details
        }
      end

      private

      attr_reader :tax_module, :tax_rule_version, :inputs

      def operation_code
        self.class::OPERATION_CODE
      end

      def operation
        @operation ||= tax_module.operations.find_by!(code: operation_code)
      end

      def used_input_keys
        self.class::INPUT_KEYS
      end

      def used_parameter_codes
        self.class::PARAMETER_CODES
      end

      def normalized_inputs
        used_input_keys.index_with { |key| decimal_input(key) }
      end

      def parameter_snapshot
        used_parameter_codes.index_with { |code| serialize_parameter(parameter_for(code)) }
      end

      def assumption_snapshot
        assumption_scope.map do |assumption|
          {
            code: assumption.code,
            title: assumption.title,
            status: assumption.status,
            description: assumption.description,
            impact: assumption.impact,
            operation_code: assumption.operation&.code,
            source_reference: assumption.source_reference
          }
        end
      end

      def legal_basis_snapshot
        LegalBasis.order(:code).map do |legal_basis|
          {
            code: legal_basis.code,
            law: legal_basis.law,
            article: legal_basis.article,
            description: legal_basis.description,
            status: legal_basis.status,
            source_reference: legal_basis.source_reference,
            notes: legal_basis.notes
          }
        end
      end

      def rule_version_snapshot
        {
          code: tax_rule_version.code,
          name: tax_rule_version.name,
          status: tax_rule_version.status,
          effective_from: tax_rule_version.effective_from,
          effective_until: tax_rule_version.effective_until,
          source_summary: tax_rule_version.source_summary
        }
      end

      def alerts
        TaxRules::ValidationAlerts.new(tax_module:, operation:).call
      end

      def parameter_for(code)
        tax_module.tax_parameters
          .where(code:, operation_id: [nil, operation.id])
          .order(Arel.sql("CASE WHEN operation_id IS NULL THEN 0 ELSE 1 END DESC"))
          .first || raise(ActiveRecord::RecordNotFound, "TaxParameter not found: #{code}")
      end

      def parameter_value(code)
        parameter_for(code).value_decimal
      end

      def decimal_input(key)
        value = inputs[key]
        return ZERO if value.blank?

        BigDecimal(value.to_s)
      rescue ArgumentError
        ZERO
      end

      def non_negative(value)
        value.negative? ? ZERO : value
      end

      def money(value)
        value.round(2)
      end

      def rate(value)
        value.round(6)
      end

      def serialize_parameter(parameter)
        {
          code: parameter.code,
          name: parameter.name,
          parameter_type: parameter.parameter_type,
          value_decimal: parameter.value_decimal,
          unit: parameter.unit,
          validation_status: parameter.validation_status,
          operation_code: parameter.operation&.code,
          legal_reference: parameter.legal_reference,
          notes: parameter.notes
        }
      end

      def assumption_scope
        tax_module.assumptions
          .open_for_validation
          .includes(:operation)
          .where(operation_id: [nil, operation.id])
          .ordered
      end

      def calculation_details
        {
          formula: self.class::FORMULA,
          pending_validation: assumption_snapshot.map { |assumption| assumption[:code] }
        }
      end
    end
  end
end