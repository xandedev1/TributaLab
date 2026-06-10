require "csv"

module Esocial
	class EstabelecimentosObrasDashboardSnapshot
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
			:source_path,
			:xml_path,
			keyword_init: true
		) do
			def atual?
				registro_atual == "sim"
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
				loaded = csv_rows(EVENTS_CSV_PATH)
				loaded = csv_rows(CURRENT_CSV_PATH) if loaded.empty?
				loaded.any? ? loaded : demo_rows
			end
		end

		def current_rows
			@current_rows ||= begin
				loaded = csv_rows(CURRENT_CSV_PATH)
				loaded = all_rows.select(&:atual?) if loaded.empty?
				loaded.any? ? loaded : [ all_rows.max_by { |row| row.ini_valid.to_s } ].compact
			end
		end

		def metrics
			@metrics ||= [
				Metric.new(label: "Periodos", value: all_rows.size, detail: "eventos S-1005 no historico"),
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
			data_from_csv? ? "CSV extraido" : "demonstrativo"
		end

		def source_detail
			if EVENTS_CSV_PATH.exist?
				relative_path(EVENTS_CSV_PATH)
			elsif CURRENT_CSV_PATH.exist?
				relative_path(CURRENT_CSV_PATH)
			else
				"modelo visual S-1005"
			end
		end

		def data_from_csv?
			(EVENTS_CSV_PATH.exist? && csv_rows(EVENTS_CSV_PATH).any?) || (CURRENT_CSV_PATH.exist? && csv_rows(CURRENT_CSV_PATH).any?)
		end

		def vigente_em_label
			current_rows.find { |row| row.vigente_em.present? }&.vigente_em || Date.today.strftime("%Y-%m")
		end

		def events_count
			return count_csv_rows(EVENTS_CSV_PATH) if EVENTS_CSV_PATH.exist?

			all_rows.size
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

		def demo_rows
			[
				build_row(base_demo.merge("ini_valid" => "2018-01", "fim_valid" => "2018-12", "aliquota_fap" => "1.0000", "aliquota_rat_ajustada" => "3.0000", "data_recepcao" => "2018-01-08T09:20:00", "registro_atual" => "nao")),
				build_row(base_demo.merge("ini_valid" => "2019-01", "fim_valid" => "2019-12", "aliquota_fap" => "0.9821", "aliquota_rat_ajustada" => "2.9463", "data_recepcao" => "2019-01-07T10:11:00", "registro_atual" => "nao")),
				build_row(base_demo.merge("ini_valid" => "2020-01", "fim_valid" => "2020-12", "aliquota_fap" => "0.9120", "aliquota_rat_ajustada" => "2.7360", "data_recepcao" => "2020-01-06T11:04:00", "registro_atual" => "nao")),
				build_row(base_demo.merge("ini_valid" => "2021-01", "fim_valid" => "2021-12", "aliquota_fap" => "0.8455", "aliquota_rat_ajustada" => "2.5365", "data_recepcao" => "2021-01-05T08:47:00", "registro_atual" => "nao")),
				build_row(base_demo.merge("ini_valid" => "2022-01", "fim_valid" => "2022-12", "aliquota_fap" => "0.8012", "aliquota_rat_ajustada" => "2.4036", "data_recepcao" => "2022-01-06T14:32:00", "registro_atual" => "nao")),
				build_row(base_demo.merge("ini_valid" => "2023-01", "fim_valid" => "", "aliquota_fap" => "0.7345", "aliquota_rat_ajustada" => "2.2035", "data_recepcao" => "2023-01-06T10:30:00", "registro_atual" => "sim"))
			]
		end

		def base_demo
			{
				"empresa_tp_insc" => "1",
				"empresa_nr_insc" => "CNPJ raiz CTE",
				"estabelecimento_tp_insc" => "1",
				"estabelecimento_nr_insc" => "CNPJ estabelecimento CTE",
				"vigente_em" => Date.today.strftime("%Y-%m"),
				"acao_evento" => "alteracao",
				"cnae_preponderante" => "4930202",
				"aliquota_gilrat" => "3",
				"nr_recibo" => "modelo",
				"source_path" => "modelo S-1005",
				"xml_path" => "evtTabEstab"
			}
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
				aliquota_gilrat: attributes["aliquota_gilrat"].to_s,
				aliquota_fap: attributes["aliquota_fap"].to_s,
				aliquota_rat_ajustada: attributes["aliquota_rat_ajustada"].to_s,
				data_recepcao: attributes["data_recepcao"].to_s,
				nr_recibo: attributes["nr_recibo"].to_s,
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

		def relative_path(path)
			path.relative_path_from(Rails.root).to_s
		rescue ArgumentError
			path.to_s
		end
	end
end
