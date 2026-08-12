require "json"

module FiscalAuditor
  class EfdRazaoDashboard
    # Record from EFD (TXT) - A100 (Serviços) or C100 (Vendas)
    EfdRecord = Data.define(:codigo, :num_nf, :data_emissao, :valor_nf, :source_file, :page)

    # Record from Razão (PDF)
    RazaoRecord = Data.define(:num_nf, :data_emissao, :credito, :source_file, :page)

    # Cross-referenced record (TXT → PDF or PDF → TXT)
    CrossRecord = Data.define(
      :codigo,
      :num_nf,
      :data_emissao_txt,
      :valor_nf,
      :data_emissao_pdf,
      :credito,
      :diferenca,
      :matched,
      :source_txt,
      :source_pdf,
      :page_txt,
      :page_pdf
    ) do
      def matched?
        matched
      end
    end

    EXTRACTOR_EFD = Rails.root.join("script/extract_efd_razao.py").freeze
    EXTRACTOR_PDF = Rails.root.join("script/extract_razao_pdf.py").freeze
    EFD_JSON = Rails.root.join("tmp/efd_razao.json").freeze
    RAZAO_SERVICOS_JSON = Rails.root.join("tmp/razao_servicos.json").freeze
    RAZAO_VENDAS_JSON = Rails.root.join("tmp/razao_vendas.json").freeze

    class << self
      def records(company = "solucoes")
        cache_key = "efd_razao_#{company}"
        cached = instance_variable_get("@#{cache_key}")
        return cached if cached && !stale?(company, cache_key)

        # Load from cached JSON files (never block on extraction)
        data = load_records(company)
        instance_variable_set("@#{cache_key}", data)
        instance_variable_set("@#{cache_key}_sig", source_signature(company))
        data
      end

      def extract_if_needed(company)
        return unless any_source?(company) && stale?(company, "efd_razao_#{company}")
        extract(company)
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
          CompanyPath.razao_vendas_pdf(company)
        ]
        paths.filter_map { |p| p.exist? ? [ p.mtime.to_i, p.size ] : nil }
      end

      def any_source?(company)
        CompanyPath.efd_dir(company).exist? ||
          CompanyPath.razao_servicos_pdf(company).exist? ||
          CompanyPath.razao_vendas_pdf(company).exist?
      end

      def extract(company)
        python = ENV.fetch("PYTHON", Rails.root.join(".venv/Scripts/python.exe").to_s)
        efd_dir = CompanyPath.efd_dir(company)

        if efd_dir.exist?
          system(python, EXTRACTOR_EFD.to_s, efd_dir.to_s, EFD_JSON.to_s, exception: true)
        end

        servicos_pdf = CompanyPath.razao_servicos_pdf(company)
        system(python, EXTRACTOR_PDF.to_s, servicos_pdf.to_s, RAZAO_SERVICOS_JSON.to_s, exception: true) if servicos_pdf.exist?

        vendas_pdf = CompanyPath.razao_vendas_pdf(company)
        system(python, EXTRACTOR_PDF.to_s, vendas_pdf.to_s, RAZAO_VENDAS_JSON.to_s, exception: true) if vendas_pdf.exist?
      end

      def load_records(company)
        efd = load_efd
        razao_servicos = load_razao(RAZAO_SERVICOS_JSON)
        razao_vendas = load_razao(RAZAO_VENDAS_JSON)

        {
          a100: efd[:a100],
          c100: efd[:c100],
          razao_servicos: razao_servicos,
          razao_vendas: razao_vendas
        }
      end

      def load_efd
        return { a100: [], c100: [] } unless EFD_JSON.exist?

        data = JSON.parse(File.read(EFD_JSON))
        {
          a100: (data["a100"] || []).map { |r| EfdRecord.new(r["codigo"], r["num_nf"], r["data_emissao"], r["valor_nf"]&.to_d || 0.to_d, r["source_file"], r["page"]) },
          c100: (data["c100"] || []).map { |r| EfdRecord.new(r["codigo"], r["num_nf"], r["data_emissao"], r["valor_nf"]&.to_d || 0.to_d, r["source_file"], r["page"]) }
        }
      end

      def load_razao(json_path)
        return [] unless json_path.exist?

        data = JSON.parse(File.read(json_path))
        (data["records"] || []).map do |r|
          RazaoRecord.new(r["num_nf"], r["data_emissao"], r["credito"]&.to_d || 0.to_d, r["source_file"], r["page"])
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

    def efd_a100_count
      self.class.records(company)[:a100].size
    end

    def efd_c100_count
      self.class.records(company)[:c100].size
    end

    def razao_servicos_count
      self.class.records(company)[:razao_servicos].size
    end

    def razao_vendas_count
      self.class.records(company)[:razao_vendas].size
    end

    def efd_a100_total
      self.class.records(company)[:a100].sum(&:valor_nf)
    end

    def efd_c100_total
      self.class.records(company)[:c100].sum(&:valor_nf)
    end

    def razao_servicos_total
      self.class.records(company)[:razao_servicos].sum(&:credito)
    end

    def razao_vendas_total
      self.class.records(company)[:razao_vendas].sum(&:credito)
    end

    def efd_total
      efd_a100_total + efd_c100_total
    end

    def razao_total
      razao_servicos_total + razao_vendas_total
    end

    def diferenca_total
      razao_total - efd_total
    end

    def available_months
      data = self.class.records(company)
      months = []
      data[:a100].each { |r| months << r.data_emissao[0..6] if r.data_emissao }
      data[:c100].each { |r| months << r.data_emissao[0..6] if r.data_emissao }
      data[:razao_servicos].each { |r| months << r.data_emissao[0..6] if r.data_emissao }
      data[:razao_vendas].each { |r| months << r.data_emissao[0..6] if r.data_emissao }
      months.uniq.sort
    end

    def filter_by_month(records, month)
      return records unless month.present?
      records.select { |r| r.data_emissao&.start_with?(month) }
    end

    # Relatório 1: A100 TXT → PDF (EFD como base, cruzar com Razão Serviços)
    def report_a100_txt_to_pdf(month: nil)
      data = self.class.records(company)
      efd_records = filter_by_month(data[:a100], month)
      razao_records = filter_by_month(data[:razao_servicos], month)
      cross(efd_records, razao_records, :txt_to_pdf)
    end

    # Relatório 2: A100 PDF → TXT (Razão como base, cruzar com EFD)
    def report_a100_pdf_to_txt(month: nil)
      data = self.class.records(company)
      efd_records = filter_by_month(data[:a100], month)
      razao_records = filter_by_month(data[:razao_servicos], month)
      cross(razao_records, efd_records, :pdf_to_txt)
    end

    # Relatório 3: C100 TXT → PDF (EFD como base, cruzar com Razão Vendas)
    def report_c100_txt_to_pdf(month: nil)
      data = self.class.records(company)
      efd_records = filter_by_month(data[:c100], month)
      razao_records = filter_by_month(data[:razao_vendas], month)
      cross(efd_records, razao_records, :txt_to_pdf)
    end

    # Relatório 4: C100 PDF → TXT (Razão como base, cruzar com EFD)
    def report_c100_pdf_to_txt(month: nil)
      data = self.class.records(company)
      efd_records = filter_by_month(data[:c100], month)
      razao_records = filter_by_month(data[:razao_vendas], month)
      cross(razao_records, efd_records, :pdf_to_txt)
    end

    private

    def cross(base_records, match_records, direction)
      # Build lookup by NF number (5 digits)
      match_by_nf = match_records.each_with_object({}) do |r, h|
        h[r.num_nf] ||= []
        h[r.num_nf] << r
      end

      base_records.map do |base|
        matches = match_by_nf[base.num_nf]

        if matches&.any?
          match = matches.first
          case direction
          when :txt_to_pdf
            # base=EfdRecord, match=RazaoRecord
            diferenca = base.valor_nf - match.credito
            CrossRecord.new(
              codigo: base.codigo,
              num_nf: base.num_nf,
              data_emissao_txt: base.data_emissao,
              valor_nf: base.valor_nf,
              data_emissao_pdf: match.data_emissao,
              credito: match.credito,
              diferenca: diferenca,
              matched: true,
              source_txt: base.source_file,
              source_pdf: match.source_file,
              page_txt: base.page,
              page_pdf: match.page
            )
          when :pdf_to_txt
            # base=RazaoRecord, match=EfdRecord
            diferenca = base.credito - match.valor_nf
            CrossRecord.new(
              codigo: match.codigo,
              num_nf: base.num_nf,
              data_emissao_txt: match.data_emissao,
              valor_nf: match.valor_nf,
              data_emissao_pdf: base.data_emissao,
              credito: base.credito,
              diferenca: diferenca,
              matched: true,
              source_txt: match.source_file,
              source_pdf: base.source_file,
              page_txt: match.page,
              page_pdf: base.page
            )
          end
        else
          case direction
          when :txt_to_pdf
            CrossRecord.new(
              codigo: base.codigo,
              num_nf: base.num_nf,
              data_emissao_txt: base.data_emissao,
              valor_nf: base.valor_nf,
              data_emissao_pdf: nil,
              credito: 0.to_d,
              diferenca: base.valor_nf,
              matched: false,
              source_txt: base.source_file,
              source_pdf: nil,
              page_txt: base.page,
              page_pdf: nil
            )
          when :pdf_to_txt
            CrossRecord.new(
              codigo: nil,
              num_nf: base.num_nf,
              data_emissao_txt: nil,
              valor_nf: 0.to_d,
              data_emissao_pdf: base.data_emissao,
              credito: base.credito,
              diferenca: base.credito,
              matched: false,
              source_txt: nil,
              source_pdf: base.source_file,
              page_txt: nil,
              page_pdf: base.page
            )
          end
        end
      end
    end
  end
end
