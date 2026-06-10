require "csv"
require "date"
require "digest"
require "fileutils"
require "find"
require "json"
require "pathname"
require "rexml/document"
require "time"
require "zip"

module Esocial
	class EstabelecimentosObrasExtractor
		IGNORED_DIRECTORY_NAMES = %w[.git node_modules .venv vendor tmp log storage].freeze
		ACTIONS = %w[inclusao alteracao exclusao].freeze
		OUTPUT_COLUMNS = %w[
			empresa_tp_insc
			empresa_nr_insc
			estabelecimento_tp_insc
			estabelecimento_nr_insc
			ini_valid
			fim_valid
			vigente_em
			registro_atual
			acao_evento
			cnae_preponderante
			aliquota_gilrat
			aliquota_fap
			aliquota_rat_ajustada
			data_recepcao
			nr_recibo
			event_id
			xml_sha256
			source_path
			nested_zip_path
			xml_path
		].freeze

		Row = Struct.new(*OUTPUT_COLUMNS.map(&:to_sym), keyword_init: true) do
			def to_h
				EstabelecimentosObrasExtractor::OUTPUT_COLUMNS.to_h { |column| [ column, public_send(column) ] }
			end

			def estabelecimento_chave
				[estabelecimento_tp_insc, estabelecimento_nr_insc].join("|")
			end
		end

		Result = Struct.new(:rows, :current_rows, :stats, :output_paths, keyword_init: true)

		def self.call(source_paths:, output_dir: nil, current_on: Date.today)
			new(source_paths: source_paths, output_dir: output_dir, current_on: current_on).call
		end

		def initialize(source_paths:, output_dir: nil, current_on: Date.today)
			@source_paths = Array(source_paths).map { |source_path| Pathname.new(source_path.to_s) }
			@output_dir = output_dir ? Pathname.new(output_dir.to_s) : nil
			@current_month = normalize_month(current_on)
			@rows = []
			@errors = []
			@stats = {
				sources: 0,
				missing_sources: 0,
				zip_files: 0,
				nested_zips: 0,
				xml_files: 0,
				s1005_events: 0,
				parse_errors: 0,
				skipped_files: 0
			}
		end

		def call
			@source_paths.each { |source_path| scan_source(source_path) }
			@rows.sort_by! { |row| [ row.estabelecimento_chave, row.ini_valid.to_s, row.event_id.to_s ] }

			current_rows = build_current_rows
			output_paths = write_outputs(current_rows) if @output_dir

			Result.new(rows: @rows, current_rows: current_rows, stats: stats, output_paths: output_paths || {})
		end

		private

		def stats
			@stats.merge(errors: @errors)
		end

		def scan_source(source_path)
			unless source_path.exist?
				@stats[:missing_sources] += 1
				record_error(source_path.to_s, nil, "Fonte nao encontrada")
				return
			end

			@stats[:sources] += 1

			if source_path.directory?
				scan_directory(source_path)
			else
				scan_file(source_path)
			end
		end

		def scan_directory(directory_path)
			Find.find(directory_path.to_s) do |candidate|
				path = Pathname.new(candidate)

				if path.directory?
					Find.prune if path != directory_path && IGNORED_DIRECTORY_NAMES.include?(path.basename.to_s)
					next
				end

				scan_file(path)
			end
		end

		def scan_file(file_path)
			case file_path.extname.downcase
			when ".xml"
				parse_xml(File.binread(file_path), source_path: file_path.to_s, nested_zip_path: nil, xml_path: file_path.basename.to_s)
			when ".zip"
				parse_zip_file(file_path)
			else
				@stats[:skipped_files] += 1
			end
		rescue StandardError => error
			record_error(file_path.to_s, nil, error.message)
		end

		def parse_zip_file(file_path)
			@stats[:zip_files] += 1

			Zip::File.open(file_path.to_s) do |zip|
				zip.entries.each do |entry|
					parse_zip_entry(entry, source_path: file_path.to_s, parent_zip_path: nil)
				end
			end
		rescue StandardError => error
			record_error(file_path.to_s, nil, error.message)
		end

		def parse_zip_buffer(buffer, source_path:, parent_zip_path:)
			Zip::File.open_buffer(buffer) do |zip|
				zip.entries.each do |entry|
					parse_zip_entry(entry, source_path: source_path, parent_zip_path: parent_zip_path)
				end
			end
		rescue StandardError => error
			record_error(source_path, parent_zip_path, error.message)
		end

		def parse_zip_entry(entry, source_path:, parent_zip_path:)
			return if entry.directory?

			entry_path = [ parent_zip_path, entry.name ].compact.join("/")

			if entry.name.downcase.end_with?(".zip")
				@stats[:nested_zips] += 1
				parse_zip_buffer(read_zip_entry(entry), source_path: source_path, parent_zip_path: entry_path)
			elsif entry.name.downcase.end_with?(".xml")
				parse_xml(read_zip_entry(entry), source_path: source_path, nested_zip_path: parent_zip_path, xml_path: entry_path)
			else
				@stats[:skipped_files] += 1
			end
		end

		def read_zip_entry(entry)
			stream = entry.get_input_stream
			stream.read
		ensure
			stream&.close
		end

		def parse_xml(xml, source_path:, nested_zip_path:, xml_path:)
			@stats[:xml_files] += 1
			return unless xml.include?("evtTabEstab")

			document = REXML::Document.new(xml)
			event_node = descendant(document, "evtTabEstab")
			return unless event_node

			action_node = estabelecimento_action_node(document)
			ide_empregador_node = descendant(event_node, "ideEmpregador")
			ide_estab_node = descendant(action_node, "ideEstab")
			dados_estab_node = descendant(action_node, "dadosEstab")
			tp_insc = text(ide_estab_node, "tpInsc")
			nr_insc = text(ide_estab_node, "nrInsc")
			return if tp_insc.empty? && nr_insc.empty?

			acao_evento = action_node&.name.to_s
			ini_valid = text(ide_estab_node, "iniValid")
			fim_valid = text(ide_estab_node, "fimValid")

			@rows << Row.new(
				empresa_tp_insc: text(ide_empregador_node, "tpInsc"),
				empresa_nr_insc: text(ide_empregador_node, "nrInsc"),
				estabelecimento_tp_insc: tp_insc,
				estabelecimento_nr_insc: nr_insc,
				ini_valid: ini_valid,
				fim_valid: fim_valid,
				vigente_em: @current_month,
				registro_atual: current_record?(acao_evento, ini_valid, fim_valid) ? "sim" : "nao",
				acao_evento: acao_evento,
				cnae_preponderante: text(dados_estab_node, "cnaePrep"),
				aliquota_gilrat: text(dados_estab_node, "aliqGilrat"),
				aliquota_fap: text(dados_estab_node, "fap"),
				aliquota_rat_ajustada: text(dados_estab_node, "aliqRatAjust"),
				data_recepcao: first_text(document, %w[dhRecepcao dhProcessamento dtRecepcao dtRecibido]),
				nr_recibo: text(document, "nrRecibo"),
				event_id: event_node.attributes["Id"].to_s,
				xml_sha256: Digest::SHA256.hexdigest(xml).upcase,
				source_path: source_path,
				nested_zip_path: nested_zip_path.to_s,
				xml_path: xml_path.to_s
			)
			@stats[:s1005_events] += 1
		rescue StandardError => error
			record_error(source_path, xml_path, error.message)
		end

		def estabelecimento_action_node(document)
			info_node = descendant(document, "infoEstab")
			return nil unless info_node

			info_node.elements.find { |element| ACTIONS.include?(local_name(element)) }
		end

		def current_record?(acao_evento, ini_valid, fim_valid)
			return false if acao_evento == "exclusao"
			return false if ini_valid.to_s.empty?
			return false if ini_valid > @current_month
			return false if !fim_valid.to_s.empty? && fim_valid < @current_month

			true
		end

		def build_current_rows
			@rows.group_by(&:estabelecimento_chave).filter_map do |_key, key_rows|
				candidates = key_rows.reject { |row| row.acao_evento == "exclusao" }
				next if candidates.empty?

				current_candidates = candidates.select { |row| row.registro_atual == "sim" }
				selected_pool = current_candidates.empty? ? candidates : current_candidates
				selected_pool.max_by { |row| row_sort_key(row) }
			end.sort_by { |row| [ row.estabelecimento_tp_insc.to_s, row.estabelecimento_nr_insc.to_s ] }
		end

		def row_sort_key(row)
			fim_valid_key = row.fim_valid.to_s.empty? ? "9999-12" : row.fim_valid.to_s
			[ row.ini_valid.to_s, fim_valid_key, row.data_recepcao.to_s, row.nr_recibo.to_s, row.event_id.to_s, row.xml_sha256.to_s ]
		end

		def write_outputs(current_rows)
			FileUtils.mkdir_p(@output_dir)
			events_path = @output_dir.join("estabelecimentos_s1005_eventos.csv")
			current_path = @output_dir.join("estabelecimentos_s1005_quadro.csv")
			summary_path = @output_dir.join("estabelecimentos_s1005_resumo.json")

			write_csv(events_path, @rows)
			write_csv(current_path, current_rows)
			File.write(summary_path, JSON.pretty_generate(summary_payload(current_rows)))

			{ events_csv: events_path.to_s, current_csv: current_path.to_s, summary_json: summary_path.to_s }
		end

		def write_csv(path, rows)
			CSV.open(path, "w:UTF-8", col_sep: ";", write_headers: true, headers: OUTPUT_COLUMNS) do |csv|
				rows.each { |row| csv << OUTPUT_COLUMNS.map { |column| row.to_h[column] } }
			end
		end

		def summary_payload(current_rows)
			{
				generated_at: Time.now.utc.iso8601,
				vigente_em: @current_month,
				stats: stats,
				estabelecimentos: current_rows.map(&:estabelecimento_chave)
			}
		end

		def descendant(node, name)
			return nil unless node

			node.each_element do |element|
				return element if local_name(element) == name

				found = descendant(element, name)
				return found if found
			end

			nil
		end

		def text(node, name)
			descendant(node, name)&.text.to_s.strip
		end

		def first_text(node, names)
			names.each do |name|
				value = text(node, name)
				return value if value.present?
			end

			""
		end

		def local_name(element)
			element.name.to_s.split(":").last
		end

		def normalize_month(value)
			return value.strftime("%Y-%m") if value.respond_to?(:strftime)

			value.to_s[0, 7]
		end

		def record_error(source_path, xml_path, message)
			@stats[:parse_errors] += 1
			return if @errors.size >= 20

			@errors << { source_path: source_path.to_s, xml_path: xml_path.to_s, message: message.to_s.lines.first.to_s.strip }
		end
	end
end
