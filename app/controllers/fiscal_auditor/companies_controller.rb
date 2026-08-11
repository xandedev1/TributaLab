module FiscalAuditor
  class CompaniesController < BaseController
    skip_before_action :require_fiscal_auditor_company

    COMPANIES = {
      "appa" => {
        name: "APPA Facilities",
        legal_name: "APPA Servicos Temporarios e Efetivos LTDA",
        cnpj: "05.969.071/0001-10",
        tag: "Base consolidada",
        description: "Faturamento, retencoes, folha e contas vinculadas processadas."
      },
      "solucoes" => {
        name: "Solucoes",
        legal_name: "SOLUCOES SERVICOS TERCEIRIZADOS LTDA.",
        cnpj: "09.445.502/0001-09",
        tag: "Aguardando dados",
        description: "Estrutura pronta. Nenhum arquivo subido ate o momento."
      }
    }.freeze

    def index
      @companies = COMPANIES
    end

    def select
      company = params[:company]
      unless COMPANIES.key?(company)
        redirect_to fiscal_auditor_companies_path, alert: "Empresa invalida."
        return
      end

      session[:fiscal_auditor_company] = company
      redirect_to fiscal_auditor_root_path, notice: "Empresa #{COMPANIES[company][:name]} selecionada."
    end
  end
end
