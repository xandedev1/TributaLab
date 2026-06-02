require "test_helper"

module RubricRecovery
	class AdequacyControllerTest < ActionDispatch::IntegrationTest
		setup do
			RubricNatureAssignmentVersion.delete_all
			RubricNatureAssignment.delete_all
			RubricNatureSuggestion.delete_all
			RubricEvent.delete_all
			EsocialNature.delete_all
			RubricCompany.delete_all
		end

		test "renders adequacy scoring page" do
			get rubric_recovery_adequacy_path

			assert_response :success
			assert_select "h1", "Pontuacao de Naturezas"
			assert_select "body", /464/
			assert_select "body", /Salario/
			assert_select "body", /1000 - Salário, vencimento, soldo/
			assert_no_match(/R\$|valor a restituir|credito recuperavel/i, response.body)
		end

		test "selects nature and updates incidences with history" do
			get rubric_recovery_adequacy_path
			event = RubricEvent.find_by!(event_code: "0271")
			suggestion = event.rubric_nature_suggestions.first

			post rubric_recovery_adequacy_assignments_path(event), params: { esocial_nature_id: suggestion.esocial_nature_id, justification: "Selecao inicial validada." }

			assert_redirected_to rubric_recovery_adequacy_event_path(event)
			assignment = event.reload.rubric_nature_assignment
			assert_equal "selected", assignment.status
			assert_equal suggestion.esocial_nature, assignment.esocial_nature

			get rubric_recovery_rubrics_natures_path
			assert_response :success
			assert_select "body", /Bolsa Estagio/

			patch rubric_recovery_rubrics_nature_path(assignment), params: {
				assignment: {
					selected_cod_inc_cp: "11",
					selected_cod_inc_irrf: assignment.selected_cod_inc_irrf,
					selected_cod_inc_fgts: assignment.selected_cod_inc_fgts,
					status: "reviewed",
					justification: "Ajuste validado pela revisao tecnica."
				}
			}

			assert_redirected_to rubric_recovery_rubrics_natures_path
			assert_equal "11", assignment.reload.selected_cod_inc_cp
			assert_equal "reviewed", assignment.status
			assert_operator assignment.rubric_nature_assignment_versions.count, :>=, 1
			assert_match(/Ajuste validado/, assignment.rubric_nature_assignment_versions.order(:created_at).last.reason)
		end
	end
end