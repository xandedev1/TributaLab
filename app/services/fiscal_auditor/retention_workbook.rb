require "date"
require "rexml/document"
require "zip"

module FiscalAuditor
  class RetentionWorkbook
    Record = Data.define(
      :source,
      :source_row,
      :cnpj,
      :client_code,
      :client,
      :rps,
      :invoice_number,
      :emission_date,
      :competence,
      :status,
      :billed,
      :inss,
      :irrf,
      :pis,
      :cofins,
      :csll,
      :iss,
      :net
    ) do
      def retained
        inss + irrf + pis + cofins + csll + iss
      end
    end

    HEADER_MATCHERS = {
      cnpj: /cnpj cliente/,
      client_code: /\A(?:(?:cod|cd) cliente|cleinte)\z/,
      client: /\Acliente\z/,
      rps: /\Arps\z/,
      invoice_number: /\An (?:nf e|nfe)\z/,
      emission_date: /dt emissao|data emissao/,
      competence: /competencia/,
      status: /status/,
      billed: /valor (?:da )?fatura/,
      inss: /valor inss/,
      irrf: /valor irrf/,
      pis: /valor pis/,
      cofins: /valor cofins/,
      csll: /valor csll/,
      iss: /valor iss/,
      net: /(?:valor|vl) liquido|liquido|valor final/
    }.freeze

    REQUIRED_HEADERS = %i[cnpj client emission_date competence billed inss irrf pis cofins csll iss net].freeze
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
        header_row, headers = locate_headers(rows, shared_strings)

        rows.drop_while { |row| row != header_row }.drop(1).filter_map do |row|
          build_record(row, headers, shared_strings)
        end
      end
    end

    def locate_headers(rows, shared_strings)
      rows.each_with_index do |row, row_index|
        values = row_values(row, shared_strings)
        headers = HEADER_MATCHERS.to_h do |name, matcher|
          [ name, values.index { |value| normalize(value).match?(matcher) } ]
        end.compact
        next unless REQUIRED_HEADERS.all? { |name| headers.key?(name) }

        headers[:client_code] ||= infer_client_code_index(rows.drop(row_index + 1), headers, shared_strings)
        return [ row, headers ]
      end

      raise ArgumentError, "Required fiscal headers not found in #{path.basename}"
    end

    def infer_client_code_index(rows, headers, shared_strings)
      candidates = (0...headers.fetch(:client)).to_a - [ headers.fetch(:cnpj) ]
      sample = rows.first(100).map { |row| row_values(row, shared_strings) }

      candidates.max_by do |index|
        sample.count { |values| values[index].to_s.strip.match?(/\A\d+(?:\.0)?\z/) }
      end
    end

    def build_record(row, headers, shared_strings)
      values = row_values(row, shared_strings)
      cnpj = value_at(values, headers, :cnpj)
      return unless cnpj.match?(/\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/)

      Record.new(
        source: path.basename.to_s,
        source_row: row.attributes["r"].to_i,
        cnpj: cnpj,
        client_code: identifier_at(values, headers, :client_code),
        client: value_at(values, headers, :client),
        rps: identifier_at(values, headers, :rps),
        invoice_number: identifier_at(values, headers, :invoice_number),
        emission_date: excel_date(value_at(values, headers, :emission_date)),
        competence: excel_date(value_at(values, headers, :competence))&.beginning_of_month,
        status: value_at(values, headers, :status),
        billed: decimal_at(values, headers, :billed),
        inss: decimal_at(values, headers, :inss),
        irrf: decimal_at(values, headers, :irrf),
        pis: decimal_at(values, headers, :pis),
        cofins: decimal_at(values, headers, :cofins),
        csll: decimal_at(values, headers, :csll),
        iss: decimal_at(values, headers, :iss),
        net: decimal_at(values, headers, :net)
      )
    end

    def value_at(values, headers, name)
      index = headers[name]
      return "" unless index

      values[index].to_s.strip
    end

    def decimal_at(values, headers, name)
      BigDecimal(value_at(values, headers, name).tr(",", "."), exception: false) || 0.to_d
    end

    def identifier_at(values, headers, name)
      value = value_at(values, headers, name)
      value.sub(/\.0\z/, "").presence
    end

    def excel_date(value)
      return if value.blank?

      serial = Float(value, exception: false)
      return Date.new(1899, 12, 30) + serial.to_i if serial

      Date.parse(value)
    rescue Date::Error
      nil
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

    def normalize(value)
      I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]+/, " ").strip
    end

    def column_index(name)
      name.chars.reduce(0) { |sum, character| (sum * 26) + character.ord - 64 } - 1
    end
  end
end
