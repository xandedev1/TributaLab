module FiscalAuditor
  # Agrega as despesas de uniformes e material de limpeza por empresa (cliente).
  # O código do cliente vem embutido na descrição (coluna "DESPESA/ CLIENTE") e é casado
  # contra os códigos conhecidos da folha. Linhas sem cliente vinculado (interno/matriz)
  # são agrupadas em "Sem empresa relacionada".
  class UniformsDashboard
    UNALLOCATED = "Sem empresa relacionada".freeze
    REFERENCE_PATTERN = /ref\.?\s*\d+/i
    CODE_PATTERN = /\d{2,4}/

    class << self
      def source_paths(company = "appa")
        Dir[CompanyPath.uniforms_glob(company)].sort
      end

      def records(company = "appa")
        source_paths(company).flat_map { |path| UniformsWorkbook.new(path).records }.freeze
      end
    end

    attr_reader :company

    def initialize(records: nil, client_names: nil, company: "appa")
      @records = records
      @client_names = client_names
      @company = company
    end

    def available?
      records.any?
    end

    def rows
      @rows ||= grouped.map do |code, entries|
        [ code, aggregate(entries).merge(client_code: code, client: client_names.fetch(code, code)) ]
      end.map(&:last).sort_by { |row| -row[:total] }.freeze
    end

    def unallocated
      @unallocated ||= aggregate(records.reject { |record| resolve_code(record.description) })
        .merge(client_code: nil, client: UNALLOCATED)
    end

    def totals
      @totals ||= begin
        cleaning = records.select { |record| record.category == "Limpeza" }.sum(&:amount)
        uniforms = records.select { |record| record.category == "Uniformes" }.sum(&:amount)
        allocated = rows.sum { |row| row[:total] }
        {
          cleaning: cleaning,
          uniforms: uniforms,
          total: cleaning + uniforms,
          allocated: allocated,
          unallocated: unallocated[:total]
        }
      end
    end

    def entries_for(code)
      grouped.fetch(code, []).sort_by { |record| [ record.category, -record.amount ] }
    end

    private

    def records
      @records ||= self.class.records(company)
    end

    def client_names
      @client_names ||= PayrollDashboard.records(company)
        .group_by(&:client_code)
        .transform_values { |group| group.group_by(&:client).max_by { |_, items| items.size }.first }
    end

    def known_codes
      @known_codes ||= client_names.keys.to_set
    end

    def grouped
      @grouped ||= records.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |record, memo|
        code = resolve_code(record.description)
        memo[code] << record if code
      end
    end

    def resolve_code(description)
      cleaned = description.to_s.gsub(REFERENCE_PATTERN, " ")
      cleaned.scan(CODE_PATTERN).find { |token| known_codes.include?(token) }
    end

    def aggregate(entries)
      cleaning = entries.select { |record| record.category == "Limpeza" }.sum(&:amount)
      uniforms = entries.select { |record| record.category == "Uniformes" }.sum(&:amount)
      { cleaning: cleaning, uniforms: uniforms, total: cleaning + uniforms, count: entries.size }
    end
  end
end
