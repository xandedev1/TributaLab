class SimulationsController < ApplicationController
  OPERATION_CODES = Simulations::RunSimulation::CALCULATORS.keys.freeze

  def index
    @tax_modules = TaxModule.ordered
    @tax_module = TaxModule.includes(:operations).find_by(code: params[:tax_module_code].presence || "real_estate_tax_reform")
    @operations = @tax_module ? @tax_module.operations.where(code: OPERATION_CODES).ordered : Operation.none
    @selected_operation_code = params[:operation_code].presence
    @alert_state = params[:alert_state].presence
    @date_from = params[:date_from].presence
    @date_until = params[:date_until].presence

    @simulations = Simulation.includes(:case_file, :tax_module, :operation, :tax_rule_version, :simulation_result)
      .order(created_at: :desc)
    @simulations = @simulations.where(tax_module: @tax_module) if @tax_module
    @simulations = @simulations.joins(:operation).where(operations: { code: @selected_operation_code }) if @selected_operation_code.present?
    @simulations = @simulations.where("simulations.created_at >= ?", parsed_date(@date_from)&.beginning_of_day) if parsed_date(@date_from)
    @simulations = @simulations.where("simulations.created_at <= ?", parsed_date(@date_until)&.end_of_day) if parsed_date(@date_until)
    @simulations = apply_alert_filter(@simulations, @alert_state)
  end

  def new
    load_form_context
    @selected_operation_code = selected_operation_code
    @inputs = {}.with_indifferent_access
  end

  def create
    load_form_context
    @selected_operation_code = simulation_params[:operation_code]
    @inputs = input_params.with_indifferent_access

    simulation = Simulations::RunSimulation.new(
      operation_code: @selected_operation_code,
      inputs: @inputs,
      name: simulation_params[:name],
      case_file: selected_case_file
    ).call

    redirect_to simulation_path(simulation), notice: "Simulacao salva com sucesso."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError => error
    @error_message = error.message
    render :new, status: :unprocessable_entity
  end

  def show
    @simulation = Simulation.includes(:case_file, :tax_module, :operation, :tax_rule_version, :simulation_result).find(params[:id])
    @simulation_result = @simulation.simulation_result
  end

  private

  def load_form_context
    @tax_module = TaxModule.includes(:operations, :tax_rule_versions).find_by!(code: "real_estate_tax_reform")
    @operations = @tax_module.operations.where(code: OPERATION_CODES).ordered
    @tax_rule_version = @tax_module.tax_rule_versions.ordered.first
    @case_files = CaseFile.ordered
    @operation_presenters = build_operation_presenters
  end

  def simulation_params
    params.permit(:operation_code, :name, :case_file_id)
  end

  def input_params
    params.fetch(:inputs, {}).permit(
      :sale_amount,
      :monthly_rent,
      :iptu_amount,
      :condominium_amount,
      :boot_amount,
      :contract_amount,
      :service_amount,
      :assignment_amount,
      :credits_amount
    ).to_h
  end

  def selected_operation_code
    requested_code = params[:operation_code].presence || simulation_params[:operation_code].presence
    return requested_code if OPERATION_CODES.include?(requested_code)

    OPERATION_CODES.first
  end

  def selected_case_file
    return if simulation_params[:case_file_id].blank?

    CaseFile.find(simulation_params[:case_file_id])
  end

  def build_operation_presenters
    @operations.each_with_object({}) do |operation, presenters|
      calculator = Simulations::RunSimulation::CALCULATORS.fetch(operation.code)
      presenters[operation.code] = {
        parameters: calculator::PARAMETER_CODES.map { |code| parameter_for(operation, code) }.compact,
        alerts: TaxRules::ValidationAlerts.new(tax_module: @tax_module, operation:).call
      }
    end
  end

  def parameter_for(operation, code)
    @tax_module.tax_parameters
      .where(code:, operation_id: [nil, operation.id])
      .order(Arel.sql("CASE WHEN operation_id IS NULL THEN 0 ELSE 1 END DESC"))
      .first
  end

  def parsed_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def apply_alert_filter(scope, alert_state)
    case alert_state
    when "with_alerts"
      scope.where("jsonb_array_length(alerts_snapshot) > 0")
    when "without_alerts"
      scope.where("jsonb_array_length(alerts_snapshot) = 0")
    else
      scope
    end
  end
end