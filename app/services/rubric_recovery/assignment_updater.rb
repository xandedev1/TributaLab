module RubricRecovery
	class AssignmentUpdater
		INCIDENCE_KEYS = %w[selected_cod_inc_cp selected_cod_inc_irrf selected_cod_inc_fgts status].freeze

		def initialize(assignment, attributes, changed_by: "sistema")
			@assignment = assignment
			@attributes = attributes.to_h.stringify_keys
			@changed_by = changed_by
		end

		def call
			previous_values = assignment.incidence_snapshot
			requested_values = attributes.slice(*INCIDENCE_KEYS, "justification")
			changed_incidence = incidence_changed?(previous_values, requested_values)
			justification = requested_values["justification"].to_s.strip

			raise ArgumentError, "Informe uma justificativa para alterar CP/IRRF/FGTS." if changed_incidence && justification.blank?

			assignment.assign_attributes(requested_values.except("justification"))
			assignment.justification = justification if justification.present?
			refresh_override_flags
			assignment.save!

			new_values = assignment.incidence_snapshot
			if previous_values != new_values
				assignment.rubric_nature_assignment_versions.create!(
					previous_values: previous_values,
					new_values: new_values,
					reason: justification.presence || "Atualizacao de status sem alteracao de incidencia.",
					changed_by: changed_by
				)
			end

			assignment
		end

		private

		attr_reader :assignment, :attributes, :changed_by

		def incidence_changed?(previous_values, requested_values)
			%w[selected_cod_inc_cp selected_cod_inc_irrf selected_cod_inc_fgts].any? do |key|
				requested_values.key?(key) && previous_values[key].to_s != requested_values[key].to_s
			end
		end

		def refresh_override_flags
			return unless assignment.esocial_nature

			assignment.override_cp = assignment.selected_cod_inc_cp.to_s != assignment.esocial_nature.cod_inc_cp.to_s
			assignment.override_irrf = assignment.selected_cod_inc_irrf.to_s != assignment.esocial_nature.cod_inc_irrf.to_s
			assignment.override_fgts = assignment.selected_cod_inc_fgts.to_s != assignment.esocial_nature.cod_inc_fgts.to_s
		end
	end
end