module RubricRecovery
	class NatureSuggestionBuilder
		def initialize(scorer: NatureScorer.new, normalizer: TextNormalizer.new)
			@scorer = scorer
			@normalizer = normalizer
		end

		def top_for(event, natures, limit: 10)
			natures.map do |nature|
				result = scorer.call(event, nature)
				{ nature: nature, result: result, specificity: specificity(nature) }
			end.sort_by do |candidate|
				[-candidate[:result].score, -candidate[:specificity], candidate[:nature].nature_code.to_s, candidate[:nature].source_row.to_i]
			end.first(limit).each_with_index.map do |candidate, index|
				candidate.merge(rank: index + 1)
			end
		end

		private

		attr_reader :scorer, :normalizer

		def specificity(nature)
			normalizer.domain_terms([nature.name, nature.description].join(" ")).size
		end
	end
end