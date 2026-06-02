class RubricCompany < ApplicationRecord
	has_many :rubric_events, dependent: :destroy

	validates :name, presence: true
	validates :reference_code, uniqueness: true, allow_blank: true

	scope :ordered, -> { order(name: :asc) }
end