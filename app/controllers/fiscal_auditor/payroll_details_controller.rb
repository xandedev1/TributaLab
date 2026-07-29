require "uri"

module FiscalAuditor
  class PayrollDetailsController < BaseController
    def show
      @result = PayrollComparisonDetail.new(
        client_code: params[:client_code],
        period: params[:period]
      ).result
      @return_path = return_path
    rescue ArgumentError
      head :not_found
    end

    private

    def return_path
      candidate = params[:return_to].to_s
      uri = URI.parse(candidate)
      return candidate if uri.scheme.nil? && uri.host.nil? && uri.path == fiscal_auditor_payroll_path

      fiscal_auditor_payroll_path
    rescue URI::InvalidURIError
      fiscal_auditor_payroll_path
    end
  end
end
