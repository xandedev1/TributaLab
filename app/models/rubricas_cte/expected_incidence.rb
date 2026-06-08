module RubricasCte
	class ExpectedIncidence < ApplicationRecord
		belongs_to :expected_mapping

		validates :tax_kind, :indicator_code, :expected_flag, presence: true
		validates :indicator_code, uniqueness: { scope: [:expected_mapping_id, :tax_kind] }
	end
end