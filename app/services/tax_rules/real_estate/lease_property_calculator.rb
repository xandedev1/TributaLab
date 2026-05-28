module TaxRules
  module RealEstate
    class LeasePropertyCalculator < BaseCalculator
      OPERATION_CODE = "lease_property"
      INPUT_KEYS = [:monthly_rent, :iptu_amount, :condominium_amount].freeze
      PARAMETER_CODES = %w[full_ibs_cbs_rate lease_social_deduction lease_reduction].freeze
      FORMULA = "max(0, aluguel - iptu - condominio - redutor_locacao) * (aliquota_cheia * (1 - reducao_locacao))"

      private

      def calculate
        monthly_rent = non_negative(decimal_input(:monthly_rent))
        iptu_amount = non_negative(decimal_input(:iptu_amount))
        condominium_amount = non_negative(decimal_input(:condominium_amount))
        gross_base = money(monthly_rent - iptu_amount - condominium_amount)
        deductions_amount = money(parameter_value("lease_social_deduction"))
        net_base = money(non_negative(gross_base - deductions_amount))
        full_rate = rate(parameter_value("full_ibs_cbs_rate"))
        reduction_rate = rate(parameter_value("lease_reduction"))
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

      def calculation_details
        super.merge(
          lease_base_path: "deduct_iptu_and_condominium",
          validation_note: "A planilha indica excluir IPTU e condominio, mas o exemplo usa aluguel integral. Este calculo segue a formula indicada e mantem alerta pendente."
        )
      end
    end
  end
end