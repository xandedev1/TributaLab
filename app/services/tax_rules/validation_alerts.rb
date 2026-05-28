module TaxRules
  class ValidationAlerts
    OPEN_STATUSES = %w[pending divergent].freeze

    def initialize(tax_module:, operation: nil)
      @tax_module = tax_module
      @operation = operation
    end

    def call
      parameter_alerts + assumption_alerts
    end

    private

    attr_reader :tax_module, :operation

    def parameter_alerts
      parameter_scope.map do |parameter|
        {
          type: "parameter",
          code: parameter.code,
          title: parameter.name,
          status: parameter.validation_status,
          description: parameter.notes,
          operation: parameter.operation&.name
        }
      end
    end

    def assumption_alerts
      assumption_scope.map do |assumption|
        {
          type: "assumption",
          code: assumption.code,
          title: assumption.title,
          status: assumption.status,
          description: assumption.description,
          operation: assumption.operation&.name
        }
      end
    end

    def parameter_scope
      scope = tax_module.tax_parameters.open_for_validation.includes(:operation).order(:code)
      operation ? scope.where(operation: [nil, operation]) : scope
    end

    def assumption_scope
      scope = tax_module.assumptions.open_for_validation.includes(:operation).ordered
      operation ? scope.where(operation: [nil, operation]) : scope
    end
  end
end