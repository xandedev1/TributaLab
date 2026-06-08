module RubricasCte
	class RubricIdentityLink < ApplicationRecord
		belongs_to :catalog_rubric
		has_many :findings, dependent: :nullify

		validates :match_method, :review_status, presence: true
		validates :catalog_rubric_id, uniqueness: true

		def linked?
			s1010_key.present? && review_status == "matched"
		end
	end
end