module TaxRules
  module RealEstate
    class ExchangeWithoutBootCalculator < BaseCalculator
      OPERATION_CODE = "exchange_without_boot"
      INPUT_KEYS = [].freeze
      PARAMETER_CODES = [].freeze
      FORMULA = "base_calculo = 0; imposto_estimado = 0"

      private

      def calculate
        {
          gross_base: ZERO,
          deductions_amount: ZERO,
          net_base: ZERO,
          full_rate: ZERO,
          reduction_rate: ZERO,
          effective_rate: ZERO,
          debit_amount: ZERO,
          credits_amount: ZERO,
          tax_due: ZERO
        }
      end

      def calculation_details
        super.merge(
          informational_operation: true,
          validation_note: "Operacao tratada como sem incidencia no modelo inicial. Confirmar se deve existir apenas como informativa ou se precisa de simulador proprio."
        )
      end
    end
  end
end