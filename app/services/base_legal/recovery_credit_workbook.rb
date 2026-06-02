require "rexml/document"
require "zip"

module BaseLegal
	class RecoveryCreditWorkbook
		DEFAULT_PATH = Rails.root.join("docs/04_referencias/pesquisa_original/base_legal/relatorio_recuperacao_credito.xlsx")

		Sheet = Struct.new(:name, :headers, :rows, :source_rows, keyword_init: true) do
			def row_count
				rows.size
			end
		end

		Row = Struct.new(:source_row, :values, keyword_init: true)

		def initialize(path = DEFAULT_PATH)
			@path = Pathname(path)
		end

		def sheets
			@sheets ||= parse_sheets.freeze
		end

		def sheet(name)
			sheets.find { |candidate| candidate.name == name } || sheets.first
		end

		private

		attr_reader :path

		def parse_sheets
			Zip::File.open(path.to_s) do |zip|
				shared_strings = read_shared_strings(zip)
				sheet_definitions(zip).map do |definition|
					parse_sheet(zip, definition, shared_strings)
				end
			end
		end

		def parse_sheet(zip, definition, shared_strings)
			document = read_xml(zip, definition[:entry])
			raw_rows = rows(document).map do |row|
				[source_row(row), row_values(row, shared_strings)]
			end

			header_index = raw_rows.index { |(_, values)| values.any?(&:present?) } || 0
			header_values = raw_rows[header_index]&.last || []
			width = [header_values.size, raw_rows.filter_map { |(_, values)| values.rindex(&:present?)&.+(1) }.max.to_i].max
			headers = normalize_headers(header_values, width)

			body_rows = raw_rows[(header_index + 1)..].to_a.filter_map do |row_number, values|
				cells = values.first(width).map { |value| clean(value) }
				next if cells.all?(&:blank?)

				Row.new(source_row: row_number, values: cells)
			end

			Sheet.new(
				name: definition[:name],
				headers: headers,
				rows: body_rows,
				source_rows: raw_rows.map(&:first)
			)
		end

		def sheet_definitions(zip)
			workbook = read_xml(zip, "xl/workbook.xml")
			rels = read_xml(zip, "xl/_rels/workbook.xml.rels")
			relationships = {}

			REXML::XPath.each(rels, "//r:Relationship", relationship_namespace) do |relationship|
				relationships[relationship.attributes["Id"]] = relationship.attributes["Target"]
			end

			REXML::XPath.match(workbook, "//m:sheets/m:sheet", workbook_namespace).map do |sheet|
				target = relationships.fetch(sheet.attributes["r:id"])
				{
					name: sheet.attributes["name"],
					entry: workbook_entry(target)
				}
			end
		end

		def workbook_entry(target)
			normalized = target.sub(%r{\A/}, "")
			normalized.start_with?("xl/") ? normalized : "xl/#{normalized}"
		end

		def rows(document)
			REXML::XPath.match(document, "//m:sheetData/m:row", workbook_namespace)
		end

		def source_row(row)
			row.attributes["r"].to_i
		end

		def row_values(row, shared_strings)
			values = []

			REXML::XPath.each(row, "m:c", workbook_namespace) do |cell|
				index = column_index(cell.attributes["r"].to_s.gsub(/\d/, ""))
				values[index] = cell_value(cell, shared_strings)
			end

			values.map { |value| clean(value) }
		end

		def cell_value(cell, shared_strings)
			value_node = REXML::XPath.first(cell, "m:v", workbook_namespace)
			inline_string = REXML::XPath.match(cell, ".//m:t", workbook_namespace).map(&:text).join

			case cell.attributes["t"]
			when "s"
				shared_strings[value_node.text.to_i].to_s
			when "inlineStr", "str"
				inline_string.presence || value_node&.text.to_s
			else
				value_node&.text.to_s
			end
		end

		def read_shared_strings(zip)
			entry = zip.find_entry("xl/sharedStrings.xml")
			return [] unless entry

			document = REXML::Document.new(entry.get_input_stream.read)
			REXML::XPath.match(document, "//m:si", workbook_namespace).map do |node|
				REXML::XPath.match(node, ".//m:t", workbook_namespace).map(&:text).join
			end
		end

		def read_xml(zip, entry_name)
			entry = zip.find_entry(entry_name)
			raise ArgumentError, "XLSX entry not found: #{entry_name}" unless entry

			REXML::Document.new(entry.get_input_stream.read)
		end

		def normalize_headers(values, width)
			Array.new(width) do |index|
				clean(values[index]).presence || "Coluna #{column_name(index)}"
			end
		end

		def column_index(name)
			name.chars.reduce(0) { |sum, character| (sum * 26) + character.ord - 64 } - 1
		end

		def column_name(index)
			name = +""
			number = index + 1

			while number.positive?
				number -= 1
				name.prepend((65 + (number % 26)).chr)
				number /= 26
			end

			name
		end

		def clean(value)
			value.to_s.gsub(/\s+/, " ").strip
		end

		def workbook_namespace
			{
				"m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
				"r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
			}
		end

		def relationship_namespace
			{ "r" => "http://schemas.openxmlformats.org/package/2006/relationships" }
		end
	end
end