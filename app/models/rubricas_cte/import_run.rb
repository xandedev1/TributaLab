module RubricasCte
	class ImportRun < ApplicationRecord
		belongs_to :source_file

		validates :kind, :status, :started_at, presence: true
	end
end