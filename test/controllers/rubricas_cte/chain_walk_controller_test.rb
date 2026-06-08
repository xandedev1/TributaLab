require "test_helper"

module RubricasCte
	class ChainWalkControllerTest < ActionDispatch::IntegrationTest
		setup do
			Finding.delete_all
			RubricIdentityLink.delete_all
			S1010TimelineSegment.delete_all
			S1010Event.delete_all
			ExpectedIncidence.delete_all
			ExpectedMapping.delete_all
			CatalogRubric.delete_all
			ImportRun.delete_all
			SourceFile.delete_all

			source = SourceFile.create!(kind: "test", repo_path: "test.zip", sha256: "CHAINWALKTEST")
			rubric = CatalogRubric.create!(source_file: source, table_code: "001", cte_code: "5610", description: "ADIANTAMENTO VALE", normalized_description: "adiantamento vale", first_source_row: 10, last_source_row: 11, source_rows_count: 2)
			mapping = ExpectedMapping.create!(catalog_rubric: rubric, source_file: source, source_sheet: "Plan1", source_row: 10, esocial_nature_code: "9200", fn: "N", inm: "N", irm: "N", incidence_profile: { "FGTS" => { "flag" => "nao_incide" }, "CP" => { "flag" => "nao_incide" }, "IRRF" => { "flag" => "nao_incide" } })
			link = RubricIdentityLink.create!(catalog_rubric: rubric, s1010_key: "1|ENORMAL_5610", ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_5610", cod_rubr_normalized: "5610", match_method: "suffix_code", confidence: 0.85, review_status: "matched")

			first_event = S1010Event.create!(source_file: source, nested_zip_path: "2019/mes 01.zip", xml_path: "ID1.S-1010.xml", xml_sha256: "CHAINXML1", event_action: "inclusao", nr_recibo: "1.1.000", ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_5610", cod_rubr_normalized: "5610", dsc_rubr: "ADIANTAMENTO VALE", ini_valid: "2019-01", nat_rubr: "9200", cod_inc_cp: "00", cod_inc_irrf: "00", cod_inc_fgts: "00")
			first_segment = S1010TimelineSegment.create!(source_file: source, s1010_event: first_event, s1010_key: link.s1010_key, ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_5610", cod_rubr_normalized: "5610", dsc_rubr: "ADIANTAMENTO VALE", period_start: "2019-01", period_end: "2019-09", nat_rubr: "9200", cod_inc_cp: "00", cod_inc_irrf: "00", cod_inc_fgts: "00", changed_fields: [])

			second_event = S1010Event.create!(source_file: source, nested_zip_path: "2019/mes 09.zip", xml_path: "ID2.S-1010.xml", xml_sha256: "CHAINXML2", event_action: "alteracao", nr_recibo: "1.1.001", ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_5610", cod_rubr_normalized: "5610", dsc_rubr: "ADIANTAMENTO VALE", ini_valid: "2019-09", nat_rubr: "9200", cod_inc_cp: "00", cod_inc_irrf: "11", cod_inc_fgts: "00")
			second_segment = S1010TimelineSegment.create!(source_file: source, s1010_event: second_event, s1010_key: link.s1010_key, ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_5610", cod_rubr_normalized: "5610", dsc_rubr: "ADIANTAMENTO VALE", period_start: "2019-09", nat_rubr: "9200", cod_inc_cp: "00", cod_inc_irrf: "11", cod_inc_fgts: "00", changed_fields: ["irrf"])

			Finding.create!(catalog_rubric: rubric, expected_mapping: mapping, rubric_identity_link: link, s1010_timeline_segment: first_segment, period_start: "2019-01", period_end: "2019-09", expected_nature_code: "9200", declared_nature_code: "9200", expected_cp_indicator: "nao_incide", declared_cp_code: "00", expected_irrf_indicator: "nao_incide", declared_irrf_code: "00", expected_fgts_indicator: "nao_incide", declared_fgts_code: "00", divergence_kind: "none", divergence_kinds: [], confidence: "aligned", review_status: "aligned")
			Finding.create!(catalog_rubric: rubric, expected_mapping: mapping, rubric_identity_link: link, s1010_timeline_segment: second_segment, period_start: "2019-09", expected_nature_code: "9200", declared_nature_code: "9200", expected_cp_indicator: "nao_incide", declared_cp_code: "00", expected_irrf_indicator: "nao_incide", declared_irrf_code: "11", expected_fgts_indicator: "nao_incide", declared_fgts_code: "00", irrf_divergent: true, divergence_kind: "irrf", divergence_kinds: ["irrf"], confidence: "medium")
		end

		test "renders navigable S1010 chain walk timeline" do
			rubric = CatalogRubric.find_by!(cte_code: "5610")

			get rubricas_cte_root_path(rubric_id: rubric.id)

			assert_response :success
			assert_select "h1", "Rubricas CTE"
			assert_select "body", /Fila de trabalho priorizada/
			assert_select "body", /Dossie da rubrica/
			assert_select "body", /Por que esta na fila/
			assert_select "body", /Linha do tempo S-1010/
			assert_select ".tl-event-rail"
			assert_select "body", /Sem vinculo/
			assert_select "body", /Pontuacao/
			assert_select "body", /Disputa do marco selecionado/
			assert_select "body", /ADIANTAMENTO VALE/
			assert_select "body", /Inclusao/
			assert_select "body", /Alteracao/
			assert_select "body", /2019-01 -> 2019-09/
			assert_select "body", /2019-09 -> vigente/
			assert_select "body", /IRRF/
			assert_select "body", /11 - incide\/base mensal/
			assert_select "body", /Conflito: CTE nao incide; S-1010 incide/
			assert_select "body", /Disputa do marco selecionado/
			assert_select "body", /ID2\.S-1010\.xml/
			assert_select "body", /1\.1\.001/
			assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
		end
	end
end