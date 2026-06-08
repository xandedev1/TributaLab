require "rexml/document"
require "zip"

module RubricasCte
	class NaturezaEsocialWorkbook
		DEFAULT_PATH = Rails.root.join("docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/natureza_esocial_por_rubrica_cte.xlsx")
		SOURCE_HASH = "0B1B647B44D083CFD161787E28FB53DB88E493D38A59A596F5678F063C0FC2B7".freeze
		HEADER_ROW = 5

		COLUMNS = {
			table_code: "A",
			cte_code: "B",
			description: "C",
			esocial_nature_code: "E",
			car: "F",
			tp: "G",
			cmp_inc: "H",
			seq: "I",
			fn: "J",
			fd: "K",
			fni: "L",
			fdi: "M",
			inm: "N",
			ind: "O",
			ina: "P",
			irr: "Q",
			irm: "R",
			irf: "S",
			ird: "T",
			ir: "U",
			ira: "V",
			pis: "W",
			pid: "X",
			ipm: "Y",
			ipd: "Z",
			ipf: "AA",
			rp: "AB",
			tr: "AC",
			rem: "AD",
			vinculo: "AE",
			inicio: "AF",
			fim: "AG"
		}.freeze

		Row = Struct.new(*COLUMNS.keys, :source_row, :source_sheet, :raw_values, keyword_init: true)

		def initialize(path = DEFAULT_PATH)
			@path = Pathname(path)
		end

		def rows
			@rows ||= parse_rows.freeze
		end

		private

		attr_reader :path

		def parse_rows
			Zip::File.open(path.to_s) do |zip|
				shared_strings = read_shared_strings(zip)
				document = read_xml(zip, "xl/worksheets/sheet1.xml")
				last_values = { table_code: nil, cte_code: nil, description: nil }

				worksheet_rows(document).filter_map do |row|
					row_number = row.attributes["r"].to_i
					next if row_number <= HEADER_ROW

					values = row_values(row, shared_strings)
					attributes = COLUMNS.transform_values { |column| clean(values[column]) }
					explicit_table_code = normalize_code(attributes[:table_code], width: 3)
					explicit_cte_code = normalize_code(attributes[:cte_code], width: 4)
					next if explicit_cte_code.present? && !explicit_cte_code.match?(/\A\d{4}\z/)

					attributes[:table_code] = explicit_table_code.match?(/\A\d{3}\z/) ? explicit_table_code : last_values[:table_code]
					attributes[:cte_code] = explicit_cte_code
					attributes[:esocial_nature_code] = normalize_code(attributes[:esocial_nature_code])
					next if attributes[:esocial_nature_code].present? && !attributes[:esocial_nature_code].match?(/\A\d+\z/)

					if attributes[:cte_code].present?
						last_values[:table_code] = attributes[:table_code] if attributes[:table_code].present?
						last_values[:cte_code] = attributes[:cte_code]
						last_values[:description] = attributes[:description] if attributes[:description].present?
					else
						attributes[:table_code] = last_values[:table_code]
						attributes[:cte_code] = last_values[:cte_code]
						attributes[:description] = attributes[:description].presence || last_values[:description]
					end

					next if attributes[:cte_code].blank? || attributes[:description].blank?

					Row.new(**attributes, source_row: row_number, source_sheet: "Plan1", raw_values: values.transform_values { |value| clean(value) })
				end
			end
		end

		def worksheet_rows(document)
			REXML::XPath.match(document, "//m:sheetData/m:row", namespace)
		end

		def row_values(row, shared_strings)
			values = {}

			REXML::XPath.each(row, "m:c", namespace) do |cell|
				column = cell.attributes["r"].to_s.gsub(/\d/, "")
				values[column] = cell_value(cell, shared_strings)
			end

			values
		end

		def cell_value(cell, shared_strings)
			value_node = REXML::XPath.first(cell, "m:v", namespace)
			inline_string = REXML::XPath.match(cell, ".//m:t", namespace).map(&:text).join

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
			REXML::XPath.match(document, "//m:si", namespace).map do |node|
				REXML::XPath.match(node, ".//m:t", namespace).map(&:text).join
			end
		end

		def read_xml(zip, entry_name)
			entry = zip.find_entry(entry_name)
			raise ArgumentError, "XLSX entry not found: #{entry_name}" unless entry

			REXML::Document.new(entry.get_input_stream.read)
		end

		def normalize_code(value, width: nil)
			code = clean(value).sub(/\.0\z/, "")
			return "" if code.blank?

			width && code.match?(/\A\d+\z/) ? code.rjust(width, "0") : code
		end

		def clean(value)
			value.to_s.gsub(/\s+/, " ").strip
		end

		def namespace
			{ "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }
		end
	end
end