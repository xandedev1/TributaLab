module Fiscal
  class Payable < ApplicationRecord
    self.table_name = "fiscal_payables"
    include Fiscal::CompanyScoped

    scope :paid_in_year,  ->(y)    { where(paid_year: y) }
    scope :paid_in_month, ->(y, m) { where(paid_year: y, paid_month: m) }
  end
end
