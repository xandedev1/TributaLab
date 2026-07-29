require "rexml/document"
require "zip"

module FiscalAuditor
  class PayrollChargesWorkbook
    InssEntry = Data.define(:code, :description, :period, :amount, :source, :source_row, :source_column)
    FgtsEntry = Data.define(:period, :kind, :amount, :source, :source_row, :source_column, :formula)

    WORKBOOK_NAMESPACE = {
      "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
      "r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    }.freeze
    MONTH_NAMES = {
      "JANEIRO" => 1, "FEVEREIRO" => 2, "MARCO" => 3, "ABRIL" => 4,
      "MAIO" => 5, "JUNHO" => 6, "JULHO" => 7, "AGOSTO" => 8,
      "SETEMBRO" => 9, "OUTUBRO" => 10, "NOVEMBRO" => 11, "DEZEMBRO" => 12
    }.freeze

    def initialize(path)
      @path = Pathname(path)
    end

    def inss_entries
      raise ArgumentError, "Planilha de INSS esperada" unless inss?

      rows = worksheet_rows
      (2..10).flat_map do |row_number|
        label = rows.dig(row_number, 1, :value).to_s.strip
        next [] if label.blank?

        code, description = label.split(" - ", 2)
        (2..14).filter_map do |column|
          amount = decimal(rows.dig(row_number, column, :value))
          next if amount.zero?

          InssEntry.new(
            code: code,
            description: description,
            period: column == 14 ? "2025-12" : format("2025-%02d", column - 1),
            amount: amount,
            source: path.basename.to_s,
            source_row: row_number,
            source_column: column_name(column)
          )
        end
      end
    end

    def fgts_entry
      raise ArgumentError, "Planilha de FGTS esperada" if inss?

      total_row, total_cell = worksheet_rows.filter_map do |row_number, columns|
        cell = columns[17]
        [ row_number, cell ] if cell&.fetch(:formula, nil).present? && decimal(cell[:value]).nonzero?
      end.last
      raise ArgumentError, "Totalizador de FGTS não localizado" unless total_cell

      FgtsEntry.new(
        period: fgts_period,
        kind: thirteenth? ? :thirteenth : :monthly,
        amount: decimal(total_cell[:value]),
        source: path.basename.to_s,
        source_row: total_row,
        source_column: "Q",
        formula: total_cell[:formula]
      )
    end

    private

    attr_reader :path

    def inss?
      path.basename.to_s.upcase.start_with?("INSS")
    end

    def thirteenth?
      path.basename.to_s.match?(/13\s*SALARIO/i)
    end

    def fgts_period
      return "2025-12" if thirteenth?

      normalized_name = I18n.transliterate(path.basename.to_s).upcase
      month = MONTH_NAMES.find { |name, _| normalized_name.include?(name) }&.last
      raise ArgumentError, "Competência de FGTS não identificada" unless month

      format("2025-%02d", month)
    end

    def worksheet_rows
      @worksheet_rows ||= Zip::File.open(path.to_s) do |zip|
        shared_strings = read_shared_strings(zip)
        document = read_xml(zip, first_sheet_entry(zip))
        REXML::XPath.match(document, "//m:sheetData/m:row", WORKBOOK_NAMESPACE).to_h do |row|
          row_number = row.attributes["r"].to_i
          columns = REXML::XPath.match(row, "m:c", WORKBOOK_NAMESPACE).to_h do |cell|
            column = column_index(cell.attributes["r"].to_s.gsub(/\d/, "")) + 1
            [ column, cell_payload(cell, shared_strings) ]
          end
          [ row_number, columns ]
        end
      end
    end

    def cell_payload(cell, shared_strings)
      raw_value = REXML::XPath.first(cell, "m:v", WORKBOOK_NAMESPACE)&.text.to_s
      inline = REXML::XPath.match(cell, ".//m:t", WORKBOOK_NAMESPACE).map(&:text).join
      value = case cell.attributes["t"]
      when "s" then shared_strings[raw_value.to_i].to_s
      when "inlineStr", "str" then inline.presence || raw_value
      else raw_value
      end
      { value: value, formula: REXML::XPath.first(cell, "m:f", WORKBOOK_NAMESPACE)&.text }
    end

    def first_sheet_entry(zip)
      workbook = read_xml(zip, "xl/workbook.xml")
      relationships = read_xml(zip, "xl/_rels/workbook.xml.rels")
      first_sheet = REXML::XPath.first(workbook, "//m:sheets/m:sheet", WORKBOOK_NAMESPACE)
      relationship = REXML::XPath.first(
        relationships,
        "//*[local-name()='Relationship'][@Id='#{first_sheet.attributes['r:id']}']"
      )
      target = relationship.attributes["Target"].sub(%r{\A/}, "")
      target.start_with?("xl/") ? target : "xl/#{target}"
    end

    def read_shared_strings(zip)
      entry = zip.find_entry("xl/sharedStrings.xml")
      return [] unless entry

      document = REXML::Document.new(entry.get_input_stream.read)
      REXML::XPath.match(document, "//m:si", WORKBOOK_NAMESPACE).map do |node|
        REXML::XPath.match(node, ".//m:t", WORKBOOK_NAMESPACE).map(&:text).join
      end
    end

    def read_xml(zip, entry_name)
      entry = zip.find_entry(entry_name)
      raise ArgumentError, "XLSX entry not found: #{entry_name}" unless entry

      REXML::Document.new(entry.get_input_stream.read)
    end

    def decimal(value)
      BigDecimal(value.to_s.tr(",", "."), exception: false) || 0.to_d
    end

    def column_index(name)
      name.chars.reduce(0) { |sum, character| (sum * 26) + character.ord - 64 } - 1
    end

    def column_name(number)
      name = +""
      while number.positive?
        number, remainder = (number - 1).divmod(26)
        name.prepend((65 + remainder).chr)
      end
      name
    end
  end
end
