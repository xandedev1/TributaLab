module RubricasCte
	class SourceFile < ApplicationRecord
		has_many :import_runs, dependent: :destroy
		has_many :catalog_rubrics, dependent: :destroy
		has_many :expected_mappings, dependent: :destroy
		has_many :s1010_events, dependent: :destroy
		has_many :s1010_timeline_segments, dependent: :destroy

		validates :kind, :repo_path, :sha256, presence: true
		validates :sha256, uniqueness: true
	end
end