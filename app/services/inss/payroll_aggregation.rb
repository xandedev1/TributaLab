module Inss
  # Agrega os lancamentos da folha por codigo/bloco aplicando filtros.
  # Usado pelo dashboard interativo.
  class PayrollAggregation
    Filters = Struct.new(:competencia, :contrato_codigo, :situacao_funcional, :busca, keyword_init: true)

    BlocoTotal = Struct.new(:bloco, :label, :valor, :referencia, :rows, keyword_init: true)
    CodeRow = Struct.new(:codigo, :historico, :valor, :referencia, :ocorrencias, keyword_init: true)

    def initialize(filters = {})
      @filters = Filters.new(**filters.symbolize_keys.slice(:competencia, :contrato_codigo, :situacao_funcional, :busca))
    end

    attr_reader :filters

    def employees_scope
      scope = PayrollEmployee.all
      scope = scope.for_competencia(@filters.competencia)
      scope = scope.for_contrato(@filters.contrato_codigo)
      scope = scope.for_situacao(@filters.situacao_funcional)
      scope = scope.search_nome(@filters.busca)
      scope
    end

    def entries_scope
      PayrollEntry.where(inss_payroll_employee_id: employees_scope.select(:id))
    end

    # Retorna [BlocoTotal, ...] na ordem dos blocos, cada um com uma linha por
    # codigo (soma de todos os lancamentos do codigo). O historico exibido e o
    # mais frequente entre as variacoes (quebras de linha geram variacoes).
    def by_bloco
      grouped = entries_scope
        .group(:bloco, :codigo, :historico)
        .pluck(:bloco, :codigo, :historico, Arel.sql("SUM(valor)"), Arel.sql("SUM(referencia)"), Arel.sql("COUNT(*)"))

      # Consolida por (bloco, codigo), somando as variacoes de historico.
      by_code = {}
      grouped.each do |bloco, codigo, historico, valor, referencia, ocorr|
        key = [bloco, codigo]
        agg = (by_code[key] ||= { valor: 0, referencia: 0, ocorrencias: 0, variacoes: Hash.new(0) })
        agg[:valor] += valor || 0
        agg[:referencia] += referencia || 0
        agg[:ocorrencias] += ocorr
        agg[:variacoes][historico.to_s] += ocorr
      end

      by_bloco = Hash.new { |h, k| h[k] = [] }
      by_code.each do |(bloco, codigo), agg|
        historico = agg[:variacoes].max_by { |texto, count| [count, texto.length] }&.first
        by_bloco[bloco] << CodeRow.new(
          codigo: codigo, historico: historico,
          valor: agg[:valor], referencia: agg[:referencia], ocorrencias: agg[:ocorrencias]
        )
      end
      by_bloco.each_value { |rows| rows.sort_by! { |r| -r.valor.to_f } }

      PayrollEntry::BLOCOS.map do |key, label|
        rows = by_bloco[key]
        BlocoTotal.new(
          bloco: key, label: label,
          valor: rows.sum { |r| r.valor },
          referencia: rows.sum { |r| r.referencia },
          rows: rows
        )
      end
    end

    def totals
      {
        funcionarios: employees_scope.count,
        proventos: entries_scope.where(bloco: "proventos").sum(:valor),
        descontos: entries_scope.where(bloco: "descontos").sum(:valor),
        encargos: entries_scope.where(bloco: "encargos").sum(:valor),
        liquido: entries_scope.where(bloco: "liquido").sum(:valor)
      }
    end

    # Soma dos principais codigos de INSS (apuracao).
    def inss_summary
      codes = {
        "3590" => "INSS Empresa",
        "3600" => "INSS - SAT/RAT",
        "3870" => "INSS - Terceiros",
        "3580" => "Liquido Guia INSS",
        "1160" => "INSS Descontado (Rescisao)",
        "1180" => "INSS 13o Descontado",
        "3190" => "Base INSS",
        "3211" => "Base INSS 13o"
      }
      sums = entries_scope.where(codigo: codes.keys).group(:codigo).sum(:valor)
      codes.map do |codigo, label|
        { codigo: codigo, label: label, valor: sums[codigo] || 0 }
      end
    end

    # Opcoes para os selects de filtro.
    def competencias
      PayrollEmployee.where.not(competencia: nil).distinct.order(:competencia).pluck(:competencia)
    end

    def contratos
      PayrollEmployee.where.not(contrato_codigo: nil)
        .distinct.order(:contrato_codigo)
        .pluck(:contrato_codigo, :contrato_nome)
    end

    def situacoes
      PayrollEmployee.where.not(situacao_funcional: nil).distinct.order(:situacao_funcional).pluck(:situacao_funcional)
    end

    def employees_list(limit: 100)
      employees_scope.ordered.limit(limit)
    end
  end
end
