module Fiscal
  class EfdRecord < ApplicationRecord
    self.table_name = "fiscal_efd_records"
    include Fiscal::CompanyScoped

    scope :in_year,  ->(y)    { where(issued_year: y) }
    scope :in_month, ->(y, m) { where(issued_year: y, issued_month: m) }
  end
end
