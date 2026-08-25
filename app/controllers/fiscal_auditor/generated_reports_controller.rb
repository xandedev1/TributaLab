module FiscalAuditor
  class GeneratedReportsController < BaseController
    REPORTS = [
      {
        key: "memoria_calculo",
        name: "Memória de Cálculo",
        description: "Detalhamento linha a linha de como cada imposto e valor foi calculado.",
        entry: "Abre ao clicar num valor no Faturamento, Contas a receber, Cruzamento, Despesas ou Folha.",
        target: :billing
      },
      {
        key: "comparativo_folha",
        name: "Comparativo da Folha",
        description: "Folha declarada versus faturada por cliente e competência.",
        entry: "Abre ao clicar num funcionário ou competência na Folha.",
        target: :payroll
      },
      {
        key: "fonte_original",
        name: "Fonte Original",
        description: "Linha exata na planilha original que deu origem a cada dado.",
        entry: "Abre ao clicar num link de origem em qualquer módulo.",
        target: :billing
      }
    ].freeze

    def index
      @reports = REPORTS
      # Os relatorios sao gerados a partir dos dados da empresa; hoje apenas a APPA possui base.
      @available = current_fiscal_auditor_company == "appa"
    end
  end
end
