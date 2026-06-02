require "test_helper"

module RubricRecovery
	class MarcosTab03WorkbookTest < ActiveSupport::TestCase
		test "reads real Plan1 and tab03 sheets" do
			workbook = MarcosTab03Workbook.new

			assert_equal 464, workbook.events.size
			assert_equal 148, workbook.natures.size
			assert_equal 464, workbook.events.map(&:event_code).uniq.size
			assert_equal 2, workbook.natures.count { |nature| nature.nature_code == "1016" }
			assert_equal 2, workbook.natures.count { |nature| nature.nature_code == "1017" }
			assert_equal "0001", workbook.events.first.event_code
			assert_equal "Salario", workbook.events.first.description
		end
	end
end