module Inss
  class EmployeesController < ApplicationController
    def show
      @employee = PayrollEmployee.find(params[:id])
      @entries_by_bloco = @employee.entries.order(:bloco, :codigo).group_by(&:bloco)
    end
  end
end
