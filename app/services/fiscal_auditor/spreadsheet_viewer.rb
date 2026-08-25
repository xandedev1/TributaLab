require "json"
require "open3"

module FiscalAuditor
  class SpreadsheetViewer
    PAGE_SIZE = 100
    SOURCE_PATHS = {
      "billing" => ->(company) { Dashboard.source_paths(company) },
      "receivables" => ->(company) { ReceivablesDashboard.source_paths(company) },
      "payables" => ->(company) { ExpensesDashboard.source_paths(company) },
      "payroll" => ->(company) { PayrollDashboard.source_paths(company) },
      "payroll_charges" => ->(company) { PayrollChargesDashboard.source_paths(company) }
    }.freeze
    DEFAULT_SHEETS = {
      "receivables" => "APPA"
    }.freeze

    Result = Data.define(
      :source_kind, :filename, :sheet, :sheets, :columns, :rows,
      :total_rows, :total_columns, :page, :total_pages, :highlighted_row
    )

    def initialize(source_kind:, filename:, row: nil, sheet: nil, page: nil, company: "appa")
      @source_kind = source_kind.to_s
      @filename = filename.to_s
      @highlighted_row = positive_integer(row)
      @requested_sheet = sheet.to_s.presence || DEFAULT_SHEETS[@source_kind]
      @requested_page = positive_integer(page)
      @company = company
    end

    def result
      @result ||= begin
        payload = extract
        Result.new(
          source_kind: source_kind,
          filename: payload.fetch("filename"),
          sheet: payload.fetch("sheet"),
          sheets: payload.fetch("sheets"),
          columns: column_names(payload.fetch("total_columns")),
          rows: payload.fetch("rows"),
          total_rows: payload.fetch("total_rows"),
          total_columns: payload.fetch("total_columns"),
          page: page,
          total_pages: [ (payload.fetch("total_rows").to_f / PAGE_SIZE).ceil, 1 ].max,
          highlighted_row: highlighted_row
        )
      end
    end

    private

    attr_reader :source_kind, :filename, :highlighted_row, :requested_sheet, :requested_page

    def extract
      output, error, status = Open3.capture3(
        python_executable,
        Rails.root.join("script/extract_spreadsheet_view.py").to_s,
        source_path.to_s,
        requested_sheet.to_s,
        first_row.to_s,
        PAGE_SIZE.to_s
      )
      raise ArgumentError, error.presence || "Não foi possível ler a planilha" unless status.success?

      JSON.parse(output.force_encoding(Encoding::UTF_8))
    rescue JSON::ParserError => error
      raise ArgumentError, error.message
    end

    def source_path
      paths = SOURCE_PATHS.fetch(source_kind) { raise ArgumentError, "Origem de planilha inválida" }.call(@company)
      paths.map { |path| Pathname(path) }.find { |path| path.basename.to_s == filename } ||
        raise(ArgumentError, "Planilha não autorizada")
    end

    def page
      @page ||= requested_page || (highlighted_row ? ((highlighted_row - 1) / PAGE_SIZE) + 1 : 1)
    end

    def first_row
      ((page - 1) * PAGE_SIZE) + 1
    end

    def positive_integer(value)
      integer = value.to_i
      integer if integer.positive?
    end

    def column_names(count)
      (1..count).map { |number| column_name(number) }
    end

    def column_name(number)
      name = +""
      while number.positive?
        number, remainder = (number - 1).divmod(26)
        name.prepend((65 + remainder).chr)
      end
      name
    end

    def python_executable
      configured = ENV["FISCAL_AUDITOR_PYTHON"]
      return configured if configured.present?

      candidates = [ Rails.root.join(".venv/Scripts/python.exe"), Rails.root.join(".venv/bin/python") ]
      candidates.find(&:exist?)&.to_s || "python"
    end
  end
end
