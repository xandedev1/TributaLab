class Sector < ApplicationRecord
	has_many :tax_modules, dependent: :restrict_with_exception

	validates :code, :name, presence: true
	validates :code, uniqueness: true

	scope :ordered, -> { order(:position, :name) }
end
