module Fiscal
  # Concern comum aos models de dados do Auditor Fiscal (multi-tenant + tempo).
  module CompanyScoped
    extend ActiveSupport::Concern

    included do
      belongs_to :company, class_name: "Fiscal::Company", foreign_key: :fiscal_company_id
      scope :for_company, ->(id) { where(fiscal_company_id: id) }
    end
  end
end
