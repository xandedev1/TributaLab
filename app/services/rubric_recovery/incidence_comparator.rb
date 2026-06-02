module RubricRecovery
	class IncidenceComparator
		NON_TAXABLE_CODES = {
			cp: %w[0 00],
			irrf: %w[0 00 9 09],
			fgts: %w[0 00]
		}.freeze

		def self.status(indicator, code, tax)
			new.status(indicator, code, tax)
		end

		def self.alignment(indicator, code, tax)
			new.alignment(indicator, code, tax)
		end

		def status(indicator, code, tax)
			comparison = alignment(indicator, code, tax)
			return "Neutro" if comparison[:neutral]

			comparison[:matches] ? "OK" : "Divergente"
		end

		def alignment(indicator, code, tax)
			expected = expected_taxable(indicator)
			return { expected: nil, actual: taxable?(code, tax), matches: false, neutral: true, score: 0.25 } if expected.nil?

			actual = taxable?(code, tax)
			matches = expected == actual
			{ expected: expected, actual: actual, matches: matches, neutral: false, score: matches ? 0.5 : 0.0 }
		end

		private

		def expected_taxable(indicator)
			case indicator.to_s.strip
			when "+"
				true
			when "N"
				false
			else
				nil
			end
		end

		def taxable?(code, tax)
			clean_code = code.to_s.strip.sub(/\A0+/, "")
			clean_code = "0" if clean_code.blank?
			!NON_TAXABLE_CODES.fetch(tax).include?(clean_code)
		end
	end
end