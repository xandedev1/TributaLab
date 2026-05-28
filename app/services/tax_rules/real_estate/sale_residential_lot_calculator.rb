module TaxRules
  module RealEstate
    class SaleResidentialLotCalculator < BaseCalculator
      OPERATION_CODE = "sale_residential_lot"
      INPUT_KEYS = [:sale_amount].freeze
      PARAMETER_CODES = %w[full_ibs_cbs_rate sale_lot_social_deduction lot_sale_reduction].freeze
      FORMULA = "max(0, valor_venda - redutor_lote) * (aliquota_cheia * (1 - reducao))"

      private

      def calculate
        gross_base = money(non_negative(decimal_input(:sale_amount)))
        deductions_amount = money(parameter_value("sale_lot_social_deduction"))
        net_base = money(non_negative(gross_base - deductions_amount))
        full_rate = rate(parameter_value("full_ibs_cbs_rate"))
        reduction_rate = rate(parameter_value("lot_sale_reduction"))
        effective_rate = rate(full_rate * (ONE - reduction_rate))
        debit_amount = money(net_base * effective_rate)

        {
          gross_base:,
          deductions_amount:,
          net_base:,
          full_rate:,
          reduction_rate:,
          effective_rate:,
          debit_amount:,
          credits_amount: ZERO,
          tax_due: debit_amount
        }
      end
    end
  end
end