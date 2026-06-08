module RubricasCte
	class CatalogRubric < ApplicationRecord
		belongs_to :source_file
		has_many :expected_mappings, -> { order(:source_row) }, dependent: :destroy
		has_one :rubric_identity_link, dependent: :destroy
		has_many :findings, dependent: :destroy

		validates :cte_code, :description, presence: true
		validates :cte_code, uniqueness: true

		scope :ordered, -> { order(:cte_code) }

		def esocial_nature_codes
			expected_mappings.map(&:esocial_nature_code).select(&:present?).uniq
		end

		def nonzero_esocial_nature_codes
			esocial_nature_codes.reject { |code| code == "0" }
		end

		def linked_to_s1010?
			rubric_identity_link&.linked?
		end
	end
end