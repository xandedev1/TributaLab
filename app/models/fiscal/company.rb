module Fiscal
  class Company < ApplicationRecord
    self.table_name = "fiscal_companies"

    validates :slug, :legal_name, :cnpj, presence: true
    validates :slug, :cnpj, uniqueness: true

    scope :active, -> { where(status: "active") }
  end
end
