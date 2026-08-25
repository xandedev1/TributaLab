module FiscalAuditor
  class TaxLotationsController < BaseController
    def index
      @reference = TaxLotationsReference.new(params[:table])
      # As lotacoes tributarias sao um export do eSocial da APPA; nenhuma outra empresa possui esses dados.
      @available = current_fiscal_auditor_company == "appa"
    end
  end
end