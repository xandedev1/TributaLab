module Fiscal
  class LinkedAccount < ApplicationRecord
    self.table_name = "fiscal_linked_accounts"
    include Fiscal::CompanyScoped

    has_many :balances, class_name: "Fiscal::LinkedAccountBalance", foreign_key: :fiscal_linked_account_id, dependent: :destroy
  end
end
