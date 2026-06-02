module TaxRules
  module RealEstate
    class AssignmentRightsCalculator < BaseCalculator
      OPERATION_CODE = "rights_assignment"
      INPUT_KEYS = [:assignment_amount, :credits_amount].freeze
      PARAMETER_CODES = %w[full_ibs_cbs_rate rights_assignment_reduction].freeze
      FORMULA = "max(0, valor_cessao * (aliquota_cheia * (1 - reducao_cessao)) - creditos)"

      private

      def calculate
        gross_base = money(non_negative(decimal_input(:assignment_amount)))
        credits_amount = money(non_negative(decimal_input(:credits_amount)))
        full_rate = rate(parameter_value("full_ibs_cbs_rate"))
        reduction_rate = rate(parameter_value("rights_assignment_reduction"))
        effective_rate = rate(full_rate * (ONE - reduction_rate))
        debit_amount = money(gross_base * effective_rate)
        tax_due = money(non_negative(debit_amount - credits_amount))

        {
          gross_base:,
          deductions_amount: ZERO,
          net_base: gross_base,
          full_rate:,
          reduction_rate:,
          effective_rate:,
          debit_amount:,
          credits_amount:,
          tax_due:
        }
      end

      def calculation_details
        debit_amount = decimal_input(:assignment_amount) * (parameter_value("full_ibs_cbs_rate") * (ONE - parameter_value("rights_assignment_reduction")))

        super.merge(
          rights_assignment_rate_path: "apply_parameterized_reduction_pending_validation",
          credit_excess_amount: money(non_negative(decimal_input(:credits_amount) - debit_amount)),
          validation_note: "A planilha indica reducao de 70% para locacao/cessao/arrendamento, mas a aba de calculo de cessao usa aliquota cheia. Validar com Denis."
        )
      end
    end
  end
end