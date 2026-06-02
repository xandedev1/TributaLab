module TaxRules
  module RealEstate
    class BrokerageAdministrationCalculator < BaseCalculator
      OPERATION_CODE = "management_brokerage"
      INPUT_KEYS = [:service_amount, :credits_amount].freeze
      PARAMETER_CODES = %w[full_ibs_cbs_rate].freeze
      FORMULA = "max(0, valor_servico * aliquota_cheia - creditos)"

      private

      def calculate
        gross_base = money(non_negative(decimal_input(:service_amount)))
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
        debit_amount = decimal_input(:service_amount) * parameter_value("full_ibs_cbs_rate")

        super.merge(
          credit_excess_amount: money(non_negative(decimal_input(:credits_amount) - debit_amount)),
          validation_note: "Modelo inicial usa aliquota cheia sem redutor. Confirmar administracao/corretagem com Denis."
        )
      end
    end
  end
end