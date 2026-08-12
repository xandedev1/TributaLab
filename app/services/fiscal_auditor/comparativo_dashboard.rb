require "json"

module FiscalAuditor
  class ComparativoDashboard
    EXTRACTOR_EFD = Rails.root.join("script/extract_efd_razao.py").freeze
    EXTRACTOR_PDF = Rails.root.join("script/extract_razao_pdf.py").freeze
    EFD_JSON = Rails.root.join("tmp/efd_razao.json").freeze
    RAZAO_SERVICOS_JSON = Rails.root.join("tmp/razao_servicos.json").freeze
    RAZAO_VENDAS_JSON = Rails.root.join("tmp/razao_vendas.json").freeze
    DEVOLUCAO_JSON = Rails.root.join("tmp/devolucao.json").freeze

    class << self
      def records(company = "solucoes")
        cache_key = "comparativo_#{company}"
        cached = instance_variable_get("@#{cache_key}")
        return cached if cached && !stale?(company, cache_key)

        data = load_records(company)
        instance_variable_set("@#{cache_key}", data)
        instance_variable_set("@#{cache_key}_sig", source_signature(company))
        data
      end

      private

      def stale?(company, cache_key)
        sig = instance_variable_get("@#{cache_key}_sig")
        !sig || sig != source_signature(company)
      end

      def source_signature(company)
        paths = [
          CompanyPath.efd_dir(company),
          CompanyPath.razao_servicos_pdf(company),
          CompanyPath.razao_vendas_pdf(company),
          CompanyPath.devolucao_pdf(company)
        ]
        paths.filter_map { |p| p.exist? ? [ p.mtime.to_i, p.size ] : nil }
      end

      def load_records(company)
        efd = load_efd
        razao_servicos = load_razao(RAZAO_SERVICOS_JSON)
        razao_vendas = load_razao(RAZAO_VENDAS_JSON)
        devolucao = load_devolucao

        {
          a100: efd[:a100],
          c100: efd[:c100],
          razao_servicos: razao_servicos,
          razao_vendas: razao_vendas,
          devolucao: devolucao
        }
      end

      def load_efd
        return { a100: [], c100: [] } unless EFD_JSON.exist?

        data = JSON.parse(File.read(EFD_JSON))
        {
          a100: (data["a100"] || []).map { |r| { num_nf: r["num_nf"], data_emissao: r["data_emissao"], valor: r["valor_nf"]&.to_d || 0.to_d } },
          c100: (data["c100"] || []).map { |r| { num_nf: r["num_nf"], data_emissao: r["data_emissao"], valor: r["valor_nf"]&.to_d || 0.to_d } }
        }
      end

      def load_razao(json_path)
        return [] unless json_path.exist?

        data = JSON.parse(File.read(json_path))
        (data["records"] || []).map do |r|
          { num_nf: r["num_nf"], data_emissao: r["data_emissao"], valor: r["credito"]&.to_d || 0.to_d }
        end
      end

      def load_devolucao
        return [] unless DEVOLUCAO_JSON.exist?

        data = JSON.parse(File.read(DEVOLUCAO_JSON))
        (data["records"] || []).map do |r|
          { num_nf: r["num_nf"], data_emissao: r["data_emissao"], valor: r["valor"]&.to_d || 0.to_d }
        end
      end
    end

    attr_reader :company

    def initialize(company: "solucoes")
      @company = company
    end

    def available?
      data = self.class.records(company)
      data[:a100].any? || data[:c100].any? || data[:razao_servicos].any? || data[:razao_vendas].any?
    end

    def monthly_comparison
      data = self.class.records(company)
      months = {}

      # Group by month
      (data[:a100] + data[:c100]).each do |r|
        month = r[:data_emissao]&.[](0..6)
        next unless month
        months[month] ||= { efd: 0.to_d, ecf: 0.to_d, devolucao: 0.to_d }
        months[month][:efd] += r[:valor]
      end

      (data[:razao_servicos] + data[:razao_vendas]).each do |r|
        month = r[:data_emissao]&.[](0..6)
        next unless month
        months[month] ||= { efd: 0.to_d, ecf: 0.to_d, devolucao: 0.to_d }
        months[month][:ecf] += r[:valor]
      end

      data[:devolucao].each do |r|
        month = r[:data_emissao]&.[](0..6)
        next unless month
        months[month] ||= { efd: 0.to_d, ecf: 0.to_d, devolucao: 0.to_d }
        months[month][:devolucao] += r[:valor]
      end

      # Calculate differences
      months.map do |month, values|
        faturamento_ecf = values[:ecf] - values[:devolucao]
        diferenca = faturamento_ecf - values[:efd]
        {
          month: month,
          efd: values[:efd],
          ecf: values[:ecf],
          devolucao: values[:devolucao],
          faturamento_ecf: faturamento_ecf,
          diferenca: diferenca
        }
      end.sort_by { |m| m[:month] }
    end

    def totals
      monthly = monthly_comparison
      {
        efd: monthly.sum { |m| m[:efd] },
        ecf: monthly.sum { |m| m[:ecf] },
        devolucao: monthly.sum { |m| m[:devolucao] },
        faturamento_ecf: monthly.sum { |m| m[:faturamento_ecf] },
        diferenca: monthly.sum { |m| m[:diferenca] }
      }
    end
  end
end
