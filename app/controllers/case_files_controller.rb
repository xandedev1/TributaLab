class CaseFilesController < ApplicationController
  def index
    @case_files = CaseFile.includes(:simulations).ordered
  end

  def show
    @case_file = CaseFile.includes(simulations: [:tax_module, :operation, :tax_rule_version, :simulation_result]).find(params[:id])
    @simulations = @case_file.simulations.order(created_at: :desc)
  end

  def new
    @case_file = CaseFile.new(status: "active")
  end

  def create
    @case_file = CaseFile.new(case_file_params)

    if @case_file.save
      redirect_to case_file_path(@case_file), notice: "Caso interno criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def case_file_params
    params.require(:case_file).permit(:name, :description, :status, :reference_code, :notes)
  end
end