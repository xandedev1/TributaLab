module Inss
  class PayrollEmployee < ApplicationRecord
    self.table_name = "inss_payroll_employees"

    belongs_to :import,
      class_name: "Inss::PayrollImport",
      foreign_key: :inss_payroll_import_id,
      inverse_of: :employees

    has_many :entries,
      class_name: "Inss::PayrollEntry",
      foreign_key: :inss_payroll_employee_id,
      dependent: :destroy,
      inverse_of: :employee

    scope :ordered, -> { order(:nome) }
    scope :for_situacao, ->(situacao) { where(situacao_funcional: situacao) if situacao.present? }
    scope :for_contrato, ->(codigo) { where(contrato_codigo: codigo) if codigo.present? }
    scope :for_competencia, ->(comp) { where(competencia: comp) if comp.present? }
    scope :search_nome, ->(term) {
      where("nome ILIKE :q OR matricula ILIKE :q", q: "%#{sanitize_sql_like(term.to_s)}%") if term.present?
    }

    def display_name
      [matricula, nome].compact.join(" - ")
    end
  end
end
