module Inss
  class DashboardController < ApplicationController
    def index
      @tables_ready = PayrollImport.available?
      unless @tables_ready
        @aggregation = nil
        return
      end

      @aggregation = PayrollAggregation.new(filter_params)
      @filters = @aggregation.filters
      @totals = @aggregation.totals
      @blocos = @aggregation.by_bloco
      @inss_summary = @aggregation.inss_summary
      @competencias = @aggregation.competencias
      @contratos = @aggregation.contratos
      @situacoes = @aggregation.situacoes
      @employees = @aggregation.employees_list
      @imports_count = PayrollImport.where(status: "completed").count
    end

    private

    def filter_params
      params.permit(:competencia, :contrato_codigo, :situacao_funcional, :busca).to_h
    end
  end
end
