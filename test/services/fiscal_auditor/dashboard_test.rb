require "test_helper"

module FiscalAuditor
  class DashboardTest < ActiveSupport::TestCase
    test "combines emission and competence filters and reconciles totals" do
      records = [
        record(emission: Date.new(2025, 6, 2), competence: Date.new(2025, 5, 1), billed: 1_000, inss: 110, iss: 50, net: 840),
        record(emission: Date.new(2025, 6, 3), competence: Date.new(2025, 6, 1), billed: 500, inss: 55, iss: 25, net: 420),
        record(emission: Date.new(2025, 5, 4), competence: Date.new(2025, 5, 1), billed: 200, inss: 22, iss: 10, net: 168)
      ]

      dashboard = Dashboard.new(emission_month: "2025-06", competence_months: [ "2025-05" ])
      dashboard.instance_variable_set(:@all_records, records)

      assert_equal [ "2025-05", "2025-06" ], dashboard.available_competence_months
      assert_equal 1, dashboard.records.size
      assert_equal 1_000.to_d, dashboard.totals[:billed]
      assert_equal 160.to_d, dashboard.totals[:retained]
      assert_equal 840.to_d, dashboard.totals[:net]
      assert_equal 16.to_d, dashboard.retention_rate
      assert_equal 0, dashboard.discrepancy_count
    end

    test "ignores malformed month parameters" do
      dashboard = Dashboard.new(emission_month: "2025-13")
      dashboard.instance_variable_set(:@all_records, [ record ])

      assert_nil dashboard.emission_month
      assert_empty dashboard.available_competence_months
      assert_equal 1, dashboard.records.size
    end

    test "lists only competences found in the selected emission month" do
      records = [
        record(emission: Date.new(2025, 1, 2), competence: Date.new(2024, 12, 1)),
        record(emission: Date.new(2025, 1, 3), competence: Date.new(2025, 1, 1)),
        record(emission: Date.new(2025, 2, 4), competence: Date.new(2024, 11, 1))
      ]
      dashboard = Dashboard.new(emission_month: "2025-01")
      dashboard.instance_variable_set(:@all_records, records)

      assert_equal [ "2024-12", "2025-01" ], dashboard.available_competence_months
      assert_equal 2, dashboard.records.size
    end

    private

    def record(emission: Date.new(2025, 6, 2), competence: Date.new(2025, 5, 1), billed: 100, inss: 11, iss: 5, net: 84)
      RetentionWorkbook::Record.new(
        source: "sample.xlsx",
        source_row: 2,
        cnpj: "12.345.678/0001-90",
        client_code: "123",
        client: "Cliente Teste",
        rps: "456",
        invoice_number: "789",
        emission_date: emission,
        competence: competence,
        status: "Aberta",
        billed: billed.to_d,
        inss: inss.to_d,
        irrf: 0.to_d,
        pis: 0.to_d,
        cofins: 0.to_d,
        csll: 0.to_d,
        iss: iss.to_d,
        net: net.to_d
      )
    end
  end
end
