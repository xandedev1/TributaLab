require "csv"

module Esocial
	class LotacoesDashboardSnapshot
		CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020", "lotacoes_s1020_quadro.csv")
		EVENTS_CSV_PATH = Rails.root.join("tmp", "lotacoes_s1020", "lotacoes_s1020_eventos.csv")

		Metric = Struct.new(:label, :value, :detail, keyword_init: true)
		FpasGroup = Struct.new(:fpas, :rows, :cod_tercs, :suspensos, keyword_init: true)
		Row = Struct.new(
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
				loaded = csv_rows
				loaded.any? ? loaded : demo_rows
			end
		end

		def metrics
			@metrics ||= [
				Metric.new(label: "Codigos", value: all_rows.size, detail: "lotacoes no quadro"),
				Metric.new(label: "Vigentes", value: all_rows.count(&:atual?), detail: "validas em #{vigente_em_label}"),
				Metric.new(label: "FPAS", value: distinct_values(all_rows, :fpas).size, detail: distinct_values(all_rows, :fpas).join(", ").presence || "sem FPAS"),
				Metric.new(label: "Suspensoes", value: rows_with_suspension.size, detail: "terceiros/processos no S-1020")
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
			return count_csv_rows(EVENTS_CSV_PATH) if EVENTS_CSV_PATH.exist?

			all_rows.size
		end

		def source_label
			csv_available? ? "CSV extraido" : "demonstrativo"
		end

		def source_detail
			csv_available? ? relative_path(CSV_PATH) : "modelo visual S-1020"
		end

		def data_from_csv?
			csv_available? && csv_rows.any?
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

		def csv_available?
			CSV_PATH.exist?
		end

		def csv_rows
			@csv_rows ||= begin
				return [] unless csv_available?

				CSV.foreach(CSV_PATH, headers: true, col_sep: ";", encoding: "bom|utf-8").map do |csv_row|
					build_row(csv_row.to_h)
				end
			rescue StandardError => error
				@load_error = error.message
				[]
			end
		end

		def demo_rows
			[
				build_row(
					"codigo_lotacao" => "0001",
					"ini_valid" => "2025-01",
					"fim_valid" => "",
					"vigente_em" => Date.today.strftime("%Y-%m"),
					"registro_atual" => "sim",
					"acao_evento" => "alteracao",
					"tp_lotacao" => "01",
					"enquadramento_eps_fpas" => "FPAS=507 | COD_TERCS=0000 | COD_TERCS_SUSP=0003",
					"fpas" => "507",
					"cod_tercs" => "0000",
					"cod_tercs_suspensos" => "0003",
					"processos_judiciais" => "cod_terc=0003,nr_proc_jud=0000000-00.0000.0.00.0000,cod_susp=92",
					"nr_recibo" => "modelo",
					"source_path" => "modelo S-1020",
					"xml_path" => "evtTabLotacao"
				),
				build_row(
					"codigo_lotacao" => "0002",
					"ini_valid" => "2025-01",
					"fim_valid" => "",
					"vigente_em" => Date.today.strftime("%Y-%m"),
					"registro_atual" => "sim",
					"acao_evento" => "inclusao",
					"tp_lotacao" => "01",
					"enquadramento_eps_fpas" => "FPAS=515 | COD_TERCS=0115",
					"fpas" => "515",
					"cod_tercs" => "0115",
					"cod_tercs_suspensos" => "",
					"processos_judiciais" => "",
					"nr_recibo" => "modelo",
					"source_path" => "modelo S-1020",
					"xml_path" => "evtTabLotacao"
				),
				build_row(
					"codigo_lotacao" => "0099",
					"ini_valid" => "2024-07",
					"fim_valid" => "2025-12",
					"vigente_em" => Date.today.strftime("%Y-%m"),
					"registro_atual" => "sim",
					"acao_evento" => "alteracao",
					"tp_lotacao" => "04",
					"enquadramento_eps_fpas" => "FPAS=507 | COD_TERCS=0079",
					"fpas" => "507",
					"cod_tercs" => "0079",
					"cod_tercs_suspensos" => "",
					"processos_judiciais" => "",
					"nr_recibo" => "modelo",
					"source_path" => "modelo S-1020",
					"xml_path" => "evtTabLotacao"
				)
			]
		end

		def build_row(attributes)
			Row.new(
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
				nr_recibo: attributes["nr_recibo"].to_s,
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
