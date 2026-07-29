module FiscalAuditor
  class TaxLotationsController < BaseController
    def index
      @reference = TaxLotationsReference.new(params[:table])
    end
  end
end