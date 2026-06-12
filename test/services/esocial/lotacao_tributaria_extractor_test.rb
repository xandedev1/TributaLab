require "test_helper"
require "tmpdir"
require "zip"

module Esocial
	class LotacaoTributariaExtractorTest < ActiveSupport::TestCase
		test "extracts current lotacao records from xml and nested zip sources" do
			Dir.mktmpdir do |dir|
				xml_path = File.join(dir, "s1020_0001.xml")
				long_code_xml_path = File.join(dir, "s1020_000100000000000000.xml")
				zip_path = File.join(dir, "nested.zip")
				output_dir = File.join(dir, "out")
				long_code = "000100000000000000"

				File.write(xml_path, s1020_xml(event_id: "ID001", codigo_lotacao: "0001", ini_valid: "2024-01", fpas: "515", cod_tercs: "0115"))
				File.write(long_code_xml_path, s1020_xml(event_id: "ID003", codigo_lotacao: long_code, ini_valid: "2025-01", fpas: "507", cod_tercs: "0000"))
				Zip::File.open(zip_path, create: true) do |zip|
					zip.get_output_stream("2025/s1020_0001.xml") do |io|
						io.write s1020_xml(event_id: "ID002", codigo_lotacao: "0001", ini_valid: "2025-01", fpas: "507", cod_tercs: "0000", acao: "alteracao")
					end
				end

				result = LotacaoTributariaExtractor.call(source_paths: [ xml_path, long_code_xml_path, zip_path ], output_dir: output_dir, current_on: Date.new(2025, 6, 10))

				assert_equal 3, result.rows.size
				assert_equal 2, result.current_rows.size
				assert_equal "0001", result.current_rows.first.codigo_lotacao
				assert_equal "507", result.current_rows.first.fpas
				assert_equal "sim", result.current_rows.first.registro_atual
				assert_equal "FPAS=507 | COD_TERCS=0000 | COD_TERCS_SUSP=0003 | PROC_JUD=cod_terc=0003,nr_proc_jud=0000000-00.0000.0.00.0000,cod_susp=92", result.current_rows.first.enquadramento_eps_fpas
				assert_includes result.current_rows.map(&:codigo_lotacao), long_code
				assert_path_exists File.join(output_dir, "lotacoes_s1020_eventos.csv")
				assert_path_exists File.join(output_dir, "lotacoes_s1020_quadro.csv")
				assert_path_exists File.join(output_dir, "lotacoes_s1020_resumo.json")
			end
		end

		private

		def s1020_xml(event_id:, codigo_lotacao:, ini_valid:, fpas:, cod_tercs:, acao: "inclusao")
			<<~XML
				<eSocial>
				  <evtTabLotacao Id="#{event_id}">
				    <ideEmpregador>
				      <tpInsc>1</tpInsc>
				      <nrInsc>12345678</nrInsc>
				    </ideEmpregador>
				    <infoLotacao>
				      <#{acao}>
				        <ideLotacao>
				          <codLotacao>#{codigo_lotacao}</codLotacao>
				          <iniValid>#{ini_valid}</iniValid>
				        </ideLotacao>
				        <dadosLotacao>
				          <tpLotacao>01</tpLotacao>
				          <tpInsc>1</tpInsc>
				          <nrInsc>12345678</nrInsc>
				          <fpasLotacao>
				            <fpas>#{fpas}</fpas>
				            <codTercs>#{cod_tercs}</codTercs>
				            <codTercsSusp>0003</codTercsSusp>
				          </fpasLotacao>
				          <infoProcJudTerceiros>
				            <procJudTerceiro>
				              <codTerc>0003</codTerc>
				              <nrProcJud>0000000-00.0000.0.00.0000</nrProcJud>
				              <codSusp>92</codSusp>
				            </procJudTerceiro>
				          </infoProcJudTerceiros>
				        </dadosLotacao>
				      </#{acao}>
				    </infoLotacao>
				    <retornoEvento>
				      <nrRecibo>1.2.0000000000000000000</nrRecibo>
				    </retornoEvento>
				  </evtTabLotacao>
				</eSocial>
			XML
		end
	end
end
