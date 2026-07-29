require "test_helper"

module FiscalAuditor
  class PayrollChargesDashboardTest < ActiveSupport::TestCase
    test "reads INSS and the final liquid FGTS totalizers" do
      dashboard = PayrollChargesDashboard.new

      assert_equal 14, PayrollChargesDashboard.source_paths.size
      assert_equal 12, dashboard.rows.size
      assert_equal 6_642_769.31.to_d, dashboard.rows.first[:inss_gross].round(2)
      assert_equal 1_905_232.32.to_d, dashboard.rows.first[:fgts_to_add].round(2)

      september = dashboard.fgts_components("2025-09").sole
      assert_equal 1_389_102.37.to_d, september.amount.round(2)
      assert_equal 284, september.source_row
      assert_equal "Q281-Q283", september.formula
    end

    test "deducts payroll INSS events before adding INSS and FGTS" do
      dashboard = PayrollChargesDashboard.new
      january = dashboard.rows.first

      assert_equal 1_935_750.17.to_d, january[:inss_discounts].round(2)
      assert_equal(
        january[:inss_gross] - january[:inss_discounts],
        january[:inss_to_add]
      )
      assert_equal(
        january[:payroll_net] + january[:inss_to_add] + january[:fgts_to_add],
        january[:adjusted_payroll]
      )
      assert_equal %w[566 596 641 757], dashboard.discount_components("2025-01").map { |component| component[:code] }
    end

    test "adds the thirteenth INSS and FGTS only in December" do
      dashboard = PayrollChargesDashboard.new
      december = dashboard.rows.last

      assert_equal 3_508_018.66.to_d, december[:inss_thirteenth].round(2)
      assert_equal 550_345.31.to_d, december[:fgts_thirteenth].round(2)
      assert_equal %i[monthly thirteenth], dashboard.fgts_components("2025-12").map(&:kind)
      assert dashboard.rows.first(11).all? { |row| row[:inss_thirteenth].zero? && row[:fgts_thirteenth].zero? }
    end

    test "recomposes the adjusted annual payroll" do
      totals = PayrollChargesDashboard.new.totals

      assert_equal 300_038_898.67.to_d, totals[:payroll_net].round(2)
      assert_equal 70_228_476.53.to_d, totals[:inss_gross].round(2)
      assert_equal 21_310_214.98.to_d, totals[:inss_discounts].round(2)
      assert_equal 48_918_261.55.to_d, totals[:inss_to_add].round(2)
      assert_equal 20_771_676.54.to_d, totals[:fgts_to_add].round(2)
      assert_equal 369_728_836.76.to_d, totals[:adjusted_payroll].round(2)
    end
  end
end
