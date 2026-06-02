class DashboardController < ApplicationController
  def index
    @tax_module = TaxModule.includes(:product_area, :sector, :operations, :tax_parameters, :assumptions, :credit_categories, :tax_rule_versions)
      .find_by(code: "real_estate_tax_reform")

    @operations = @tax_module ? @tax_module.operations.ordered : Operation.none
    @parameters = @tax_module ? @tax_module.tax_parameters.includes(:operation).order(:code) : TaxParameter.none
    @credit_categories = @tax_module ? @tax_module.credit_categories.order(:name) : CreditCategory.none
    @tax_rule_version = @tax_module&.tax_rule_versions&.ordered&.first
    @alerts = @tax_module ? TaxRules::ValidationAlerts.new(tax_module: @tax_module).call : []
    @case_files = CaseFile.ordered.limit(3)
    @simulations_count = Simulation.count
  end
end