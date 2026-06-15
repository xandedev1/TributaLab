require "csv"
require "rexml/document"

module Esocial
	class EstabelecimentosObrasDashboardSnapshot
		OFFICIAL_CURRENT_CSV_PATH = Rails.root.join("tmp", "estabelecimentos_s1005_oficial", "estabelecimentos_s1005_quadro.csv")
		OFFICIAL_EVENTS_CSV_PATH = Rails.root.join("tmp", "estabelecimentos_s1005_oficial", "estabelecimentos_s1005_eventos.csv")
		CURRENT_CSV_PATH = Rails.root.join("tmp", "estabelecimentos_s1005", "estabelecimentos_s1005_quadro.csv")
		EVENTS_CSV_PATH = Rails.root.join("tmp", "estabelecimentos_s1005", "estabelecimentos_s1005_eventos.csv")

		Metric = Struct.new(:label, :value, :detail, keyword_init: true)
		EstabelecimentoGroup = Struct.new(:chave, :rows, keyword_init: true) do
			def tp_insc
				rows.first&.estabelecimento_tp_insc.to_s
			end

			def nr_insc
				rows.first&.estabelecimento_nr_insc.to_s
			end

			def atual
				rows.find(&:atual?) || rows.max_by { |row| row.ini_valid.to_s }
			end
		end

		Row = Struct.new(
			:empresa_tp_insc,
			:empresa_nr_insc,
			:estabelecimento_tp_insc,
			:estabelecimento_nr_insc,
			:ini_valid,
			:fim_valid,
			:vigente_em,
			:registro_atual,
			:acao_evento,
			:cnae_preponderante,
			:aliquota_gilrat,
			:aliquota_fap,
			:aliquota_rat_ajustada,
			:data_recepcao,
			:nr_recibo,
			:event_id,
			:source_path,
			:xml_path,
			keyword_init: true
		) do
			MISSING_XML_VALUE = "nao consta no XML".freeze

			def atual?
				registro_atual == "sim"
			end

			def aliquota_fap_label
				aliquota_fap.presence || MISSING_XML_VALUE
			end

			def aliquota_gilrat_label
				aliquota_gilrat.presence || MISSING_XML_VALUE
			end

			def fim_valid_label
				fim_valid.presence || "vigente"
			end

			def estabelecimento_chave
				[estabelecimento_tp_insc, estabelecimento_nr_insc].join("|")
			end

			def periodo_label
				"#{ini_valid.presence || "-"} -> #{fim_valid_label}"
			end

			def searchable_text
				to_h.values.join(" ").downcase
			end
		end

		attr_reader :query, :load_error

		def initialize(filters = {})
			@query = filters[:q].to_s.strip
			@load_error = nil
		end

		def rows
			@rows ||= filtered_rows
		end

		def all_rows
			@all_rows ||= begin
				loaded = event_csv_paths.flat_map { |path| csv_rows(path) }
				loaded = current_csv_paths.flat_map { |path| csv_rows(path) } if loaded.empty?
				deduplicate_rows(loaded)
			end
		end

		def current_rows
			@current_rows ||= begin
				loaded = current_csv_paths.flat_map { |path| csv_rows(path) }
				loaded = all_rows.select(&:atual?) if loaded.empty?
				loaded = loaded.any? ? loaded : [ all_rows.max_by { |row| row.ini_valid.to_s } ].compact
				deduplicate_rows(loaded)
			end
		end

		def metrics
			@metrics ||= [
				Metric.new(label: "Evidencias", value: all_rows.size, detail: source_event_detail),
				Metric.new(label: "Estab/obras", value: estabelecimento_groups.size, detail: "inscricoes distintas"),
				Metric.new(label: "CNAE atual", value: current_cnaes.join(", ").presence || "-", detail: "cnae preponderante vigente"),
				Metric.new(label: "FAP atual", value: current_faps.join(", ").presence || "-", detail: "fator vigente em #{vigente_em_label}")
			]
		end

		def estabelecimento_groups
			@estabelecimento_groups ||= rows.group_by(&:estabelecimento_chave).map do |chave, group_rows|
				EstabelecimentoGroup.new(chave: chave, rows: group_rows.sort_by { |row| row.ini_valid.to_s })
			end.sort_by(&:chave)
		end

		def source_label
			return "eSocial oficial + XML local" if event_csv_paths.include?(OFFICIAL_EVENTS_CSV_PATH) && event_csv_paths.size > 1
			return "eSocial oficial" if event_csv_paths == [ OFFICIAL_EVENTS_CSV_PATH ]
			return "S-5011 oficial" if derived_from_s5011?
			return "S-1005 XML" if direct_s1005_xml?
			return "CSV extraido" if data_from_csv?
			return "CSV vazio" if any_source_file_exists?

			"sem fonte real"
		end

		def source_detail
			if event_csv_paths.any?
				event_csv_paths.map { |path| relative_path(path) }.join(" + ")
			elsif current_csv_paths.any?
				current_csv_paths.map { |path| relative_path(path) }.join(" + ")
			else
				"tmp/estabelecimentos_s1005/estabelecimentos_s1005_eventos.csv ausente"
			end
		end

		def data_from_csv?
			event_csv_paths.any? || current_csv_paths.any?
		end

		def vigente_em_label
			current_rows.find { |row| row.vigente_em.present? }&.vigente_em || Date.today.strftime("%Y-%m")
		end

		def events_count
			return event_csv_paths.sum { |path| count_csv_rows(path) } if event_csv_paths.any?

			all_rows.size
		end

		def source_event_detail
			derived_from_s5011? ? "linhas extraidas de ideEstab/infoEstab no S-5011" : "eventos S-1005 no historico"
		end

		def events_count_label
			derived_from_s5011? ? "evidencias S-5011" : "eventos S-1005"
		end

		private

		def filtered_rows
			base = all_rows.sort_by { |row| [ row.estabelecimento_chave, row.ini_valid.to_s ] }
			return base if query.blank?

			tokens = query.downcase.split
			base.select do |row|
				tokens.all? { |token| row.searchable_text.include?(token) }
			end
		end

		def event_csv_paths
			@event_csv_paths ||= s1005_csv_paths("estabelecimentos_s1005_eventos.csv")
		end

		def current_csv_paths
			@current_csv_paths ||= s1005_csv_paths("estabelecimentos_s1005_quadro.csv")
		end

		def any_source_file_exists?
			s1005_csv_paths("estabelecimentos_s1005_eventos.csv", require_rows: false).any? ||
				s1005_csv_paths("estabelecimentos_s1005_quadro.csv", require_rows: false).any?
		end

		def s1005_csv_paths(filename, require_rows: true)
			paths = Rails.root.glob("tmp/estabelecimentos_s1005*/#{filename}").sort_by do |path|
				[ path.to_s.include?("_oficial") ? 0 : 1, path.to_s ]
			end
			return paths.select(&:exist?) unless require_rows

			paths.select { |path| path.exist? && csv_rows(path).any? }
		end

		def deduplicate_rows(rows)
			rows.each_with_object({}) do |row, unique_rows|
				key = row.event_id.presence || [ row.estabelecimento_chave, row.ini_valid, row.fim_valid, row.nr_recibo ].join("|")
				unique_rows[key] = row
			end.values
		end

		def csv_rows(path)
			@csv_cache ||= {}
			return @csv_cache[path] if @csv_cache.key?(path)
			return @csv_cache[path] = [] unless path.exist?

			@csv_cache[path] = CSV.foreach(path, headers: true, col_sep: ";", encoding: "bom|utf-8").map do |csv_row|
				build_row(csv_row.to_h)
			end
		rescue StandardError => error
			@load_error = error.message
			@csv_cache[path] = []
		end

		def build_row(attributes)
			Row.new(
				empresa_tp_insc: attributes["empresa_tp_insc"].to_s,
				empresa_nr_insc: attributes["empresa_nr_insc"].to_s,
				estabelecimento_tp_insc: attributes["estabelecimento_tp_insc"].to_s,
				estabelecimento_nr_insc: attributes["estabelecimento_nr_insc"].to_s,
				ini_valid: attributes["ini_valid"].to_s,
				fim_valid: attributes["fim_valid"].to_s,
				vigente_em: attributes["vigente_em"].to_s,
				registro_atual: attributes["registro_atual"].to_s,
				acao_evento: attributes["acao_evento"].to_s,
				cnae_preponderante: attributes["cnae_preponderante"].to_s,
				aliquota_gilrat: attributes["aliquota_gilrat"].presence || retorno_aliq_rat(attributes["event_id"]).to_s,
				aliquota_fap: attributes["aliquota_fap"].to_s,
				aliquota_rat_ajustada: attributes["aliquota_rat_ajustada"].to_s,
				data_recepcao: attributes["data_recepcao"].to_s,
				nr_recibo: attributes["nr_recibo"].to_s,
				event_id: attributes["event_id"].to_s,
				source_path: attributes["source_path"].to_s,
				xml_path: attributes["xml_path"].to_s
			)
		end

		def current_cnaes
			distinct_values(current_rows, :cnae_preponderante)
		end

		def current_faps
			distinct_values(current_rows, :aliquota_fap)
		end

		def distinct_values(collection, attribute)
			collection.map { |row| row.public_send(attribute).to_s }.reject(&:blank?).uniq.sort
		end

		def count_csv_rows(path)
			CSV.foreach(path, headers: true, col_sep: ";", encoding: "bom|utf-8").count
		rescue StandardError
			all_rows.size
		end

		def retorno_aliq_rat(event_id)
			return "" if event_id.blank?

			retorno_aliq_rat_by_event_id[event_id.to_s].to_s
		end

		def retorno_aliq_rat_by_event_id
			@retorno_aliq_rat_by_event_id ||= begin
				Rails.root.glob("storage/esocial_official/cte/**/download_recibos_*.xml").each_with_object({}) do |path, values|
					document = REXML::Document.new(File.binread(path))
					descendants(document, "arquivo").each do |arquivo_node|
						event_node = descendant(arquivo_node, "evt")
						event_id = event_node&.attributes&.[]("Id").to_s.presence || descendant(arquivo_node, "evtTabEstab")&.attributes&.[]("Id").to_s
						aliq_rat = text(descendant(arquivo_node, "infoEstabelecimento"), "aliqRat")
						values[event_id] = aliq_rat if event_id.present? && aliq_rat.present?
					end
				rescue StandardError
					next
				end
			end
		end

		def derived_from_s5011?
			all_rows.any? && all_rows.all? { |row| row.acao_evento == "totalizador S-5011" }
		end

		def direct_s1005_xml?
			all_rows.any? && all_rows.all? { |row| %w[inclusao alteracao exclusao].include?(row.acao_evento) }
		end

		def relative_path(path)
			path.relative_path_from(Rails.root).to_s
		rescue ArgumentError
			path.to_s
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

		def descendants(node, name, matches = [])
			return matches unless node

			node.each_element do |element|
				matches << element if local_name(element) == name
				descendants(element, name, matches)
			end

			matches
		end

		def text(node, name)
			descendant(node, name)&.text.to_s.strip
		end

		def local_name(element)
			element.name.to_s.split(":").last
		end
	end
end
