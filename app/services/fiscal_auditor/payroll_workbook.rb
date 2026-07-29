require "date"
require "rexml/document"
require "zip"

module FiscalAuditor
  class PayrollWorkbook
    Record = Data.define(
      :source, :source_row, :company, :client_code, :client,
      :event_code, :event_description, :event_type, :competence, :amount
    )

    MONTH_COLUMNS = (5..16).freeze
    WORKBOOK_NAMESPACE = {
      "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
      "r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    }.freeze

    def initialize(path)
      @path = Pathname(path)
    end

    def records
      @records ||= parse.freeze
    end

    private

    attr_reader :path

    def parse
      Zip::File.open(path.to_s) do |zip|
        shared_strings = read_shared_strings(zip)
        document = read_xml(zip, first_sheet_entry(zip))
        rows = REXML::XPath.match(document, "//m:sheetData/m:row", WORKBOOK_NAMESPACE)

        rows.flat_map { |row| records_for(row, shared_strings) }
      end
    end

    def records_for(row, shared_strings)
      values = row_values(row, shared_strings)
      event_type = values[4].to_s.strip
      return [] unless %w[Vencimento Desconto].include?(event_type)

      client_code = identifier(values[0])
      client = values[1].to_s.strip
      return [] if client_code.blank? || client.blank?

      MONTH_COLUMNS.filter_map do |column|
        amount = decimal(values[column])
        next if amount.zero? && values[column].blank?

        Record.new(
          source: path.basename.to_s,
          source_row: row.attributes["r"].to_i,
          company: path.basename.to_s[/Empresa\s+(\d+)/i, 1],
          client_code: client_code,
          client: client,
          event_code: identifier(values[2]),
          event_description: values[3].to_s.strip,
          event_type: event_type,
          competence: Date.new(2025, column - 4, 1),
          amount: amount
        )
      end
    end

    def identifier(value)
      value.to_s.strip.sub(/\.0\z/, "").presence
    end

    def decimal(value)
      BigDecimal(value.to_s.tr(",", "."), exception: false) || 0.to_d
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

    def row_values(row, shared_strings)
      values = []
      REXML::XPath.each(row, "m:c", WORKBOOK_NAMESPACE) do |cell|
        index = column_index(cell.attributes["r"].to_s.gsub(/\d/, ""))
        values[index] = cell_value(cell, shared_strings)
      end
      values
    end

    def cell_value(cell, shared_strings)
      value = REXML::XPath.first(cell, "m:v", WORKBOOK_NAMESPACE)&.text.to_s
      inline = REXML::XPath.match(cell, ".//m:t", WORKBOOK_NAMESPACE).map(&:text).join

      case cell.attributes["t"]
      when "s" then shared_strings[value.to_i].to_s
      when "inlineStr", "str" then inline.presence || value
      else value
      end
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

    def column_index(name)
      name.chars.reduce(0) { |sum, character| (sum * 26) + character.ord - 64 } - 1
    end
  end
end
