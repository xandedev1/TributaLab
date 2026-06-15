require "erb"
require "stringio"
require "zip"

module Esocial
	class CompanyTablesXlsxExporter
		CONTENT_TYPE_XML = <<~XML.freeze
			<?xml version="1.0" encoding="UTF-8"?>
			<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
				<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
				<Default Extension="xml" ContentType="application/xml"/>
				<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
				<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
				<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
				<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
				<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
			</Types>
		XML

		ROOT_RELS_XML = <<~XML.freeze
			<?xml version="1.0" encoding="UTF-8"?>
			<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
				<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
				<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
				<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
			</Relationships>
		XML

		WORKBOOK_XML = <<~XML.freeze
			<?xml version="1.0" encoding="UTF-8"?>
			<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
				<sheets>
					<sheet name="Tabelas Empresa" sheetId="1" r:id="rId1"/>
				</sheets>
			</workbook>
		XML

		WORKBOOK_RELS_XML = <<~XML.freeze
			<?xml version="1.0" encoding="UTF-8"?>
			<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
				<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
				<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
			</Relationships>
		XML

		STYLES_XML = <<~XML.freeze
			<?xml version="1.0" encoding="UTF-8"?>
			<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
				<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
				<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
				<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
				<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
				<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/></cellXfs>
				<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
			</styleSheet>
		XML

		def self.s1005(rows)
			new(
				headers: %w[Id tpInsc nrInsc cnaePrep fap aliqRat iniValid fimValid],
				rows: rows.map do |row|
					[
						row.event_id,
						row.estabelecimento_tp_insc,
						row.estabelecimento_nr_insc,
						row.cnae_preponderante,
						row.aliquota_fap_label,
						row.aliquota_gilrat_label,
						row.ini_valid,
						row.fim_valid_label
					]
				end
			).call
		end

		def self.s1020(rows)
			new(
				headers: %w[Id tpInsc nrInsc tpLotacao codLotacao fpas codTercs aliqRat fap iniValid fimValid],
				rows: rows.map do |row|
					[
						row.event_id,
						row.empresa_tp_insc.presence || row.lotacao_tp_insc,
						row.empresa_nr_insc.presence || row.lotacao_nr_insc,
						row.tp_lotacao,
						row.codigo_lotacao,
						row.fpas,
						row.cod_tercs,
						row.aliq_rat,
						row.fap,
						row.ini_valid,
						row.fim_valid_label
					]
				end
			).call
		end

		def initialize(headers:, rows:)
			@headers = headers
			@rows = rows
		end

		def call
			buffer = Zip::OutputStream.write_buffer do |zip|
				write_entry(zip, "[Content_Types].xml", CONTENT_TYPE_XML)
				write_entry(zip, "_rels/.rels", ROOT_RELS_XML)
				write_entry(zip, "xl/workbook.xml", WORKBOOK_XML)
				write_entry(zip, "xl/_rels/workbook.xml.rels", WORKBOOK_RELS_XML)
				write_entry(zip, "xl/styles.xml", STYLES_XML)
				write_entry(zip, "xl/worksheets/sheet1.xml", worksheet_xml)
				write_entry(zip, "docProps/core.xml", core_xml)
				write_entry(zip, "docProps/app.xml", app_xml)
			end

			buffer.string
		end

		private

		def write_entry(zip, path, content)
			zip.put_next_entry(path)
			zip.write(content)
		end

		def worksheet_xml
			all_rows = [@headers] + @rows
			rows_xml = all_rows.each_with_index.map do |row, row_index|
				row_number = row_index + 1
				cells_xml = row.each_with_index.map do |value, column_index|
					cell_xml(value, row_number, column_index + 1, row_index.zero?)
				end.join

				%(<row r="#{row_number}">#{cells_xml}</row>)
			end.join

			<<~XML
				<?xml version="1.0" encoding="UTF-8"?>
				<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
					<sheetViews><sheetView workbookViewId="0"/></sheetViews>
					<sheetFormatPr defaultRowHeight="15"/>
					<cols>#{columns_xml}</cols>
					<sheetData>#{rows_xml}</sheetData>
				</worksheet>
			XML
		end

		def columns_xml
			@headers.each_index.map do |column_index|
				column_number = column_index + 1
				%(<col min="#{column_number}" max="#{column_number}" width="24" customWidth="1"/>).html_safe
			end.join
		end

		def cell_xml(value, row_number, column_number, header)
			style_attribute = header ? " s=\"1\"" : ""
			%(<c r="#{column_letters(column_number)}#{row_number}" t="inlineStr"#{style_attribute}><is><t>#{escape(value)}</t></is></c>)
		end

		def column_letters(column_number)
			letters = ""
			current_number = column_number

			while current_number.positive?
				current_number -= 1
				letters.prepend((65 + (current_number % 26)).chr)
				current_number /= 26
			end

			letters
		end

		def escape(value)
			ERB::Util.html_escape(value.to_s)
		end

		def core_xml
			timestamp = Time.current.utc.iso8601

			<<~XML
				<?xml version="1.0" encoding="UTF-8"?>
				<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
					<dc:title>Tabelas Empresa</dc:title>
					<dc:creator>TributaLab</dc:creator>
					<cp:lastModifiedBy>TributaLab</cp:lastModifiedBy>
					<dcterms:created xsi:type="dcterms:W3CDTF">#{timestamp}</dcterms:created>
					<dcterms:modified xsi:type="dcterms:W3CDTF">#{timestamp}</dcterms:modified>
				</cp:coreProperties>
			XML
		end

		def app_xml
			<<~XML
				<?xml version="1.0" encoding="UTF-8"?>
				<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
					<Application>TributaLab</Application>
				</Properties>
			XML
		end
	end
end