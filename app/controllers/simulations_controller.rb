class SimulationsController < ApplicationController
  ETAPA_002_OPERATION_CODES = %w[
    sale_property
    sale_residential_lot
    lease_property
    exchange_with_boot
  ].freeze

  def new
    load_form_context
    @selected_operation_code = params[:operation_code].presence || ETAPA_002_OPERATION_CODES.first
    @inputs = {}.with_indifferent_access
  end

  def create
    load_form_context
    @selected_operation_code = simulation_params[:operation_code]
    @inputs = input_params.with_indifferent_access

    simulation = Simulations::RunSimulation.new(
      operation_code: @selected_operation_code,
      inputs: @inputs,
      name: simulation_params[:name]
    ).call

    redirect_to simulation_path(simulation), notice: "Simulacao salva com sucesso."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError => error
    @error_message = error.message
    render :new, status: :unprocessable_entity
  end

  def show
    @simulation = Simulation.includes(:tax_module, :operation, :tax_rule_version, :simulation_result).find(params[:id])
    @simulation_result = @simulation.simulation_result
  end

  private

  def load_form_context
    @tax_module = TaxModule.includes(:operations, :tax_rule_versions).find_by!(code: "real_estate_tax_reform")
    @operations = @tax_module.operations.where(code: ETAPA_002_OPERATION_CODES).ordered
    @tax_rule_version = @tax_module.tax_rule_versions.ordered.first
  end

  def simulation_params
    params.permit(:operation_code, :name)
  end

  def input_params
    params.fetch(:inputs, {}).permit(:sale_amount, :monthly_rent, :iptu_amount, :condominium_amount, :boot_amount, :credits_amount).to_h
  end
end