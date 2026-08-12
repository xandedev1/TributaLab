module FiscalAuditor
  class EfdRazaoController < BaseController
    def show
      @dashboard = EfdRazaoDashboard.new(company: current_fiscal_auditor_company)
      @selected_month = params[:month].presence

      @report =
        case params[:report]
        when "a100_txt_pdf"
          { title: "A100 · EFD → Razão (Serviços)", records: @dashboard.report_a100_txt_to_pdf(month: @selected_month) }
        when "a100_pdf_txt"
          { title: "A100 · Razão → EFD (Serviços)", records: @dashboard.report_a100_pdf_to_txt(month: @selected_month) }
        when "c100_txt_pdf"
          { title: "C100 · EFD → Razão (Vendas)", records: @dashboard.report_c100_txt_to_pdf(month: @selected_month) }
        when "c100_pdf_txt"
          { title: "C100 · Razão → EFD (Vendas)", records: @dashboard.report_c100_pdf_to_txt(month: @selected_month) }
        else
          nil
        end
    end
  end
end
