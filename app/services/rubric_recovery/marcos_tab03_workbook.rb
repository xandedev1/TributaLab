require "rexml/document"
require "zip"

module RubricRecovery
	class MarcosTab03Workbook
		DEFAULT_PATH = Rails.root.join(
			"docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/tabela_eventos_rubricas_marcos_tab03_2026-06-01.xlsx"
		)
		SOURCE_HASH = "867D8E7B38D0968C94F9721D4202CBD089A3543D31594AE1817A541D71886BA4"

		EventRow = Struct.new(
			:source_row,
			:table_code,
			:event_code,
			:description,
			:car,
			:reg,
			:tp,
			:nt,
			:sl,
			:rub,
			:br,
			:fn,
			:fd,
			:fni,
			:fdi,
			:inm,
			:ind,
			:irm,
			:irf,
			:ird,
			:ir,
			keyword_init: true
		)

		NatureRow = Struct.new(
			:source_row,
			:nature_code,
			:name,
			:normalized_name,
			:valid_from,
			:valid_to,
			:description,
			:exclusive_employee_incidence,
			:cod_inc_cp,
			:cod_inc_irrf,
			:cod_inc_fgts,
			:suggested_cp,
			:suggested_irrf,
			:suggested_fgts,
			:reason_source,
			keyword_init: true
		)

		def initialize(path = DEFAULT_PATH)
			@path = Pathname(path)
		end

		def events
			@events ||= parse_events.freeze
		end

		def natures
			@natures ||= parse_natures.freeze
		end

		private

		attr_reader :path

		def parse_events
			Zip::File.open(path.to_s) do |zip|
				shared_strings = read_shared_strings(zip)
				document = read_xml(zip, "xl/worksheets/sheet1.xml")
				last_table_code = nil

				rows(document).filter_map do |row|
					row_number = row.attributes["r"].to_i
					next if row_number <= 4

					values = row_values(row, shared_strings)
					event_code = normalize_code(values["B"], width: 4)
					next unless event_code.match?(/\A\d{4}\z/)

					table_code = normalize_code(values["A"], width: 3).presence || last_table_code
					last_table_code = table_code if table_code.present?

					EventRow.new(
						source_row: row_number,
						table_code: table_code,
						event_code: event_code,
						description: clean(values["C"]),
						car: clean(values["E"]),
						reg: normalize_code(values["F"], width: 3),
						tp: clean(values["G"]),
						nt: clean(values["H"]),
						sl: clean(values["I"]),
						rub: normalize_code(values["J"], width: 3),
						br: clean(values["K"]),
						fn: clean(values["L"]),
						fd: clean(values["M"]),
						fni: clean(values["N"]),
						fdi: clean(values["O"]),
						inm: clean(values["P"]),
						ind: clean(values["Q"]),
						irm: clean(values["R"]),
						irf: clean(values["S"]),
						ird: clean(values["T"]),
						ir: clean(values["U"])
					)
				end
			end
		end

		def parse_natures
			Zip::File.open(path.to_s) do |zip|
				shared_strings = read_shared_strings(zip)
				document = read_xml(zip, "xl/worksheets/sheet2.xml")

				rows(document).filter_map do |row|
					row_number = row.attributes["r"].to_i
					next if row_number == 1

					values = row_values(row, shared_strings)
					nature_code = normalize_code(values["A"])
					name = clean(values["B"])
					next if nature_code.blank? || name.blank?

					NatureRow.new(
						source_row: row_number,
						nature_code: nature_code,
						name: name,
						normalized_name: clean(values["C"]),
						valid_from: clean(values["D"]),
						valid_to: clean(values["E"]),
						description: clean(values["F"]),
						exclusive_employee_incidence: clean(values["G"]),
						cod_inc_cp: normalize_code(values["I"]),
						cod_inc_irrf: normalize_code(values["J"]),
						cod_inc_fgts: normalize_code(values["K"]),
						suggested_cp: clean(values["L"]),
						suggested_irrf: clean(values["M"]),
						suggested_fgts: clean(values["N"]),
						reason_source: clean(values["O"])
					)
				end
			end
		end

		def rows(document)
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
			when "inlineStr"
				inline_string
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
			REXML::Document.new(zip.find_entry(entry_name).get_input_stream.read)
		end

		def namespace
			{ "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }
		end

		def normalize_code(value, width: nil)
			code = clean(value).sub(/\.0\z/, "")
			return "" if code.blank?

			width && code.match?(/\A\d+\z/) ? code.rjust(width, "0") : code
		end

		def clean(value)
			value.to_s.strip
		end
	end
end