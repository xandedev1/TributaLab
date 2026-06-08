module RubricasCte
	class TimelineBuilder
		def self.call(source_file: SourceFile.find_by!(kind: "s1010_historico_zip"))
			new(source_file:).call
		end

		def initialize(source_file:)
			@source_file = source_file
		end

		def call
			source_file.s1010_timeline_segments.delete_all

			source_file.s1010_events.ordered.group_by(&:s1010_key).each do |key, events|
				previous_signature = nil
				events.each_with_index do |event, index|
					next_event = events[index + 1]
					signature = signature_for(event)
					S1010TimelineSegment.create!(
						source_file: source_file,
						s1010_event: event,
						s1010_key: key,
						ide_tab_rubr: event.ide_tab_rubr,
						cod_rubr_raw: event.cod_rubr_raw,
						cod_rubr_normalized: event.cod_rubr_normalized,
						dsc_rubr: event.dsc_rubr,
						period_start: event.ini_valid,
						period_end: event.fim_valid.presence || next_event&.ini_valid,
						nat_rubr: event.nat_rubr,
						tp_rubr: event.tp_rubr,
						cod_inc_cp: event.cod_inc_cp,
						cod_inc_irrf: event.cod_inc_irrf,
						cod_inc_fgts: event.cod_inc_fgts,
						previous_signature: previous_signature,
						signature: signature,
						changed_fields: changed_fields(previous_signature, signature)
					)
					previous_signature = signature
				end
			end

			source_file.s1010_timeline_segments.count
		end

		private

		attr_reader :source_file

		def signature_for(event)
			[event.nat_rubr, event.cod_inc_cp, event.cod_inc_irrf, event.cod_inc_fgts].join("|")
		end

		def changed_fields(previous_signature, signature)
			return [] if previous_signature.blank?

			previous = previous_signature.split("|")
			current = signature.split("|")
			%w[nature cp irrf fgts].select.with_index { |_, index| previous[index] != current[index] }
		end
	end
end