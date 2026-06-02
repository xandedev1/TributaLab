class RubricNatureAssignmentVersion < ApplicationRecord
	belongs_to :rubric_nature_assignment

	validates :previous_values, :new_values, :reason, :changed_by, presence: true
end