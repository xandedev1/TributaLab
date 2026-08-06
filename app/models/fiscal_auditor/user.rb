module FiscalAuditor
  class User < ApplicationRecord
    self.table_name = "fiscal_auditor_users"

    has_secure_password

    validates :username, presence: true, uniqueness: { case_sensitive: false }
    validates :password, length: { minimum: 6 }, allow_nil: true

    scope :active, -> { where(active: true) }
  end
end
