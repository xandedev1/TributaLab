module RubricasCte
	class IncidenceClassifier
		FGTS_COLUMNS = %i[fn fd fni fdi].freeze
		CP_COLUMNS = %i[inm ind ina].freeze
		IRRF_COLUMNS = %i[irm irf ird ir ira].freeze

		COLUMN_GROUPS = {
			"FGTS" => FGTS_COLUMNS,
			"CP" => CP_COLUMNS,
			"IRRF" => IRRF_COLUMNS
		}.freeze

		def self.profile(row)
			new(row).profile
		end

		def self.expected_flag(values)
			normalized = values.map { |value| value.to_s.strip.upcase }.reject(&:blank?)
			return "unknown" if normalized.empty?
			return "incide" if normalized.include?("+")
			return "nao_incide" if normalized.all? { |value| value == "N" || value == "0" }

			"unknown"
		end

		def self.declared_flag(code)
			value = code.to_s.strip
			return "unknown" if value.blank?
			return "nao_incide" if value == "00" || value == "0"

			"incide"
		end

		def initialize(row)
			@row = row
		end

		def profile
			COLUMN_GROUPS.transform_values do |columns|
				values = columns.to_h { |column| [column.to_s, row.public_send(column)] }
				{
					"flag" => self.class.expected_flag(values.values),
					"values" => values
				}
			end
		end

		private

		attr_reader :row
	end
end