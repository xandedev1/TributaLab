class AssumptionsController < ApplicationController
  def index
    @tax_module = TaxModule.find_by!(code: params[:tax_module_code].presence || "real_estate_tax_reform")
    @assumptions = @tax_module.assumptions.includes(:operation).ordered
  end
end