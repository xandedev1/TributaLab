require "test_helper"

module RubricasCte
	class DashboardControllerTest < ActionDispatch::IntegrationTest
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

			source = SourceFile.create!(kind: "test", repo_path: "test.xlsx", sha256: "DASHBOARDTEST")
			rubric = CatalogRubric.create!(source_file: source, table_code: "001", cte_code: "0609", description: "1/3 Abono Pecuniario Fer", normalized_description: "1/3 abono pecuniario fer", first_source_row: 6, last_source_row: 6, source_rows_count: 1)
			mapping = ExpectedMapping.create!(catalog_rubric: rubric, source_file: source, source_sheet: "Plan1", source_row: 6, esocial_nature_code: "1023", fn: "N", inm: "N", irm: "N", incidence_profile: { "FGTS" => { "flag" => "nao_incide" }, "CP" => { "flag" => "nao_incide" }, "IRRF" => { "flag" => "nao_incide" } })
			ExpectedIncidence.create!(expected_mapping: mapping, tax_kind: "CP", indicator_code: "inm", raw_value: "N", expected_flag: "nao_incide")
			event = S1010Event.create!(source_file: source, xml_path: "sample.xml", xml_sha256: "XMLDASHBOARDTEST", ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_0609", cod_rubr_normalized: "0609", dsc_rubr: "1/3 Abono Pecuniario Fer", ini_valid: "2018-07", nat_rubr: "1023", cod_inc_cp: "11", cod_inc_irrf: "00", cod_inc_fgts: "00")
			segment = S1010TimelineSegment.create!(source_file: source, s1010_event: event, s1010_key: event.s1010_key, ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_0609", cod_rubr_normalized: "0609", dsc_rubr: event.dsc_rubr, period_start: "2018-07", nat_rubr: "1023", cod_inc_cp: "11", cod_inc_irrf: "00", cod_inc_fgts: "00")
			link = RubricIdentityLink.create!(catalog_rubric: rubric, s1010_key: event.s1010_key, ide_tab_rubr: "1", cod_rubr_raw: "ENORMAL_0609", cod_rubr_normalized: "0609", match_method: "suffix_code", confidence: 0.85, review_status: "matched")
			Finding.create!(catalog_rubric: rubric, expected_mapping: mapping, rubric_identity_link: link, s1010_timeline_segment: segment, period_start: "2018-07", expected_nature_code: "1023", declared_nature_code: "1023", expected_cp_indicator: "nao_incide", declared_cp_code: "11", expected_irrf_indicator: "nao_incide", declared_irrf_code: "00", expected_fgts_indicator: "nao_incide", declared_fgts_code: "00", cp_divergent: true, divergence_kind: "cp", divergence_kinds: ["cp"], confidence: "medium")
		end

		test "redirects legacy dashboard to unified rubricas cte product" do
			get rubricas_cte_dashboard_path

			assert_redirected_to rubricas_cte_root_path(q: nil, status: nil)
		end
	end
end