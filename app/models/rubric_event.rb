class RubricEvent < ApplicationRecord
	belongs_to :rubric_company
	has_many :rubric_nature_suggestions, -> { order(rank: :asc) }, dependent: :destroy
	has_one :rubric_nature_assignment, dependent: :destroy

	validates :source_file_hash, :source_sheet, :source_row, :event_code, :description, presence: true
	validates :event_code, uniqueness: { scope: :rubric_company_id }

	scope :ordered, -> { order(:event_code) }

	def best_suggestion
		rubric_nature_suggestions.min_by(&:rank)
	end

	def assigned?
		rubric_nature_assignment&.esocial_nature.present?
	end

	def ambiguous_suggestions?
		first, second = rubric_nature_suggestions.first(2)
		return false unless first && second

		(first.score.to_f - second.score.to_f).abs < 0.35
	end

	def adequacy_status
		return rubric_nature_assignment.status if rubric_nature_assignment.present?
		return "sem natureza" unless best_suggestion
		return "ambigua" if ambiguous_suggestions?
		return "sugestao alta" if best_suggestion.score.to_f >= 8.5
		return "revisar" if best_suggestion.score.to_f >= 5.0

		"sem natureza"
	end

	def relevant_suggestions_count
		rubric_nature_suggestions.count { |suggestion| suggestion.score.to_f >= 5.0 }
	end
end