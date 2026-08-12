require "json"

module FiscalAuditor
  class DevolucaoDashboard
    DevolucaoRecord = Data.define(:num_nf, :data_emissao, :valor, :source_file, :page)

    EXTRACTOR_PDF = Rails.root.join("script/extract_devolucao_pdf.py").freeze
    DEVOLUCAO_JSON = Rails.root.join("tmp/devolucao.json").freeze

    class << self
      def records(company = "solucoes")
        cache_key = "devolucao_#{company}"
        cached = instance_variable_get("@#{cache_key}")
        return cached if cached && !stale?(company, cache_key)

        data = load_records(company)
        instance_variable_set("@#{cache_key}", data)
        instance_variable_set("@#{cache_key}_sig", source_signature(company))
        data
      end

      def extract_if_needed(company)
        return unless any_source?(company) && stale?(company, "devolucao_#{company}")
        extract(company)
      end

      private

      def stale?(company, cache_key)
        sig = instance_variable_get("@#{cache_key}_sig")
        !sig || sig != source_signature(company)
      end

      def source_signature(company)
        path = CompanyPath.devolucao_pdf(company)
        path.exist? ? [ path.mtime.to_i, path.size ] : nil
      end

      def any_source?(company)
        CompanyPath.devolucao_pdf(company).exist?
      end

      def extract(company)
        python = ENV.fetch("PYTHON", Rails.root.join(".venv/Scripts/python.exe").to_s)
        pdf_path = CompanyPath.devolucao_pdf(company)
        system(python, EXTRACTOR_PDF.to_s, pdf_path.to_s, DEVOLUCAO_JSON.to_s, exception: true) if pdf_path.exist?
      end

      def load_records(company)
        return [] unless DEVOLUCAO_JSON.exist?

        data = JSON.parse(File.read(DEVOLUCAO_JSON))
        (data["records"] || []).map do |r|
          DevolucaoRecord.new(
            r["num_nf"],
            r["data_emissao"],
            r["valor"]&.to_d || 0.to_d,
            r["source_file"],
            r["page"]
          )
        end
      end
    end

    attr_reader :company

    def initialize(company: "solucoes")
      @company = company
    end

    def available?
      self.class.records(company).any?
    end

    def total_count
      self.class.records(company).size
    end

    def total_value
      self.class.records(company).sum(&:valor)
    end

    def available_months
      self.class.records(company).filter_map { |r| r.data_emissao&.[](0..6) }.uniq.sort
    end

    def filter_by_month(records, month)
      return records unless month.present?
      records.select { |r| r.data_emissao&.start_with?(month) }
    end

    def records(month: nil)
      filter_by_month(self.class.records(company), month)
    end
  end
end
