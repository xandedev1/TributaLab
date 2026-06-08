require "digest"
require "rexml/document"
require "zip"

module RubricasCte
	class S1010ZipImporter
		SOURCE_REPO_PATH = "docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/s1010_todos_os_anos_cte_2026_06_02.zip".freeze

		def self.call
			new.call
		end

		def call
			source_file = SourceFileRegistry.find_or_create!(
				kind: "s1010_historico_zip",
				repo_path: SOURCE_REPO_PATH,
				original_path: "C:/Users/xandao/Downloads/S1010 todos os anos CTE.zip",
				notes: "ZIP local com XMLs S-1010 em ZIPs mensais aninhados."
			)

			ActiveRecord::Base.transaction do
				source_file.s1010_timeline_segments.delete_all
				source_file.s1010_events.delete_all
				run = source_file.import_runs.create!(kind: "s1010_zip", started_at: Time.current)
				stats = { xmls: 0, nested_zips: 0, parse_errors: 0 }

				Zip::File.open(Rails.root.join(SOURCE_REPO_PATH).to_s) do |zip|
					zip.entries.each do |entry|
						next if entry.directory?

						if entry.name.downcase.end_with?(".zip")
							stats[:nested_zips] += 1
							parse_zip_buffer(entry.get_input_stream.read, entry.name, source_file, stats)
						elsif entry.name.downcase.end_with?(".xml")
							parse_xml(entry.get_input_stream.read, nil, entry.name, source_file, stats)
						end
					end
				end

				run.update!(
					status: "completed",
					finished_at: Time.current,
					rows_read: stats[:xmls],
					rows_written: source_file.s1010_events.count,
					stats: stats
				)
				source_file.update!(loaded_at: Time.current)
			end

			source_file
		end

		private

		def parse_zip_buffer(buffer, zip_path, source_file, stats)
			Zip::File.open_buffer(buffer) do |zip|
				zip.entries.each do |entry|
					next if entry.directory?

					if entry.name.downcase.end_with?(".zip")
						stats[:nested_zips] += 1
						parse_zip_buffer(entry.get_input_stream.read, "#{zip_path}/#{entry.name}", source_file, stats)
					elsif entry.name.downcase.end_with?(".xml")
						parse_xml(entry.get_input_stream.read, zip_path, entry.name, source_file, stats)
					end
				end
			end
		end

		def parse_xml(xml, nested_zip_path, xml_path, source_file, stats)
			stats[:xmls] += 1
			document = REXML::Document.new(xml)
			action_node = action_node(document)
			ide_node = descendant(action_node, "ideRubrica")
			dados_node = descendant(action_node, "dadosRubrica")
			raw_code = text(ide_node, "codRubr")

			S1010Event.create!(
				source_file: source_file,
				nested_zip_path: nested_zip_path,
				xml_path: xml_path,
				xml_sha256: Digest::SHA256.hexdigest(xml).upcase,
				event_action: action_node&.name,
				event_id: descendant(document, "evtTabRubrica")&.attributes&.[]("Id"),
				nr_recibo: text(document, "nrRecibo"),
				ide_tab_rubr: text(ide_node, "ideTabRubr"),
				cod_rubr_raw: raw_code,
				cod_rubr_normalized: normalize_rubric_code(raw_code),
				dsc_rubr: text(dados_node, "dscRubr"),
				normalized_description: RubricRecovery::TextNormalizer.normalize(text(dados_node, "dscRubr")),
				ini_valid: text(ide_node, "iniValid"),
				fim_valid: text(ide_node, "fimValid"),
				nat_rubr: text(dados_node, "natRubr"),
				tp_rubr: text(dados_node, "tpRubr"),
				cod_inc_cp: text(dados_node, "codIncCP"),
				cod_inc_irrf: text(dados_node, "codIncIRRF"),
				cod_inc_fgts: text(dados_node, "codIncFGTS"),
				observacao: text(dados_node, "observacao")
			)
		rescue StandardError
			stats[:parse_errors] += 1
		end

		def action_node(document)
			info = descendant(document, "infoRubrica")
			return nil unless info

			info.elements.find { |element| %w[inclusao alteracao exclusao].include?(element.name) }
		end

		def descendant(node, name)
			return nil unless node

			node.each_element do |element|
				return element if element.name == name

				found = descendant(element, name)
				return found if found
			end

			nil
		end

		def text(node, name)
			descendant(node, name)&.text.to_s.strip
		end

		def normalize_rubric_code(value)
			code = value.to_s.strip.upcase
			code.scan(/\d+/).last.to_s.rjust(4, "0")
		end
	end
end