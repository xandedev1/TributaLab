module RubricRecovery
	class AdequacyImporter
		COMPANY_REFERENCE = "CTE".freeze
		COMPANY_NAME = "CTE CENTRO DE TECNOLOGIA EDI.E HOL. LTDA".freeze

		def self.ensure_loaded!
			new.ensure_loaded!
		end

		def initialize(workbook: MarcosTab03Workbook.new, builder: NatureSuggestionBuilder.new)
			@workbook = workbook
			@builder = builder
		end

		def ensure_loaded!
			return if loaded?

			call
		end

		def call
			ActiveRecord::Base.transaction do
				company = import_company
				events = import_events(company)
				natures = import_natures
				regenerate_suggestions(events, natures)
			end
		end

		private

		attr_reader :workbook, :builder

		def loaded?
			events_count = RubricEvent.where(source_file_hash: MarcosTab03Workbook::SOURCE_HASH).count
			natures_count = EsocialNature.where(source_file_hash: MarcosTab03Workbook::SOURCE_HASH).count
			suggestions_count = RubricNatureSuggestion.joins(:rubric_event)
				.where(rubric_events: { source_file_hash: MarcosTab03Workbook::SOURCE_HASH })
				.where(algorithm_version: NatureScorer::VERSION)
				.count

			events_count == 464 && natures_count == 148 && suggestions_count == 4_640
		end

		def import_company
			company = RubricCompany.find_or_initialize_by(reference_code: COMPANY_REFERENCE)
			company.update!(name: COMPANY_NAME, notes: "Fonte inicial da etapa MD 006 - Adequacao S-1010 via Pontuacao.")
			company
		end

		def import_events(company)
			workbook.events.map do |row|
				event = RubricEvent.find_or_initialize_by(rubric_company: company, event_code: row.event_code)
				event.update!(
					source_file_hash: MarcosTab03Workbook::SOURCE_HASH,
					source_sheet: "Plan1",
					source_row: row.source_row,
					table_code: row.table_code,
					description: row.description,
					car: row.car,
					reg: row.reg,
					tp: row.tp,
					nt: row.nt,
					sl: row.sl,
					rub: row.rub,
					br: row.br,
					fn: row.fn,
					fd: row.fd,
					fni: row.fni,
					fdi: row.fdi,
					inm: row.inm,
					ind: row.ind,
					irm: row.irm,
					irf: row.irf,
					ird: row.ird,
					ir: row.ir,
					normalized_description: TextNormalizer.normalize(row.description)
				)
				event
			end
		end

		def import_natures
			workbook.natures.map do |row|
				nature = EsocialNature.find_or_initialize_by(source_file_hash: MarcosTab03Workbook::SOURCE_HASH, source_row: row.source_row)
				nature.update!(
					source_sheet: "tab03",
					nature_code: row.nature_code,
					name: row.name,
					normalized_name: TextNormalizer.normalize(row.normalized_name.presence || row.name),
					valid_from: row.valid_from,
					valid_to: row.valid_to,
					description: row.description,
					exclusive_employee_incidence: row.exclusive_employee_incidence,
					cod_inc_cp: row.cod_inc_cp,
					cod_inc_irrf: row.cod_inc_irrf,
					cod_inc_fgts: row.cod_inc_fgts,
					suggested_cp: row.suggested_cp,
					suggested_irrf: row.suggested_irrf,
					suggested_fgts: row.suggested_fgts,
					reason_source: row.reason_source
				)
				nature
			end
		end

		def regenerate_suggestions(events, natures)
			RubricNatureSuggestion.where(rubric_event: events).delete_all

			events.each do |event|
				builder.top_for(event, natures).each do |candidate|
					result = candidate.fetch(:result)
					RubricNatureSuggestion.create!(
						rubric_event: event,
						esocial_nature: candidate.fetch(:nature),
						rank: candidate.fetch(:rank),
						score: result.score,
						confidence_label: result.confidence_label,
						positive_signals: result.positive_signals,
						penalties: result.penalties,
						incidence_alignment: result.incidence_alignment,
						algorithm_version: NatureScorer::VERSION
					)
				end
			end
		end
	end
end