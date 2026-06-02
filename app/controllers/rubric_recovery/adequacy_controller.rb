module RubricRecovery
	class AdequacyController < ApplicationController
		before_action :ensure_adequacy_data!

		def index
			@query = params[:q].to_s.strip
			@status = params[:status].to_s.strip
			@events = filtered_events
			@metrics = build_metrics
		end

		def show
			@event = event_scope.find(params[:rubric_event_id])
			@assignment = @event.rubric_nature_assignment
			@suggestions = @event.rubric_nature_suggestions.includes(:esocial_nature).order(:rank)
		end

		private

		def ensure_adequacy_data!
			RubricRecovery::AdequacyImporter.ensure_loaded!
		end

		def event_scope
			RubricEvent.includes(:rubric_company, :rubric_nature_assignment, rubric_nature_suggestions: :esocial_nature).ordered
		end

		def filtered_events
			events = event_scope.to_a
			events = events.select { |event| event.event_code.include?(@query) || event.description.downcase.include?(@query.downcase) } if @query.present?
			events = events.select { |event| event.adequacy_status == @status } if @status.present?
			events
		end

		def build_metrics
			all_events = event_scope.to_a
			[
				{ label: "Eventos CTE", value: all_events.size, detail: "linhas reais da Plan1" },
				{ label: "Naturezas tab03", value: EsocialNature.count, detail: "linhas preservando vigencia" },
				{ label: "Sugestoes geradas", value: RubricNatureSuggestion.count, detail: "top 10 por rubrica" },
				{ label: "Selecionadas", value: RubricNatureAssignment.where.not(esocial_nature_id: nil).count, detail: "com natureza escolhida" },
				{ label: "Ambiguas", value: all_events.count(&:ambiguous_suggestions?), detail: "empate material no topo" }
			]
		end
	end
end