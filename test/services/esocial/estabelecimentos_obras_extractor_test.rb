require "test_helper"
require "tmpdir"
require "zip"

module Esocial
	class EstabelecimentosObrasExtractorTest < ActiveSupport::TestCase
		test "extracts current estabelecimento records from xml and nested zip sources" do
			Dir.mktmpdir do |dir|
				xml_path = File.join(dir, "s1005_2019.xml")
				zip_path = File.join(dir, "nested.zip")
				output_dir = File.join(dir, "out")

				File.write(xml_path, s1005_xml(event_id: "ID001", ini_valid: "2019-01", fim_valid: "2019-12", fap: "1.0000", rat_ajust: "2.0000", data_recepcao: "2019-01-10T08:00:00"))
				Zip::File.open(zip_path, create: true) do |zip|
					zip.get_output_stream("2023/s1005.xml") do |io|
						io.write s1005_xml(event_id: "ID002", ini_valid: "2023-01", fim_valid: "", fap: "0.7345", rat_ajust: "1.4690", data_recepcao: "2023-01-06T10:30:00", acao: "alteracao")
					end
				end

				result = EstabelecimentosObrasExtractor.call(source_paths: [ xml_path, zip_path ], output_dir: output_dir, current_on: Date.new(2026, 6, 10))

				assert_equal 2, result.rows.size
				assert_equal 1, result.current_rows.size
				assert_equal "1", result.current_rows.first.estabelecimento_tp_insc
				assert_equal "12345678000190", result.current_rows.first.estabelecimento_nr_insc
				assert_equal "5611201", result.current_rows.first.cnae_preponderante
				assert_equal "3", result.current_rows.first.aliquota_gilrat
				assert_equal "0.7345", result.current_rows.first.aliquota_fap
				assert_equal "1.4690", result.current_rows.first.aliquota_rat_ajustada
				assert_equal "2023-01-06T10:30:00", result.current_rows.first.data_recepcao
				assert_equal "sim", result.current_rows.first.registro_atual
				assert_path_exists File.join(output_dir, "estabelecimentos_s1005_eventos.csv")
				assert_path_exists File.join(output_dir, "estabelecimentos_s1005_quadro.csv")
				assert_path_exists File.join(output_dir, "estabelecimentos_s1005_resumo.json")
			end
		end

		private

		def s1005_xml(event_id:, ini_valid:, fim_valid:, fap:, rat_ajust:, data_recepcao:, acao: "inclusao")
			fim_valid_node = fim_valid.empty? ? "" : "<fimValid>#{fim_valid}</fimValid>"

			<<~XML
				<eSocial>
				  <evtTabEstab Id="#{event_id}">
				    <ideEmpregador>
				      <tpInsc>1</tpInsc>
				      <nrInsc>12345678</nrInsc>
				    </ideEmpregador>
				    <infoEstab>
				      <#{acao}>
				        <ideEstab>
				          <tpInsc>1</tpInsc>
				          <nrInsc>12345678000190</nrInsc>
				          <iniValid>#{ini_valid}</iniValid>
				          #{fim_valid_node}
				        </ideEstab>
				        <dadosEstab>
				          <cnaePrep>5611201</cnaePrep>
				          <aliqGilrat>3</aliqGilrat>
				          <fap>#{fap}</fap>
				          <aliqRatAjust>#{rat_ajust}</aliqRatAjust>
				        </dadosEstab>
				      </#{acao}>
				    </infoEstab>
				    <retornoEvento>
				      <dhRecepcao>#{data_recepcao}</dhRecepcao>
				      <nrRecibo>1.2.0000000000000000000</nrRecibo>
				    </retornoEvento>
				  </evtTabEstab>
				</eSocial>
			XML
		end
	end
end
