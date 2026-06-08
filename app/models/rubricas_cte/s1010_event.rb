module RubricasCte
	class S1010Event < ApplicationRecord
		belongs_to :source_file
		has_many :s1010_timeline_segments, dependent: :destroy

		validates :xml_path, :xml_sha256, presence: true
		validates :xml_sha256, uniqueness: true

		scope :ordered, -> { order(:ide_tab_rubr, :cod_rubr_raw, :ini_valid, :xml_path) }

		def s1010_key
			[self.ide_tab_rubr, self.cod_rubr_raw].compact.join("|")
		end
	end
end