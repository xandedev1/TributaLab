module TaxRules
  module RealEstate
    class ExchangeWithBootCalculator < BaseCalculator
      OPERATION_CODE = "exchange_with_boot"
      INPUT_KEYS = [:boot_amount, :credits_amount].freeze
      PARAMETER_CODES = %w[full_ibs_cbs_rate].freeze
      FORMULA = "max(0, valor_torna * aliquota_cheia - creditos)"

      private

      def calculate
        gross_base = money(non_negative(decimal_input(:boot_amount)))
        credits_amount = money(non_negative(decimal_input(:credits_amount)))
        full_rate = rate(parameter_value("full_ibs_cbs_rate"))
        debit_amount = money(gross_base * full_rate)
        tax_due = money(non_negative(debit_amount - credits_amount))

        {
          gross_base:,
          deductions_amount: ZERO,
          net_base: gross_base,
          full_rate:,
          reduction_rate: ZERO,
          effective_rate: full_rate,
          debit_amount:,
          credits_amount:,
          tax_due:
        }
      end

      def calculation_details
        super.merge(
          credit_excess_amount: money(non_negative(decimal_input(:credits_amount) - (decimal_input(:boot_amount) * parameter_value("full_ibs_cbs_rate"))))
        )
      end
    end
  end
end