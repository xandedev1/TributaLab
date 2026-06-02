class RubricNatureSuggestion < ApplicationRecord
	belongs_to :rubric_event
	belongs_to :esocial_nature

	validates :rank, :score, :confidence_label, :algorithm_version, presence: true
	validates :rank, uniqueness: { scope: :rubric_event_id }
	validates :esocial_nature_id, uniqueness: { scope: :rubric_event_id }
end