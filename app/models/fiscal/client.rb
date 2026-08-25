module Fiscal
  class Client < ApplicationRecord
    self.table_name = "fiscal_clients"
    include Fiscal::CompanyScoped

    has_many :billings, class_name: "Fiscal::Billing", foreign_key: :fiscal_client_id, dependent: :nullify
    has_many :receivables, class_name: "Fiscal::Receivable", foreign_key: :fiscal_client_id, dependent: :nullify

    validates :code, presence: true
  end
end
