require "test_helper"

module FiscalAuditor
  class PayrollComparisonDetailTest < ActiveSupport::TestCase
    test "recomposes a client and competence from payroll events and billing invoices" do
      result = PayrollComparisonDetail.new(client_code: "492", period: "2025-01").result
      summary = result.summary

      assert_equal "492", summary[:client_code]
      assert_equal "2025-01", summary[:month]
      assert_equal summary[:earnings], result.events.select { |record| record.event_type == "Vencimento" }.sum(&:amount)
      assert_equal summary[:discounts], result.events.select { |record| record.event_type == "Desconto" }.sum(&:amount)
      assert_equal summary[:billing_net], result.invoices.sum(&:net)
      assert_equal summary[:events], result.events.size
      assert_equal summary[:documents], result.invoices.size
      assert result.events.all? { |record| record.source == "Empresa 010 Folha 2025.xlsx" }
      assert result.invoices.none? { |record| I18n.transliterate(record.status.to_s).downcase.include?("cancel") }
    end

    test "rejects an invalid or unavailable comparison" do
      assert_raises(ArgumentError) { PayrollComparisonDetail.new(client_code: "492", period: "2025-13").result }
      assert_raises(ArgumentError) { PayrollComparisonDetail.new(client_code: "inexistente", period: "2025-01").result }
    end

    test "keeps payroll evidence when no billing invoice exists" do
      result = PayrollComparisonDetail.new(client_code: "1", period: "2025-01").result

      assert_equal :missing_billing, result.summary[:status]
      assert result.events.any?
      assert_empty result.invoices
      assert_equal 0.to_d, result.summary[:billing_net]
    end
  end
end
