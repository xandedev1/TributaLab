module RubricasCte
	class NaturezaEsocialImporter
		SOURCE_REPO_PATH = "docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/natureza_esocial_por_rubrica_cte.xlsx".freeze

		def self.call
			new.call
		end

		def initialize(workbook: NaturezaEsocialWorkbook.new)
			@workbook = workbook
		end

		def call
			source_file = SourceFileRegistry.find_or_create!(
				kind: "natureza_esocial_rubrica_cte",
				repo_path: SOURCE_REPO_PATH,
				original_path: "C:/Users/xandao/Downloads/Natureza E-Social por Rubrica CTE.xlsx",
				notes: "Fonte primaria rubrica CTE -> natureza eSocial pela coluna eSoc."
			)

			ActiveRecord::Base.transaction do
				Finding.delete_all
				RubricIdentityLink.delete_all
				source_file.catalog_rubrics.destroy_all

				run = source_file.import_runs.create!(kind: "natureza_esocial", started_at: Time.current)
				rows = workbook.rows
				catalog = {}
				incidence_rows = []

				rows.each do |row|
					key = row.cte_code
					rubric = catalog[key] ||= CatalogRubric.create!(
						source_file: source_file,
						table_code: row.table_code,
						cte_code: row.cte_code,
						description: row.description,
						normalized_description: RubricRecovery::TextNormalizer.normalize(row.description),
						first_source_row: row.source_row,
						last_source_row: row.source_row,
						source_rows_count: 0,
						active_from: row.inicio,
						active_to: row.fim
					)

					update_catalog_span!(rubric, row)
					mapping = create_mapping!(rubric, source_file, row)
					incidence_rows.concat(expected_incidence_rows(mapping, row))
				end

				ExpectedIncidence.insert_all(incidence_rows) if incidence_rows.any?

				run.update!(
					status: "completed",
					finished_at: Time.current,
					rows_read: rows.size,
					rows_written: ExpectedMapping.where(source_file: source_file).count,
					stats: {
						catalog_rubrics: CatalogRubric.where(source_file: source_file).count,
						mappings_with_esoc: ExpectedMapping.where(source_file: source_file).nonzero_esocial.count,
						mappings_zero_esoc: ExpectedMapping.where(source_file: source_file, esocial_nature_code: "0").count
					}
				)
				source_file.update!(loaded_at: Time.current)
			end

			source_file
		end

		private

		attr_reader :workbook

		def update_catalog_span!(rubric, row)
			rubric.update!(
				last_source_row: [rubric.last_source_row.to_i, row.source_row].max,
				source_rows_count: rubric.source_rows_count + 1,
				active_from: [rubric.active_from, row.inicio].compact.reject(&:blank?).min,
				active_to: [rubric.active_to, row.fim].compact.reject(&:blank?).max
			)
		end

		def create_mapping!(rubric, source_file, row)
			profile = IncidenceClassifier.profile(row)
			ExpectedMapping.create!(
				catalog_rubric: rubric,
				source_file: source_file,
				source_sheet: row.source_sheet,
				source_row: row.source_row,
				esocial_nature_code: row.esocial_nature_code.presence || "0",
				car: row.car,
				tp: row.tp,
				cmp_inc: row.cmp_inc,
				seq: row.seq,
				fn: row.fn,
				fd: row.fd,
				fni: row.fni,
				fdi: row.fdi,
				inm: row.inm,
				ind: row.ind,
				ina: row.ina,
				irr: row.irr,
				irm: row.irm,
				irf: row.irf,
				ird: row.ird,
				ir: row.ir,
				ira: row.ira,
				pis: row.pis,
				pid: row.pid,
				ipm: row.ipm,
				ipd: row.ipd,
				ipf: row.ipf,
				rp: row.rp,
				tr: row.tr,
				rem: row.rem,
				vinculo: row.vinculo,
				inicio: row.inicio,
				fim: row.fim,
				incidence_profile: profile,
				raw_values: row.raw_values
			)
		end

		def expected_incidence_rows(mapping, row)
			now = Time.current
			IncidenceClassifier::COLUMN_GROUPS.flat_map do |tax_kind, columns|
				columns.map do |column|
					raw_value = row.public_send(column)
					{
						expected_mapping_id: mapping.id,
						tax_kind: tax_kind,
						indicator_code: column.to_s,
						raw_value: raw_value,
						expected_flag: IncidenceClassifier.expected_flag([raw_value]),
						created_at: now,
						updated_at: now
					}
				end
			end
		end
	end
end