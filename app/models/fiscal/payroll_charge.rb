module Fiscal
  class PayrollCharge < ApplicationRecord
    self.table_name = "fiscal_payroll_charges"
    include Fiscal::CompanyScoped

    scope :in_year,  ->(y)    { where(competencia_year: y) }
    scope :in_month, ->(y, m) { where(competencia_year: y, competencia_month: m) }
  end
end
