require "test_helper"

module RubricasCte
	class PipelineTest < ActiveSupport::TestCase
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
		end

		test "imports local CTE workbook and S1010 ZIP then generates initial findings" do
			Pipeline.refresh!

			assert_equal 469, CatalogRubric.count
			assert_equal 219, CatalogRubric.joins(:expected_mappings).merge(ExpectedMapping.nonzero_esocial).distinct.count
			assert_equal 389, ExpectedMapping.nonzero_esocial.count
			assert_operator ExpectedIncidence.count, :>, 10_000

			assert_equal 2_031, S1010Event.count
			assert_equal 2_031, S1010TimelineSegment.count
			assert_equal 469, RubricIdentityLink.count
			assert_operator RubricIdentityLink.where(review_status: "matched").count, :>, 0
			assert_operator Finding.count, :>, 0
			assert_operator Finding.where(divergence_kind: "nature").or(Finding.where(nature_divergent: true)).count, :>, 0
			assert_operator Finding.where(cp_divergent: true).or(Finding.where(irrf_divergent: true)).or(Finding.where(fgts_divergent: true)).count, :>=, 0

			event = S1010Event.find_by!(cod_rubr_raw: "ENORMAL_5792")
			assert_equal "5792", event.cod_rubr_normalized
			assert_equal "9230", event.nat_rubr
			assert_equal "00", event.cod_inc_cp
			assert_equal "00", event.cod_inc_irrf
			assert_equal "00", event.cod_inc_fgts
		end
	end
end