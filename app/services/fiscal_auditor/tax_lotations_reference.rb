module FiscalAuditor
  class TaxLotationsReference
    Source = Struct.new(:key, :label, :filename, keyword_init: true)
    Section = Struct.new(:heading, :paragraphs, :tables, keyword_init: true)
    Table = Struct.new(:headers, :rows, keyword_init: true)

    SOURCES = [
      Source.new(key: "fgts", label: "Lotações FGTS", filename: "cod_lotacoes_fgts_2025-01.md"),
      Source.new(key: "contribuicoes", label: "Lotações tributárias", filename: "cod_lotacoes_tributarias_2025-01.md"),
      Source.new(key: "tabela_4_oficial", label: "Tabela 4 oficial", filename: "tabela_4_fpas_terceiros.md"),
      Source.new(key: "tabela_4_quarta", label: "Tabela 4 Quarta RH", filename: "tabela_4_quarta_fpas_terceiros.md")
    ].freeze

    attr_reader :source

    def initialize(source_key)
      @source = SOURCES.find { |item| item.key == source_key } || SOURCES.first
    end

    def sources
      SOURCES
    end

    def title
      lines.find { |line| line.start_with?("# ") }&.delete_prefix("# ") || source.label
    end

    def sections
      @sections ||= parse_sections
    end

    def source_path
      Rails.root.join("docs", "04_referencias", "MD modelos Banco de dado", source.filename)
    end

    private

    def lines
      @lines ||= source_path.read(encoding: "UTF-8").lines.map(&:chomp)
    end

    def parse_sections
      sections = []
      current = Section.new(heading: nil, paragraphs: [], tables: [])
      index = 1

      while index < lines.size
        line = lines[index]
        normalized_line = line.strip
        if normalized_line.match?(/^(##|###)\s+/)
          sections << current if current.heading || current.paragraphs.any? || current.tables.any?
          current = Section.new(heading: normalized_line.sub(/^(##|###)\s+/, ""), paragraphs: [], tables: [])
        elsif normalized_line.match?(/^\d+\.\s+/)
          sections << current if current.heading || current.paragraphs.any? || current.tables.any?
          current = Section.new(heading: normalized_line, paragraphs: [], tables: [])
        elsif markdown_table_header?(index)
          table, index = parse_table(index)
          current.tables << table
          next
        elsif normalized_line.present? && !normalized_line.start_with?("#")
          current.paragraphs << normalized_line.sub(/^[-*]\s+/, "")
        end
        index += 1
      end

      sections << current if current.heading || current.paragraphs.any? || current.tables.any?
      sections
    end

    def markdown_table_header?(index)
      lines[index].strip.start_with?("|") && lines[index + 1]&.strip&.match?(/^\|\s*:?-{3,}/)
    end

    def parse_table(index)
      headers = split_row(lines[index].strip)
      index += 2
      rows = []
      while index < lines.size && lines[index].strip.start_with?("|")
        rows << split_row(lines[index].strip)
        index += 1
      end
      [ Table.new(headers:, rows:), index ]
    end

    def split_row(line)
      line.split("|")[1..-2].map { |value| value.strip.delete("`") }
    end
  end
end