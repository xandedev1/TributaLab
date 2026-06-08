require "test_helper"

module RubricasCte
	class NaturezaEsocialWorkbookTest < ActiveSupport::TestCase
		test "reads CTE nature workbook preserving inherited rubric rows and incidences" do
			rows = NaturezaEsocialWorkbook.new.rows

			assert_operator rows.size, :>, 1_500
			assert_equal 6, rows.first.source_row
			assert_equal "001", rows.first.table_code
			assert_equal "0609", rows.first.cte_code
			assert_equal "1023", rows.first.esocial_nature_code
			assert_equal "N", rows.first.fn
			assert_equal "N", rows.first.inm

			continuation = rows.find { |row| row.source_row == 9 }
			assert_equal "0558", continuation.cte_code
			assert_equal "1/3 Ferias", I18n.transliterate(continuation.description)
			assert_equal "1017", continuation.esocial_nature_code
			assert_equal "+", continuation.fn
			assert_equal "+", continuation.inm
		end
	end
end