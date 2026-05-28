class LegalBasis < ApplicationRecord
	STATUSES = %w[validated pending divergent replaced].freeze

	validates :code, :law, :description, :status, presence: true
	validates :code, uniqueness: true
	validates :status, inclusion: { in: STATUSES }
end
