module FiscalAuditor
  class CalculationDetailsController < BaseController
    def show
      @detail = CalculationDetail.new(
        module_name: params[:module_name],
        metric: params[:metric],
        params: params,
        page: params[:page]
      )
      @result = @detail.result
      @active_module = active_module
      @back_path = back_path
    rescue ArgumentError
      head :not_found
    end

    private

    def active_module
      {
        "billing" => :billing,
        "receivables" => :receivables,
        "reconciliation" => :reconciliation,
        "expenses" => :expenses,
        "payroll" => :payroll
      }.fetch(params[:module_name])
    end

    def back_path
      filters = request.query_parameters.except("page").reject { |key, _| key.start_with?("detail_") }
      case params[:module_name]
      when "billing" then fiscal_auditor_root_path(filters)
      when "receivables" then fiscal_auditor_receivables_path(filters)
      when "reconciliation" then fiscal_auditor_reconciliation_path(filters)
      when "expenses" then fiscal_auditor_expenses_path(filters)
      when "payroll" then fiscal_auditor_payroll_path(filters)
      end
    end
  end
end
