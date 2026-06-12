class EsocialCompanyAuthorization < ApplicationRecord
	STATUSES = %w[declared verified failed revoked expired].freeze
	VERIFICATION_METHODS = %w[manual official direct_holder].freeze

	belongs_to :esocial_certificate

	validates :target_company_cnpj, :target_company_name, :status, :verification_method, presence: true
	validates :status, inclusion: { in: STATUSES }
	validates :verification_method, inclusion: { in: VERIFICATION_METHODS }

	before_validation :normalize_target_company_cnpj

	def declared?
		status == "declared"
	end

	def verified?
		status == "verified"
	end

	def usable_for_official_test?
		declared? || verified?
	end

	private

	def normalize_target_company_cnpj
		self.target_company_cnpj = EsocialCertificate.clean_digits(target_company_cnpj)
	end
end