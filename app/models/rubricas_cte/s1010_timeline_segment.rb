module RubricasCte
	class S1010TimelineSegment < ApplicationRecord
		belongs_to :source_file
		belongs_to :s1010_event
		has_many :findings, dependent: :nullify

		validates :s1010_key, presence: true

		scope :ordered, -> { order(:s1010_key, :period_start, :id) }
	end
end