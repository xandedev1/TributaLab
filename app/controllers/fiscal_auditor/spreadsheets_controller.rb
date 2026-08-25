module FiscalAuditor
  class SpreadsheetsController < BaseController
    def show
      @result = SpreadsheetViewer.new(
        source_kind: params[:source_kind],
        filename: params[:filename],
        row: params[:row],
        sheet: params[:sheet],
        page: params[:page],
        company: current_fiscal_auditor_company
      ).result
      @active_module = active_module
      @return_path = return_path
    rescue ArgumentError
      head :not_found
    end

    private

    def active_module
      {
        "billing" => :billing,
        "receivables" => :receivables,
        "payables" => :expenses,
        "payroll" => :payroll,
        "payroll_charges" => :payroll
      }.fetch(params[:source_kind])
    end

    def return_path
      candidate = params[:return_to].to_s
      return candidate if candidate.start_with?("/auditor-fiscal/") && !candidate.include?("..") && !candidate.include?("\\")

      fiscal_auditor_root_path
    end
  end
end
