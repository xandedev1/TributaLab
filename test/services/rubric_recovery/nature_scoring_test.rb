require "test_helper"

module RubricRecovery
	class NatureScoringTest < ActiveSupport::TestCase
		setup do
			RubricNatureAssignmentVersion.delete_all
			RubricNatureAssignment.delete_all
			RubricNatureSuggestion.delete_all
			RubricEvent.delete_all
			EsocialNature.delete_all
			RubricCompany.delete_all
			AdequacyImporter.new.call
		end

		test "imports events natures and top ten suggestions" do
			assert_equal 464, RubricEvent.count
			assert_equal 148, EsocialNature.count
			assert_equal 4_640, RubricNatureSuggestion.count
			assert_equal 10, RubricEvent.find_by!(event_code: "0001").rubric_nature_suggestions.count
		end

		test "ranks required examples deterministically" do
			assert_equal "1000", top_nature_code("0001")
			assert_equal "1350", top_nature_code("0271")
			assert_equal "1017", top_nature_code("0558")
			assert_includes %w[1016 1020], top_nature_code("0005")
			assert_equal "6003", top_nature_code("0950")
			assert_equal "1202", top_nature_code("1951")
			assert_equal "1203", top_nature_code("1952")
		end

		test "creates assignment and audits incidence update" do
			event = RubricEvent.find_by!(event_code: "0271")
			suggestion = event.rubric_nature_suggestions.first
			assignment = event.create_rubric_nature_assignment!(
				esocial_nature: suggestion.esocial_nature,
				selected_score: suggestion.score,
				selection_origin: "suggested",
				status: "selected"
			)

			assert_raises(ArgumentError) do
				AssignmentUpdater.new(assignment, { selected_cod_inc_cp: "11", selected_cod_inc_irrf: assignment.selected_cod_inc_irrf, selected_cod_inc_fgts: assignment.selected_cod_inc_fgts }).call
			end

			AssignmentUpdater.new(
				assignment,
				{ selected_cod_inc_cp: "11", selected_cod_inc_irrf: assignment.selected_cod_inc_irrf, selected_cod_inc_fgts: assignment.selected_cod_inc_fgts, justification: "Revisao tecnica da incidencia CP." }
			).call

			assert_equal "11", assignment.reload.selected_cod_inc_cp
			assert assignment.override_cp
			assert_equal 1, assignment.rubric_nature_assignment_versions.count
		end

		private

		def top_nature_code(event_code)
			RubricEvent.find_by!(event_code: event_code).rubric_nature_suggestions.first.esocial_nature.nature_code
		end
	end
end