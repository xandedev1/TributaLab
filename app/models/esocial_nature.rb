class EsocialNature < ApplicationRecord
	has_many :rubric_nature_suggestions, dependent: :destroy
	has_many :rubric_nature_assignments, dependent: :nullify

	validates :source_file_hash, :source_sheet, :source_row, :nature_code, :name, presence: true
	validates :source_row, uniqueness: { scope: :source_file_hash }

	scope :ordered, -> { order(:nature_code, :valid_from, :source_row) }

	def display_name
		"#{nature_code} - #{name}"
	end

	def vigency_label
		return "#{valid_from.presence || "sem inicio"} -> #{valid_to}" if valid_to.present?

		"#{valid_from.presence || "sem inicio"} -> vigente"
	end
end