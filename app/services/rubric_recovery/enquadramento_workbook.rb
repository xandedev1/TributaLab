require "bigdecimal"
require "rexml/document"
require "zip"

module RubricRecovery
	class EnquadramentoWorkbook
		DEFAULT_PATH = Rails.root.join(
			"docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquivo_enquadrado_2026-05-29.xlsx"
		)

		Record = Struct.new(
			:code,
			:description,
			:source_type,
			:esocial_type,
			:nature_code,
			:nature_name,
			:cte_cp,
			:expected_cp,
			:validation_cp,
			:cte_irrf,
			:expected_irrf,
			:validation_irrf,
			:cte_fgts,
			:expected_fgts,
			:validation_fgts,
			:score,
			:confidence,
			:group,
			:incompatible_type,
			keyword_init: true
		) do
			def divergent?
				[cp_status, irrf_status, fgts_status].include?("Divergente")
			end

			def cp_status
				status_from(validation_cp)
			end

			def irrf_status
				status_from(validation_irrf)
			end

			def fgts_status
				status_from(validation_fgts)
			end

			def conflict_pattern
				patterns = []
				patterns << "CP" if cp_status == "Divergente"
				patterns << "IRRF" if irrf_status == "Divergente"
				patterns << "FGTS" if fgts_status == "Divergente"
				patterns.empty? ? "SEM_DIVERGENCIA" : patterns.join("+")
			end

			def normalized_group
				group.to_s.strip.presence || "SEM_GRUPO"
			end

			def group_label
				return "Sem grupo informado" if normalized_group == "SEM_GRUPO"

				normalized_group.tr("_", " ").downcase.capitalize
			end

			def esocial_nature
				"#{nature_code} - #{nature_name}"
			end

			def formatted_score
				format("%.4f", score.to_f)
			end

			def evidence_pending
				["S-1010", "EB/base legal", "Folha", "Recolhimento", "Parecer"]
			end

			def to_radar_row
				{
					code: code,
					description: description,
					group: normalized_group,
					group_label: group_label,
					esocial_nature: esocial_nature,
					confidence: confidence,
					score: formatted_score,
					cp_status: cp_status,
					irrf_status: irrf_status,
					fgts_status: fgts_status,
					conflict_pattern: conflict_pattern,
					evidence_pending: evidence_pending
				}
			end

			private

			def status_from(value)
				value.to_s.strip.casecmp("FALSO").zero? ? "Divergente" : "OK"
			end
		end

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
				sheet = read_xml(zip, "xl/worksheets/sheet1.xml")
				namespace = { "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }
				rows = REXML::XPath.match(sheet, "//m:sheetData/m:row", namespace)
				headers = row_values(rows.shift, shared_strings, namespace)

				rows.filter_map do |row|
					values = row_values(row, shared_strings, namespace)
					attributes = headers.each_with_object({}) do |(column, header), hash|
						hash[header] = values[column].to_s.strip
					end
					next if attributes["Plan1.Código"].blank?

					build_record(attributes)
				end
			end
		end

		def build_record(attributes)
			Record.new(
				code: attributes["Plan1.Código"],
				description: attributes["Plan1.Descrição"],
				source_type: attributes["Plan1.Tipo RB"],
				esocial_type: attributes["tab03.Tipo RB"],
				nature_code: attributes["tab03.Codigo"],
				nature_name: attributes["tab03.Nome"],
				cte_cp: attributes["Plan1.InM"],
				expected_cp: attributes["tab03.codIncCP"],
				validation_cp: attributes["Validação CP"],
				cte_irrf: attributes["Plan1.IrM"],
				expected_irrf: attributes["tab03.codIncIRRF"],
				validation_irrf: attributes["Validação IRRF"],
				cte_fgts: attributes["Plan1.FN"],
				expected_fgts: attributes["tab03.codIncFGTS"],
				validation_fgts: attributes["Validação FGTS"],
				score: BigDecimal(attributes["score_match"].presence || "0"),
				confidence: attributes["confianca"],
				group: attributes["grupo_evento"],
				incompatible_type: attributes["incompativel_tipo"] == "1"
			)
		end

		def row_values(row, shared_strings, namespace)
			values = {}

			REXML::XPath.each(row, "m:c", namespace) do |cell|
				column = cell.attributes["r"].to_s.gsub(/\d/, "")
				values[column] = cell_value(cell, shared_strings, namespace)
			end

			values
		end

		def cell_value(cell, shared_strings, namespace)
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
			namespace = { "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }

			REXML::XPath.match(document, "//m:si", namespace).map do |node|
				REXML::XPath.match(node, ".//m:t", namespace).map(&:text).join
			end
		end

		def read_xml(zip, entry_name)
			REXML::Document.new(zip.find_entry(entry_name).get_input_stream.read)
		end
	end
end