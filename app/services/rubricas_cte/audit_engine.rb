module RubricasCte
	class AuditEngine
		def self.call
			new.call
		end

		def call
			Finding.delete_all

			CatalogRubric.includes(:expected_mappings, :rubric_identity_link).find_each do |rubric|
				link = rubric.rubric_identity_link
				if link&.linked?
					S1010TimelineSegment.where(s1010_key: link.s1010_key).ordered.each do |segment|
						mapping = expected_mapping_for(rubric, segment)
						create_finding!(rubric, link, segment, mapping)
					end
				else
					create_unlinked_finding!(rubric, link)
				end
			end
		end

		private

		def expected_mapping_for(rubric, segment)
			nonzero = rubric.expected_mappings.select(&:nonzero_esocial?)
			active = nonzero.select { |mapping| mapping.active_for_period?(segment.period_start) }
			active.first || nonzero.first || rubric.expected_mappings.first
		end

		def create_finding!(rubric, link, segment, mapping)
			kinds = divergence_kinds(mapping, segment)
			Finding.create!(
				catalog_rubric: rubric,
				expected_mapping: mapping,
				rubric_identity_link: link,
				s1010_timeline_segment: segment,
				period_start: segment.period_start,
				period_end: segment.period_end,
				expected_nature_code: mapping&.esocial_nature_code,
				declared_nature_code: segment.nat_rubr,
				expected_cp_indicator: expected_flag(mapping, "CP"),
				declared_cp_code: segment.cod_inc_cp,
				expected_irrf_indicator: expected_flag(mapping, "IRRF"),
				declared_irrf_code: segment.cod_inc_irrf,
				expected_fgts_indicator: expected_flag(mapping, "FGTS"),
				declared_fgts_code: segment.cod_inc_fgts,
				nature_divergent: kinds.include?("nature"),
				cp_divergent: kinds.include?("cp"),
				irrf_divergent: kinds.include?("irrf"),
				fgts_divergent: kinds.include?("fgts"),
				divergence_kind: kinds.first || "none",
				divergence_kinds: kinds,
				confidence: confidence_for(kinds, link),
				evidence_json: evidence_for(mapping, segment, link),
				review_status: kinds.any? ? "pending" : "aligned"
			)
		end

		def create_unlinked_finding!(rubric, link)
			mapping = rubric.expected_mappings.find(&:nonzero_esocial?) || rubric.expected_mappings.first
			Finding.create!(
				catalog_rubric: rubric,
				expected_mapping: mapping,
				rubric_identity_link: link,
				expected_nature_code: mapping&.esocial_nature_code,
				expected_cp_indicator: expected_flag(mapping, "CP"),
				expected_irrf_indicator: expected_flag(mapping, "IRRF"),
				expected_fgts_indicator: expected_flag(mapping, "FGTS"),
				divergence_kind: "not_evaluated",
				divergence_kinds: ["not_evaluated"],
				confidence: "needs_review",
				evidence_json: { "reason" => "Rubrica CTE sem vinculo unico com S-1010 nesta etapa." },
				review_status: "pending"
			)
		end

		def divergence_kinds(mapping, segment)
			return ["not_evaluated"] unless mapping && segment

			kinds = []
			kinds << "nature" if nature_divergent?(mapping, segment)
			kinds << "cp" if incidence_divergent?(expected_flag(mapping, "CP"), segment.cod_inc_cp)
			kinds << "irrf" if incidence_divergent?(expected_flag(mapping, "IRRF"), segment.cod_inc_irrf)
			kinds << "fgts" if incidence_divergent?(expected_flag(mapping, "FGTS"), segment.cod_inc_fgts)
			kinds
		end

		def nature_divergent?(mapping, segment)
			mapping.nonzero_esocial? && segment.nat_rubr.present? && mapping.esocial_nature_code != segment.nat_rubr
		end

		def incidence_divergent?(expected, declared_code)
			return false if expected == "unknown"

			declared = IncidenceClassifier.declared_flag(declared_code)
			return false if declared == "unknown"

			expected != declared
		end

		def expected_flag(mapping, tax_kind)
			mapping&.incidence_profile&.dig(tax_kind, "flag") || "unknown"
		end

		def confidence_for(kinds, link)
			return "aligned" if kinds.empty?
			return "needs_review" if kinds.include?("not_evaluated")

			link&.match_method == "suffix_code" ? "medium" : "needs_review"
		end

		def evidence_for(mapping, segment, link)
			{
				"expected_source_row" => mapping&.source_row,
				"s1010_key" => segment&.s1010_key,
				"xml_path" => segment&.s1010_event&.xml_path,
				"nested_zip_path" => segment&.s1010_event&.nested_zip_path,
				"match_method" => link&.match_method
			}
		end
	end
end