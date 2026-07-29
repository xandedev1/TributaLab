require "test_helper"

module FiscalAuditor
  class PayrollDashboardTest < ActiveSupport::TestCase
    test "recomposes the validated annual payroll" do
      dashboard = PayrollDashboard.new

      assert_equal 10, dashboard.source_count
      assert_includes PayrollDashboard.source_paths.map { |path| File.basename(path) }, "Empresa 010 Folha 2025.xlsx"
      assert_equal 183, dashboard.available_clients.size
      assert_equal 382_194_167.07.to_d, dashboard.totals[:earnings].round(2)
      assert_equal 82_155_268.40.to_d, dashboard.totals[:discounts].round(2)
      assert_equal 300_038_898.67.to_d, dashboard.totals[:net].round(2)
    end

    test "compares payroll and billing by client and competence" do
      dashboard = PayrollDashboard.new(periods: [ "2025-01" ], client_code: "335")
      row = dashboard.comparison_rows.sole

      assert_equal "335", row[:client_code]
      assert_equal "2025-01", row[:month]
      assert_equal row[:earnings] - row[:discounts], row[:payroll_net]
      assert_equal row[:billing_net] - row[:payroll_net], row[:difference]
      assert_includes %i[covered deficit missing_billing negative_payroll], row[:status]
    end

    test "filters the complete reading by one or more situations" do
      dashboard = PayrollDashboard.new(statuses: %w[deficit missing_billing unknown])

      assert_equal %w[deficit missing_billing], dashboard.statuses
      assert_equal 557, dashboard.comparison_rows.size
      assert_equal %i[deficit missing_billing], dashboard.comparison_rows.map { |row| row[:status] }.uniq.sort
      assert_equal 80_591_682.68.to_d, dashboard.totals[:net].round(2)
      assert_equal 25_370_640.25.to_d, dashboard.billing_total.round(2)
      assert_equal(-55_221_042.43.to_d, dashboard.difference.round(2))
    end

    test "billing parser recovers client codes and names from malformed headers" do
      paths = Dashboard.source_paths.select { |path| path.include?("07_JULHO") || path.include?("11_NOVO") }
      records = paths.flat_map { |path| RetentionWorkbook.new(path).records }

      assert records.all? { |record| record.client_code.present? }
      assert records.none? { |record| record.client == record.cnpj }
    end
  end
end
