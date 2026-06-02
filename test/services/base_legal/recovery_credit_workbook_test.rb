require "test_helper"

module BaseLegal
	class RecoveryCreditWorkbookTest < ActiveSupport::TestCase
		test "reads recovery credit legal basis workbook sheets" do
			workbook = RecoveryCreditWorkbook.new
			sheets = workbook.sheets

			assert_equal ["Resumo", "Rubricas", "INSS - FGTS", "IRPF", "FGTS"], sheets.map(&:name)
			assert_equal ["Categoria", "Subcategoria", "Base Legal", "Qtd. Rubricas"], workbook.sheet("Resumo").headers
			assert_equal 9, workbook.sheet("Resumo").row_count
			assert_equal 41, workbook.sheet("Rubricas").row_count
			assert_match(/Art\. 487 CLT/, workbook.sheet("Rubricas").rows.first.values[2])
			assert_equal "5998", workbook.sheet("Rubricas").rows.first.values[3]
		end
	end
end