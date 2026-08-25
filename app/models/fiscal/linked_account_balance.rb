module Fiscal
  class LinkedAccountBalance < ApplicationRecord
    self.table_name = "fiscal_linked_account_balances"
    include Fiscal::CompanyScoped

    belongs_to :linked_account, class_name: "Fiscal::LinkedAccount", foreign_key: :fiscal_linked_account_id
  end
end
