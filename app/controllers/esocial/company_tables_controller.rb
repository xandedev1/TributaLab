module Esocial
	class CompanyTablesController < ApplicationController
		XLSX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
		XML_MIME_TYPE = "application/xml"

		def index
			@estabelecimentos_snapshot = EstabelecimentosObrasDashboardSnapshot.new
			@lotacoes_snapshot = LotacoesDashboardSnapshot.new
		end

		def s1005_xlsx
			snapshot = EstabelecimentosObrasDashboardSnapshot.new
			send_data(
				CompanyTablesXlsxExporter.s1005(snapshot.rows),
				filename: "tabelas_empresa_s1005.xlsx",
				type: XLSX_MIME_TYPE,
				disposition: "attachment"
			)
		end

		def s1005_xml
			snapshot = EstabelecimentosObrasDashboardSnapshot.new
			send_event_xml(snapshot.rows, "S-1005")
		end

		def s1020_xlsx
			snapshot = LotacoesDashboardSnapshot.new
			send_data(
				CompanyTablesXlsxExporter.s1020(snapshot.rows),
				filename: "tabelas_empresa_s1020.xlsx",
				type: XLSX_MIME_TYPE,
				disposition: "attachment"
			)
		end

		def s1020_xml
			snapshot = LotacoesDashboardSnapshot.new
			send_event_xml(snapshot.rows, "S-1020")
		end

		private

		def send_event_xml(rows, event_type)
			row = rows.find { |candidate| candidate.event_id.to_s == params[:event_id].to_s }
			path = row && Pathname.new(row.source_path.to_s)

			return render plain: "XML original nao encontrado para a linha selecionada.", status: :not_found unless path&.file? && path.extname.casecmp(".xml").zero?

			send_file(path, filename: xml_filename(row.event_id, event_type), type: XML_MIME_TYPE, disposition: "attachment")
		end

		def xml_filename(event_id, event_type)
			"#{event_id.to_s.gsub(/[^A-Za-z0-9_.-]/, "_")}.#{event_type}.xml"
		end
	end
end