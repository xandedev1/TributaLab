require "rexml/document"
require "zip"

module FiscalAuditor
  # Lê a planilha de despesas de uniformes e material de limpeza (2 abas: "limpeza" e "uniformes").
  # Cada linha traz, na coluna "DESPESA/ CLIENTE", o código do cliente embutido; o valor pago
  # está na coluna "PAGO". A resolução do código -> cliente fica no dashboard.
  class UniformsWorkbook
    Record = Data.define(:category, :description, :supplier, :amount, :source, :source_row, :sheet)

    SHEETS = { "limpeza" => "Limpeza", "uniformes" => "Uniformes" }.freeze
    WORKBOOK_NAMESPACE = {
      "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
      "r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    }.freeze

    def initialize(path)
      @path = Pathname(path)
    end

    def records
      SHEETS.flat_map do |sheet_name, category|
        rows = worksheet_rows(sheet_name)
        next [] if rows.empty?

        header = rows.min_by(&:first)&.last || {}
        columns = header_columns(header)
        next [] unless columns[:description] && columns[:amount]

        rows.sort_by(&:first).drop(1).filter_map do |row_number, cells|
          amount = decimal(cells.dig(columns[:amount], :value))
          description = cells.dig(columns[:description], :value).to_s.strip
          next if amount.zero? && description.blank?

          Record.new(
            category: category,
            description: description,
            supplier: cells.dig(columns[:supplier], :value).to_s.strip,
            amount: amount,
            source: path.basename.to_s,
            source_row: row_number,
            sheet: sheet_name
          )
        end
      end.freeze
    end

    private

    attr_reader :path

    def header_columns(header)
      mapping = {}
      header.each do |column, cell|
        label = I18n.transliterate(cell[:value].to_s).upcase.strip
        mapping[:description] ||= column if label.include?("DESPESA")
        mapping[:amount] ||= column if label == "PAGO"
        mapping[:supplier] ||= column if label.include?("FORNECEDOR")
      end
      mapping
    end

    def worksheet_rows(sheet_name)
      worksheets.fetch(sheet_name, {})
    end

    def worksheets
      @worksheets ||= Zip::File.open(path.to_s) do |zip|
        shared_strings = read_shared_strings(zip)
        sheet_targets(zip).transform_values do |target|
          document = read_xml(zip, target)
          REXML::XPath.match(document, "//m:sheetData/m:row", WORKBOOK_NAMESPACE).to_h do |row|
            row_number = row.attributes["r"].to_i
            cells = REXML::XPath.match(row, "m:c", WORKBOOK_NAMESPACE).to_h do |cell|
              column = column_index(cell.attributes["r"].to_s.gsub(/\d/, "")) + 1
              [ column, cell_payload(cell, shared_strings) ]
            end
            [ row_number, cells ]
          end
        end
      end
    end

    def sheet_targets(zip)
      workbook = read_xml(zip, "xl/workbook.xml")
      relationships = read_xml(zip, "xl/_rels/workbook.xml.rels")
      REXML::XPath.match(workbook, "//m:sheets/m:sheet", WORKBOOK_NAMESPACE).each_with_object({}) do |sheet, memo|
        name = sheet.attributes["name"].to_s.downcase
        next unless SHEETS.key?(name)

        relationship = REXML::XPath.first(
          relationships,
          "//*[local-name()='Relationship'][@Id='#{sheet.attributes['r:id']}']"
        )
        next unless relationship

        target = relationship.attributes["Target"].sub(%r{\A/}, "")
        memo[name] = target.start_with?("xl/") ? target : "xl/#{target}"
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
      { value: value }
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
  end
end
