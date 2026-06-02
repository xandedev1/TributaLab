module RubricRecovery
	class RubricsNaturesController < ApplicationController
		before_action :ensure_adequacy_data!

		def index
			@assignments = RubricNatureAssignment
				.includes(:esocial_nature, :rubric_nature_assignment_versions, rubric_event: :rubric_company)
				.where.not(esocial_nature_id: nil)
				.joins(:rubric_event)
				.order("rubric_events.event_code ASC")
		end

		def update
			assignment = RubricNatureAssignment.find(params[:assignment_id])
			RubricRecovery::AssignmentUpdater.new(assignment, update_params, changed_by: "usuario").call

			redirect_to rubric_recovery_rubrics_natures_path, notice: "Incidencias atualizadas com historico."
		rescue ActiveRecord::RecordInvalid, ArgumentError => error
			redirect_to rubric_recovery_rubrics_natures_path, alert: error.message
		end

		private

		def ensure_adequacy_data!
			RubricRecovery::AdequacyImporter.ensure_loaded!
		end

		def update_params
			params.require(:assignment).permit(:selected_cod_inc_cp, :selected_cod_inc_irrf, :selected_cod_inc_fgts, :status, :justification)
		end
	end
end