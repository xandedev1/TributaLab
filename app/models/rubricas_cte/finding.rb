module RubricasCte
	class Finding < ApplicationRecord
		belongs_to :catalog_rubric
		belongs_to :expected_mapping, optional: true
		belongs_to :rubric_identity_link, optional: true
		belongs_to :s1010_timeline_segment, optional: true

		validates :divergence_kind, :confidence, :review_status, presence: true

		scope :with_nature_divergence, -> { where(nature_divergent: true) }
		scope :with_cp_divergence, -> { where(cp_divergent: true) }
		scope :with_irrf_divergence, -> { where(irrf_divergent: true) }
		scope :with_fgts_divergence, -> { where(fgts_divergent: true) }
	end
end