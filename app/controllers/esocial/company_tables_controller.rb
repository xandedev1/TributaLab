module Esocial
	class CompanyTablesController < ApplicationController
		XLSX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

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

		def s1020_xlsx
			snapshot = LotacoesDashboardSnapshot.new
			send_data(
				CompanyTablesXlsxExporter.s1020(snapshot.rows),
				filename: "tabelas_empresa_s1020.xlsx",
				type: XLSX_MIME_TYPE,
				disposition: "attachment"
			)
		end
	end
end