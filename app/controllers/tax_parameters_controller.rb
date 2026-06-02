class TaxParametersController < ApplicationController
  def index
    @tax_module = TaxModule.find_by!(code: params[:tax_module_code].presence || "real_estate_tax_reform")
    @parameters = @tax_module.tax_parameters.includes(:operation).order(:code)
  end
end