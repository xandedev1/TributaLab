module TaxRules
  module RealEstate
    class ConstructionContractCalculator < BaseCalculator
      OPERATION_CODE = "civil_construction"
      INPUT_KEYS = [:contract_amount, :credits_amount].freeze
      PARAMETER_CODES = %w[full_ibs_cbs_rate].freeze
      FORMULA = "max(0, valor_contrato * aliquota_cheia - creditos)"

      private

      def calculate
        gross_base = money(non_negative(decimal_input(:contract_amount)))
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
        debit_amount = decimal_input(:contract_amount) * parameter_value("full_ibs_cbs_rate")

        super.merge(
          credit_excess_amount: money(non_negative(decimal_input(:credits_amount) - debit_amount)),
          validation_note: "Modelo inicial usa aliquota cheia com creditos. Confirmar se construcao civil nao possui reducao especifica."
        )
      end
    end
  end
end