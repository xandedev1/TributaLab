module RubricasCte
	class IdentityMatcher
		def self.call
			new.call
		end

		def call
			RubricIdentityLink.delete_all
			segments_by_code = S1010TimelineSegment.all.group_by(&:cod_rubr_normalized)
			segments_by_description = S1010TimelineSegment.all.group_by { |segment| RubricRecovery::TextNormalizer.normalize(segment.dsc_rubr) }

			CatalogRubric.ordered.find_each do |rubric|
				candidates = unique_candidates(segments_by_code[rubric.cte_code])
				method = "suffix_code"

				if candidates.blank?
					candidates = unique_candidates(segments_by_description[rubric.normalized_description])
					method = "description"
				end

				create_link!(rubric, candidates, method)
			end
		end

		private

		def unique_candidates(segments)
			Array(segments).group_by(&:s1010_key).values.map(&:first)
		end

		def create_link!(rubric, candidates, method)
			if candidates.one?
				candidate = candidates.first
				rubric.create_rubric_identity_link!(
					s1010_key: candidate.s1010_key,
					ide_tab_rubr: candidate.ide_tab_rubr,
					cod_rubr_raw: candidate.cod_rubr_raw,
					cod_rubr_normalized: candidate.cod_rubr_normalized,
					match_method: method,
					confidence: method == "suffix_code" ? 0.85 : 0.65,
					review_status: "matched",
					candidates: [candidate_payload(candidate)]
				)
			else
				rubric.create_rubric_identity_link!(
					match_method: candidates.any? ? "ambiguous" : "unmatched",
					confidence: 0,
					review_status: candidates.any? ? "ambiguous" : "unmatched",
					candidates: candidates.first(8).map { |candidate| candidate_payload(candidate) }
				)
			end
		end

		def candidate_payload(candidate)
			{
				"s1010_key" => candidate.s1010_key,
				"cod_rubr_raw" => candidate.cod_rubr_raw,
				"description" => candidate.dsc_rubr,
				"nat_rubr" => candidate.nat_rubr
			}
		end
	end
end