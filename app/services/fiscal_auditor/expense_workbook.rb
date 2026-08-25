require "date"
require "json"
require "open3"

module FiscalAuditor
  class ExpenseWorkbook
    Record = Data.define(
      :source,
      :source_sheet,
      :source_row,
      :due_date,
      :payment_date,
      :party,
      :client,
      :document,
      :description,
      :identification,
      :competence_expense,
      :amount
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

      normalized_output = output.dup.force_encoding(Encoding::UTF_8)
      normalized_output = output.force_encoding(Encoding::Windows_1252).encode(Encoding::UTF_8, invalid: :replace, undef: :replace) unless normalized_output.valid_encoding?
      JSON.parse(normalized_output).map { |attributes| build_record(attributes) }
    end

    def build_record(attributes)
      values = attributes.symbolize_keys
      values[:source] = path.basename.to_s
      values[:amount] = values.fetch(:amount).to_d
      values[:due_date] = Date.iso8601(values[:due_date]) if values[:due_date].present?
      values[:payment_date] = Date.iso8601(values.fetch(:payment_date))
      Record.new(**values)
    end

    def extractor_path
      Rails.root.join("script/extract_payables_xlsb.py")
    end

    def python_executable
      configured = ENV["FISCAL_AUDITOR_PYTHON"]
      return configured if configured.present?

      candidates = [ Rails.root.join(".venv/Scripts/python.exe"), Rails.root.join(".venv/bin/python") ]
      candidates.find(&:exist?)&.to_s || "python"
    end
  end
end
