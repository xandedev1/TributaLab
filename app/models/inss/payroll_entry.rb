module Inss
  class PayrollEntry < ApplicationRecord
    self.table_name = "inss_payroll_entries"

    # Blocos possiveis no RESUMO MOVIMENTO MENSAL
    BLOCOS = {
      "encargos" => "Totais e Encargos",
      "proventos" => "Proventos",
      "descontos" => "Descontos",
      "liquido" => "Liquido"
    }.freeze

    belongs_to :employee,
      class_name: "Inss::PayrollEmployee",
      foreign_key: :inss_payroll_employee_id,
      inverse_of: :entries

    validates :bloco, :codigo, presence: true
    validates :bloco, inclusion: { in: BLOCOS.keys }

    scope :for_bloco, ->(bloco) { where(bloco: bloco) if bloco.present? }

    def bloco_label
      BLOCOS.fetch(bloco, bloco)
    end
  end
end
