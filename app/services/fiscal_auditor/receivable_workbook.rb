require "date"
require "json"
require "open3"

module FiscalAuditor
  class ReceivableWorkbook
    Record = Data.define(
      :source,
      :source_row,
      :client_code,
      :client,
      :cost_center,
      :invoice_number,
      :rps,
      :emission_date,
      :bank,
      :competence,
      :competence_text,
      :status,
      :gross,
      :contingency,
      :outstanding,
      :reconciliation_status,
      :paid,
      :payment_date
    )

    def initialize(path)
      @path = Pathname(path)
    end

    def records
      @records ||= parse.freeze
    end

    private

    attr_reader :path

    def parse
      output, error, status = Open3.capture3(python_executable, extractor_path.to_s, path.to_s)
      raise ArgumentError, "Could not read #{path.basename}: #{error.presence || output}" unless status.success?

      normalized_output = output.force_encoding(Encoding::Windows_1252).encode(Encoding::UTF_8)
      JSON.parse(normalized_output).map { |attributes| build_record(attributes) }
    end

    def build_record(attributes)
      values = attributes.symbolize_keys
      %i[gross contingency outstanding paid].each { |field| values[field] = values.fetch(field).to_d }
      values[:source] = path.basename.to_s
      values[:emission_date] = Date.iso8601(values.fetch(:emission_date))
      values[:competence] = Date.iso8601(values[:competence]) if values[:competence].present?
      values[:payment_date] = Date.iso8601(values[:payment_date]) if values[:payment_date].present?
      Record.new(**values)
    end

    def extractor_path
      Rails.root.join("script/extract_receivables_xlsb.py")
    end

    def python_executable
      configured = ENV["FISCAL_AUDITOR_PYTHON"]
      return configured if configured.present?

      candidates = [
        Rails.root.join(".venv/Scripts/python.exe"),
        Rails.root.join(".venv/bin/python")
      ]
      candidates.find(&:exist?)&.to_s || "python"
    end
  end
end
