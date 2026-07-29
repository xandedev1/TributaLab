require "test_helper"
require "tmpdir"

module Esocial
	class FpasThirdPartyTableParserTest < ActiveSupport::TestCase
		test "normalizes the official table while preserving codes with leading zeros" do
			Dir.mktmpdir do |dir|
				source_path = File.join(dir, "TABELA4.csv")
				output_dir = File.join(dir, "output")

				File.write(source_path, <<~CSV)
					CODFPAS|INDCOOP|DtInicio|DtFim|CLASSTRIB|CODTERC|ALIQTERC
					515|0;Nulo|01012014|||0001|2,5
					744||01012014|31122025|06|0512|0,2
				CSV

				result = FpasThirdPartyTableParser.call(source_path:, output_dir:)
				first_row, second_row = result.rows

				assert_equal 2, result.rows.size
				assert_equal "0001", first_row.third_party_code
				assert_equal "2.5", first_row.third_party_rate
				assert_equal "2014-01-01", first_row.valid_from
				assert_nil first_row.valid_to
				assert_equal "06", second_row.tax_classification_code
				assert_equal "0512", second_row.third_party_code
				assert_equal "2025-12-31", second_row.valid_to

				postgres_csv = File.read(result.output_paths.fetch(:postgres_csv))
				markdown = File.read(result.output_paths.fetch(:markdown))

				assert_includes postgres_csv, "515,0;Nulo,2014-01-01,,,0001,2.5"
				assert_includes markdown, "## FPAS 515"
				assert_includes markdown, "| 0;Nulo | 2014-01-01 | — | — | `0001` | 2,5 |"
				assert_equal 2, result.metadata.fetch(:rows)
			end
		end
	end
end