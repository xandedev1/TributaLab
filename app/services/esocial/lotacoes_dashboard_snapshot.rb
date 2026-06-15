require "csv"

module Esocial
	class LotacoesDashboardSnapshot
		OFFICIAL_CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020_oficial", "lotacoes_s1020_quadro.csv")
		OFFICIAL_EVENTS_CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020_oficial", "lotacoes_s1020_eventos.csv")
		CTE_ZIP_CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020_cte_zips", "lotacoes_s1020_quadro.csv")
		CTE_ZIP_EVENTS_CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020_cte_zips", "lotacoes_s1020_eventos.csv")
		CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020", "lotacoes_s1020_quadro.csv")
		EVENTS_CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020", "lotacoes_s1020_eventos.csv")

		Metric = Struct.new(:label, :value, :detail, keyword_init: true)
		FpasGroup = Struct.new(:fpas, :rows, :cod_tercs, :suspensos, keyword_init: true)
		Row = Struct.new(
			:empresa_tp_insc,
			:empresa_nr_insc,
			:codigo_lotacao,
			:ini_valid,
			:fim_valid,
			:vigente_em,
			:registro_atual,
			:acao_evento,
			:tp_lotacao,
			:enquadramento_eps_fpas,
			:fpas,
			:cod_tercs,
			:cod_tercs_suspensos,
			:processos_judiciais,
			:lotacao_tp_insc,
			:lotacao_nr_insc,
			:aliq_rat,
			:fap,
			:nr_recibo,
			:event_id,
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

			def processo_count
				processos_judiciais.to_s.split("|").reject(&:blank?).size
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
				loaded = selected_events_path ? csv_rows(selected_events_path) : []
				loaded = csv_rows(selected_current_path) if loaded.empty? && selected_current_path
				loaded
			end
		end

		def metrics
			@metrics ||= [
				Metric.new(label: "Codigos", value: distinct_values(all_rows, :codigo_lotacao).size, detail: "lotacoes no historico"),
				Metric.new(label: "Vigentes", value: all_rows.count(&:atual?), detail: "validas em #{vigente_em_label}"),
				Metric.new(label: "Eventos", value: all_rows.size, detail: "linhas do CSV carregado"),
				Metric.new(label: "FPAS", value: distinct_values(all_rows, :fpas).size, detail: distinct_values(all_rows, :fpas).join(", ").presence || "sem FPAS"),
				Metric.new(label: "Excluidos", value: all_rows.count { |row| row.acao_evento == "exclusao" }, detail: "eventos de exclusao")
			]
		end

		def fpas_groups
			@fpas_groups ||= rows.group_by(&:fpas).map do |fpas, group_rows|
				FpasGroup.new(
					fpas: fpas.presence || "-",
					rows: group_rows,
					cod_tercs: distinct_values(group_rows, :cod_tercs),
					suspensos: distinct_values(group_rows, :cod_tercs_suspensos)
				)
			end.sort_by(&:fpas)
		end

		def events_count
			return count_csv_rows(selected_events_path) if selected_events_path

			all_rows.size
		end

		def source_label
			return "eSocial oficial" if selected_events_path == OFFICIAL_EVENTS_CSV_PATH
			return "XML CTE ZIP" if selected_events_path == CTE_ZIP_EVENTS_CSV_PATH
			return "CSV capturado" if selected_events_path == EVENTS_CSV_PATH
			return "CSV extraido" if data_from_csv?
			return "CSV vazio" if any_source_file_exists?

			"sem fonte real"
		end

		def source_detail
			return relative_path(selected_events_path) if selected_events_path
			return relative_path(selected_current_path) if selected_current_path

			"tmp/lotacoes_s1020_cte_zips/lotacoes_s1020_eventos.csv ausente"
		end

		def data_from_csv?
			all_rows.any?
		end

		def vigente_em_label
			all_rows.find { |row| row.vigente_em.present? }&.vigente_em || Date.today.strftime("%Y-%m")
		end

		private

		def filtered_rows
			return all_rows if query.blank?

			tokens = query.downcase.split
			all_rows.select do |row|
				tokens.all? { |token| row.searchable_text.include?(token) }
			end
		end

		def selected_events_path
			@selected_events_path ||= [ OFFICIAL_EVENTS_CSV_PATH, CTE_ZIP_EVENTS_CSV_PATH, EVENTS_CSV_PATH ].find { |path| path.exist? && csv_rows(path).any? }
		end

		def selected_current_path
			@selected_current_path ||= [ OFFICIAL_CSV_PATH, CTE_ZIP_CSV_PATH, CSV_PATH ].find { |path| path.exist? && csv_rows(path).any? }
		end

		def any_source_file_exists?
			[ OFFICIAL_EVENTS_CSV_PATH, CTE_ZIP_EVENTS_CSV_PATH, EVENTS_CSV_PATH, OFFICIAL_CSV_PATH, CTE_ZIP_CSV_PATH, CSV_PATH ].any?(&:exist?)
		end

		def csv_rows(path = CSV_PATH)
			@csv_rows ||= {}
			return @csv_rows[path] if @csv_rows.key?(path)

			return @csv_rows[path] = [] unless path.exist?

			@csv_rows[path] = CSV.foreach(path, headers: true, col_sep: ";", encoding: "bom|utf-8").map do |csv_row|
				build_row(csv_row.to_h)
			end
		rescue StandardError => error
			@load_error = error.message
			@csv_rows[path] = []
		end

		def build_row(attributes)
			Row.new(
				empresa_tp_insc: attributes["empresa_tp_insc"].to_s,
				empresa_nr_insc: attributes["empresa_nr_insc"].to_s,
				codigo_lotacao: attributes["codigo_lotacao"].to_s,
				ini_valid: attributes["ini_valid"].to_s,
				fim_valid: attributes["fim_valid"].to_s,
				vigente_em: attributes["vigente_em"].to_s,
				registro_atual: attributes["registro_atual"].to_s,
				acao_evento: attributes["acao_evento"].to_s,
				tp_lotacao: attributes["tp_lotacao"].to_s,
				enquadramento_eps_fpas: attributes["enquadramento_eps_fpas"].to_s,
				fpas: attributes["fpas"].to_s,
				cod_tercs: attributes["cod_tercs"].to_s,
				cod_tercs_suspensos: attributes["cod_tercs_suspensos"].to_s,
				processos_judiciais: attributes["processos_judiciais"].to_s,
				lotacao_tp_insc: attributes["lotacao_tp_insc"].to_s,
				lotacao_nr_insc: attributes["lotacao_nr_insc"].to_s,
				aliq_rat: attributes["aliq_rat"].presence || attributes["aliqRat"].presence || attributes["aliquota_gilrat"].to_s,
				fap: attributes["fap"].to_s,
				nr_recibo: attributes["nr_recibo"].to_s,
				event_id: attributes["event_id"].to_s,
				source_path: attributes["source_path"].to_s,
				xml_path: attributes["xml_path"].to_s
			)
		end

		def rows_with_suspension
			all_rows.select { |row| row.cod_tercs_suspensos.present? || row.processos_judiciais.present? }
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
