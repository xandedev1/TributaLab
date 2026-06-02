module RubricRecovery
	class AdequacyAssignmentsController < ApplicationController
		before_action :ensure_adequacy_data!

		def create
			@event = RubricEvent.includes(:rubric_nature_assignment, rubric_nature_suggestions: :esocial_nature).find(params[:rubric_event_id])
			assignment = @event.rubric_nature_assignment || @event.build_rubric_nature_assignment
			previous_values = assignment.persisted? ? assignment.incidence_snapshot : {}

			if params[:assignment_action] == "ambiguous"
				assignment.assign_attributes(esocial_nature: nil, selected_score: nil, selection_origin: "manual", status: "ambiguous", justification: assignment_params[:justification].presence)
			else
				suggestion = @event.rubric_nature_suggestions.find_by!(esocial_nature_id: assignment_params[:esocial_nature_id])
				nature = suggestion.esocial_nature
				assignment.assign_attributes(
					esocial_nature: nature,
					selected_score: suggestion.score,
					selection_origin: "suggested",
					selected_cod_inc_cp: nature.cod_inc_cp,
					selected_cod_inc_irrf: nature.cod_inc_irrf,
					selected_cod_inc_fgts: nature.cod_inc_fgts,
					status: "selected",
					justification: assignment_params[:justification].presence
				)
			end

			assignment.save!
			assignment.rubric_nature_assignment_versions.create!(
				previous_values: previous_values,
				new_values: assignment.incidence_snapshot,
				reason: assignment.justification.presence || "Natureza selecionada pela tela de pontuacao.",
				changed_by: "usuario"
			)

			redirect_to rubric_recovery_adequacy_event_path(@event), notice: "Atribuicao de natureza registrada."
		rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
			redirect_to rubric_recovery_adequacy_event_path(@event || params[:rubric_event_id]), alert: error.message
		end

		private

		def ensure_adequacy_data!
			RubricRecovery::AdequacyImporter.ensure_loaded!
		end

		def assignment_params
			params.permit(:esocial_nature_id, :justification)
		end
	end
end