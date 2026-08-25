module Fiscal
  class Receivable < ApplicationRecord
    self.table_name = "fiscal_receivables"
    include Fiscal::CompanyScoped

    belongs_to :client, class_name: "Fiscal::Client", foreign_key: :fiscal_client_id, optional: true

    scope :in_year,  ->(y)    { where(competencia_year: y) }
    scope :in_month, ->(y, m) { where(competencia_year: y, competencia_month: m) }
  end
end
