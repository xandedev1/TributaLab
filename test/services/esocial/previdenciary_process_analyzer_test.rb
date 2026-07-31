require "test_helper"
require "tmpdir"

module Esocial
	class PrevidenciaryProcessAnalyzerTest < ActiveSupport::TestCase
		test "matches an S-1010 previdenciary suspension to its S-1070 process" do
			Dir.mktmpdir do |directory|
				File.write(File.join(directory, "s1070.xml"), process_xml)
				File.write(File.join(directory, "s1010.xml"), rubric_xml)

				result = PrevidenciaryProcessAnalyzer.new(directory).call

				assert_empty result.errors
				assert_equal 1, result.processes.size
				assert_equal 1, result.rubric_links.size
				assert_equal 1, result.matches.size
				assert_empty result.unmatched_links

				process = result.processes.first
				link = result.rubric_links.first
				assert_equal "1.1.0000000042395247693", process.receipt
				assert_equal "50064912020224036119", process.process_number
				assert_equal "1", process.suspensions.first.code
				assert_equal "1.1.0000000042403419933", link.receipt
				assert_equal "05969071", link.employer_registration
				assert_equal "91", link.previdenciary_incidence
				assert_equal "1", link.decision_scope
				assert_equal process, result.matches.first.processes.first
			end
		end

		test "matches S-1020 third-party suspensions to the S-1070 process" do
			Dir.mktmpdir do |directory|
				File.write(File.join(directory, "s1070.xml"), process_xml)
				File.write(File.join(directory, "s1020.xml"), lotation_xml)

				result = PrevidenciaryProcessAnalyzer.new(directory).call

				assert_empty result.errors
				assert_equal 5, result.lotation_links.size
				assert_equal 5, result.lotation_matches.size
				assert_empty result.unmatched_lotation_links
				assert_equal %w[0001 0002 0016 0032 0064], result.lotation_links.map(&:third_party_entity_code)
				assert result.lotation_links.all? { |link| link.fpas == "515" }
				assert result.lotation_links.all? { |link| link.suspended_third_party_code == "0115" }
			end
		end

		private

		def process_xml
			<<~XML
				<eSocial>
				  <evtTabProcesso Id="ID1070">
				    <ideEmpregador><tpInsc>1</tpInsc><nrInsc>05969071</nrInsc></ideEmpregador>
				    <infoProcesso>
				      <inclusao>
				        <ideProcesso>
				          <tpProc>2</tpProc><nrProc>50064912020224036119</nrProc><iniValid>2026-06</iniValid>
				        </ideProcesso>
				        <dadosProc>
				          <indMatProc>1</indMatProc>
				          <infoSusp>
				            <codSusp>1</codSusp><indSusp>01</indSusp><dtDecisao>2023-01-01</dtDecisao><indDeposito>N</indDeposito>
				          </infoSusp>
				        </dadosProc>
				      </inclusao>
				    </infoProcesso>
				  </evtTabProcesso>
				  <retornoEvento><nrRecibo>1.1.0000000042395247693</nrRecibo></retornoEvento>
				</eSocial>
			XML
		end

		def rubric_xml
			<<~XML
				<eSocial>
				  <evtTabRubrica Id="ID1010">
				    <ideEmpregador><tpInsc>1</tpInsc><nrInsc>05969071</nrInsc></ideEmpregador>
				    <infoRubrica>
				      <alteracao>
				        <ideRubrica>
				          <codRubr>120</codRubr><ideTabRubr>1</ideTabRubr><iniValid>2026-06</iniValid>
				        </ideRubrica>
				        <dadosRubrica>
				          <dscRubr>Aviso prévio indenizado</dscRubr><natRubr>6003</natRubr><tpRubr>1</tpRubr><codIncCP>91</codIncCP>
				          <ideProcessoCP>
				            <tpProc>2</tpProc><nrProc>50064912020224036119</nrProc><extDecisao>1</extDecisao><codSusp>01</codSusp>
				          </ideProcessoCP>
				        </dadosRubrica>
				      </alteracao>
				    </infoRubrica>
				  </evtTabRubrica>
				  <retornoEvento><nrRecibo>1.1.0000000042403419933</nrRecibo></retornoEvento>
				</eSocial>
			XML
		end

		def lotation_xml
			processes = %w[0001 0002 0016 0032 0064].map do |code|
				<<~XML
					<procJudTerceiro>
					  <codTerc>#{code}</codTerc><nrProcJud>5006491-20.2022.4.03.6119</nrProcJud><codSusp>1</codSusp>
					</procJudTerceiro>
				XML
			end.join

			<<~XML
				<eSocial>
				  <evtTabLotacao Id="ID1020">
				    <ideEmpregador><tpInsc>1</tpInsc><nrInsc>05969071</nrInsc></ideEmpregador>
				    <infoLotacao>
				      <alteracao>
				        <ideLotacao><codLotacao>E00410-001-02A</codLotacao><iniValid>2026-06</iniValid></ideLotacao>
				        <dadosLotacao>
				          <tpLotacao>04</tpLotacao>
				          <fpasLotacao>
				            <fpas>515</fpas><codTercs>0115</codTercs><codTercsSusp>0115</codTercsSusp>
				            <infoProcJudTerceiros>#{processes}</infoProcJudTerceiros>
				          </fpasLotacao>
				        </dadosLotacao>
				      </alteracao>
				    </infoLotacao>
				    <retornoEvento><nrRecibo>1.1.0000000042409999999</nrRecibo></retornoEvento>
				  </evtTabLotacao>
				</eSocial>
			XML
		end
	end
end