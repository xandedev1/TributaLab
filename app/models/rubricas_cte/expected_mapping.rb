module RubricasCte
	class ExpectedMapping < ApplicationRecord
		belongs_to :catalog_rubric
		belongs_to :source_file
		has_many :expected_incidences, dependent: :destroy
		has_many :findings, dependent: :nullify

		validates :source_sheet, :source_row, presence: true
		validates :source_row, uniqueness: { scope: :source_file_id }

		scope :nonzero_esocial, -> { where.not(esocial_nature_code: [nil, "", "0"]) }

		def nonzero_esocial?
			esocial_nature_code.present? && esocial_nature_code != "0"
		end

		def active_for_period?(period)
			return true if period.blank?

			starts_before = inicio.blank? || inicio > "9999" || inicio.to_s <= period.to_s
			ends_after = fim.blank? || fim > "9999" || fim.to_s >= period.to_s
			starts_before && ends_after
		end
	end
end