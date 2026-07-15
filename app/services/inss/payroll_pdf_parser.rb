require "digest"

module Inss
  # Parser do relatorio "RESUMO MOVIMENTO MENSAL" (folha de pagamento).
  #
  # Estrategia: o pdf-reader (PDF::Reader::Page#text) reconstroi o texto em um
  # grid preservando as posicoes horizontais. As 3 colunas do relatorio
  # (Totais e Encargos | Proventos | Descontos) ficam lado a lado separadas por
  # espacos. Detectamos as faixas (bands) de cada coluna pelas posicoes dos
  # cabecalhos "Cod. Historico" e distribuimos cada linha visual na coluna certa.
  #
  # Ignora os totalizadores finais (Resumo Gerencial / Resumo Hierarquia /
  # Situacao Funcional dos Vinculos) para nao duplicar os valores.
  class PayrollPdfParser
    DECIMAL = /-?\d{1,3}(?:\.\d{3})*,\d{2}/
    CODE_HEADER = /C[oó]d\.?\s*Hist[oó]rico/i
    STOP_SECTIONS = /Resumo Gerencial|Resumo Hierarquia|Situa[cç][aã]o Funcional dos V[ií]nculos/i

    Result = Struct.new(:competencia, :empresa, :employees, keyword_init: true)

    EmployeeData = Struct.new(
      :matricula, :nome, :cargo, :situacao_funcional,
      :admissao, :rescisao, :salario,
      :competencia, :empresa, :orgao_codigo, :orgao_nome,
      :contrato_codigo, :contrato_nome,
      :total_proventos, :total_descontos, :liquido,
      :entries, keyword_init: true
    )

    def self.content_hash(bytes)
      Digest::SHA256.hexdigest(bytes)
    end

    def self.call(source)
      new(source).call
    end

    def initialize(source)
      @source = source
    end

    def call
      reader = PDF::Reader.new(@source)
      state = {
        competencia: nil, empresa: nil,
        orgao_codigo: nil, orgao_nome: nil,
        contrato_codigo: nil, contrato_nome: nil
      }
      employees = []
      stop = false

      reader.pages.each do |page|
        next if stop

        lines = page.text.to_s.split("\n").map { |l| l.rstrip }
        i = 0
        while i < lines.size
          line = lines[i]

          if line.match?(STOP_SECTIONS)
            stop = true
            break
          end

          update_header!(state, line)

          if (emp_match = match_employee_header(line))
            block, consumed = collect_employee_block(lines, i)
            emp = build_employee(state, emp_match, block)
            employees << emp if emp
            i += consumed
            next
          end

          i += 1
        end
      end

      Result.new(
        competencia: state[:competencia],
        empresa: state[:empresa],
        employees: employees
      )
    end

    private

    # --- Header / contexto -------------------------------------------------

    def update_header!(state, line)
      if (m = line.match(/Compet[eê]ncia:?\s*(\d{2}\/\d{4})/i))
        state[:competencia] = m[1]
      elsif state[:competencia].nil? && (m = line.match(/^\s*(\d{2}\/\d{4})\s*$/))
        # No relatorio "Competência:" e "05/2026" saem em linhas separadas.
        state[:competencia] = m[1]
      end
      if (m = line.match(/Empresa:\s*(.+)$/i))
        state[:empresa] = m[1].strip
      end
      # Contrato/subgrupo: "101311 - ... CONTRATO 113" ou "101463 - FERISTA"
      # (codigo de 6+ digitos, checado antes do orgao). Nome comeca com letra.
      if !line.match?(/Admiss|Situa|Total|Resumo/i) &&
         (m = line.match(/^\s*(\d{6,})\s*-\s*([A-Za-z\u00C0-\u00FF].*?)\s*$/))
        state[:contrato_codigo] = m[1]
        state[:contrato_nome] = m[2].strip
      # Orgao: "10146 - SEINFRA ..." (codigo de 4-5 digitos, linha centralizada)
      elsif !line.match?(/Admiss|Situa|Total|Resumo/i) &&
            (m = line.match(/^\s*(\d{4,5})\s*-\s*([A-Za-z\u00C0-\u00FF].*?)\s*$/))
        state[:orgao_codigo] = m[1]
        state[:orgao_nome] = m[2].strip
      end
    end

    # "948639 - ADRIANA DE CARVALHO ALVES Admissao Rescisao ENCARREGADO DE APOIO"
    # Matricula pode ter poucos digitos (ex: 995).
    def match_employee_header(line)
      line.match(/^\s*(\d{2,})\s*-\s*(.+?)\s+Admiss[a\u00e3]o\s+Rescis[a\u00e3]o\s+(.+?)\s*$/)
    end

    # Junta as linhas de um funcionario ate o proximo funcionario ou secao final.
    def collect_employee_block(lines, start)
      block = []
      j = start
      while j < lines.size
        line = lines[j]
        if j > start && (match_employee_header(line) || line.match?(STOP_SECTIONS))
          break
        end
        block << line
        j += 1
      end
      [block, j - start]
    end

    # --- Montagem do funcionario ------------------------------------------

    def build_employee(state, emp_match, block)
      matricula = emp_match[1]
      nome = emp_match[2].strip
      cargo = emp_match[3].strip

      situacao = admissao = rescisao = salario = nil
      block.each do |line|
        if (m = line.match(/Situa[cç][aã]o Funcional:\s*([^\d]+?)\s+(\d{2}\/\d{2}\/\d{4})\s+(\d{2}\/\d{2}\/\d{4})\s+Sal[aá]rio:?\s*([\d.,]+)/i))
          situacao = m[1].strip
          admissao = parse_date(m[2])
          rescisao = parse_date(m[3])
          salario = parse_decimal(m[4])
        elsif (m = line.match(/Situa[cç][aã]o Funcional:\s*([A-Za-zÀ-ú ]+)/i)) && situacao.nil?
          situacao = m[1].strip
        end
      end

      bands = detect_bands(block)
      entries = extract_entries(block, bands)
      totals = extract_totals(block)
      entries.concat(totals[:liquido_entries])

      # Totais calculados a partir dos lancamentos (a linha impressa "Total de
      # Proventos" as vezes tem o numero desalinhado no grid).
      total_proventos = entries.select { |e| e[:bloco] == "proventos" }.sum { |e| e[:valor] || 0 }
      total_descontos = entries.select { |e| e[:bloco] == "descontos" }.sum { |e| e[:valor] || 0 }
      liquido = totals[:liquido] || (total_proventos - total_descontos)

      EmployeeData.new(
        matricula: matricula, nome: nome, cargo: cargo,
        situacao_funcional: situacao,
        admissao: admissao, rescisao: rescisao, salario: salario,
        competencia: state[:competencia], empresa: state[:empresa],
        orgao_codigo: state[:orgao_codigo], orgao_nome: state[:orgao_nome],
        contrato_codigo: state[:contrato_codigo], contrato_nome: state[:contrato_nome],
        total_proventos: total_proventos, total_descontos: total_descontos,
        liquido: liquido,
        entries: entries
      )
    end

    # Detecta as 3 faixas de coluna pelas posicoes de "Cod. Historico".
    def detect_bands(block)
      header_line = block.find { |l| l.scan(CODE_HEADER).size >= 2 } ||
                    block.find { |l| l.match?(CODE_HEADER) }
      return nil unless header_line

      starts = []
      header_line.to_enum(:scan, CODE_HEADER).each { starts << Regexp.last_match.begin(0) }
      starts.uniq!
      return nil if starts.empty?

      # Se so achou 1 (colunas coladas), tenta pelos titulos dos blocos.
      if starts.size < 3
        title_line = block.find { |l| l.match?(/Totais e Encargos/i) && l.match?(/Proventos/i) }
        if title_line
          starts = []
          [/Totais e Encargos/i, /Proventos/i, /Descontos/i].each do |re|
            if (mm = title_line.match(re))
              starts << mm.begin(0)
            end
          end
          starts.sort!
        end
      end

      build_band_ranges(starts)
    end

    def build_band_ranges(starts)
      return nil if starts.empty?
      names = %w[encargos proventos descontos]
      ranges = {}
      starts.each_with_index do |s, idx|
        break if idx >= names.size
        finish = starts[idx + 1] ? starts[idx + 1] - 1 : Float::INFINITY
        ranges[names[idx]] = (s..finish)
      end
      ranges
    end

    def slice_band(line, range)
      return "" if range.nil?
      finish = range.end == Float::INFINITY ? line.length : [range.end, line.length].min
      start = [range.begin, line.length].min
      line[start..finish].to_s
    end

    # Extrai lancamentos de cada bloco lendo linha a linha dentro da faixa.
    def extract_entries(block, bands)
      return [] if bands.nil?

      # Recorta apenas a regiao da tabela (do cabecalho ate "Total de Proventos").
      header_idx = block.index { |l| l.match?(CODE_HEADER) } || 0
      end_idx = block.index { |l| l.match?(/Total de Proventos/i) } || block.size
      table = block[(header_idx + 1)...end_idx] || []

      entries = []
      bands.each do |bloco, range|
        current = nil
        table.each do |line|
          seg = slice_band(line, range).strip
          next if seg.empty?
          next if seg.match?(/^Cod|^C[oó]d/i)

          if (m = seg.match(/^(\d{1,9})\s+(.*)$/))
            current = start_entry(bloco, m[1], m[2])
            entries << current if current
          elsif current
            # linha de continuacao do historico: mantem so o texto, removendo
            # numeros/valores que possam vazar de colunas vizinhas.
            cont = seg.gsub(DECIMAL, " ").gsub(/\b\d+\b/, " ").squeeze(" ").strip
            current[:historico] = [current[:historico], cont].reject(&:blank?).join(" ") unless cont.empty?
          end
        end
      end
      entries
    end

    def start_entry(bloco, codigo, rest)
      decimals = rest.scan(DECIMAL)
      # Historico = texto antes do primeiro decimal (evita engolir ref/valor e
      # fragmentos que vazam de colunas vizinhas no grid).
      first_idx = rest =~ DECIMAL
      historico = (first_idx ? rest[0...first_idx] : rest).strip

      referencia = 0
      valor = 0
      if decimals.size >= 2
        referencia = parse_decimal(decimals[-2])
        valor = parse_decimal(decimals[-1])
      elsif decimals.size == 1
        valor = parse_decimal(decimals[-1])
      end

      { bloco: bloco, codigo: codigo, historico: historico, referencia: referencia, valor: valor }
    end

    def extract_totals(block)
      proventos = descontos = liquido = nil
      liquido_entries = []

      block.each do |line|
        if (m = line.match(/Total de Proventos\s+(#{DECIMAL}).*Total de Descontos\s+(#{DECIMAL})/i))
          proventos = parse_decimal(m[1])
          descontos = parse_decimal(m[2])
        elsif (m = line.match(/Total de Proventos\s+(#{DECIMAL})/i))
          proventos = parse_decimal(m[1])
        elsif (m = line.match(/Total de Descontos\s+(#{DECIMAL})/i))
          descontos = parse_decimal(m[1])
        end

        if (m = line.match(/(3050)\s+(Liquido[^\d]+?)\s+(#{DECIMAL})/i))
          liquido = parse_decimal(m[3])
          liquido_entries << {
            bloco: "liquido", codigo: m[1], historico: m[2].strip,
            referencia: 0, valor: liquido
          }
        end
      end

      { proventos: proventos, descontos: descontos, liquido: liquido, liquido_entries: liquido_entries }
    end

    # --- helpers -----------------------------------------------------------

    def parse_decimal(str)
      return nil if str.nil?
      BigDecimal(str.to_s.gsub(".", "").gsub(",", "."))
    rescue ArgumentError, TypeError
      nil
    end

    def parse_date(str)
      Date.strptime(str, "%d/%m/%Y")
    rescue ArgumentError, TypeError
      nil
    end
  end
end
