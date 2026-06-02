class RubricNatureAssignment < ApplicationRecord
	STATUSES = %w[pending selected reviewed ambiguous rejected].freeze
	SELECTION_ORIGINS = %w[suggested manual imported reviewed].freeze

	belongs_to :rubric_event
	belongs_to :esocial_nature, optional: true
	has_many :rubric_nature_assignment_versions, dependent: :destroy

	before_validation :sync_selected_incidence_codes

	validates :status, inclusion: { in: STATUSES }
	validates :selection_origin, inclusion: { in: SELECTION_ORIGINS }
	validates :rubric_event_id, uniqueness: true
	validate :selected_status_requires_nature

	def incidence_snapshot
		{
			"selected_cod_inc_cp" => selected_cod_inc_cp,
			"selected_cod_inc_irrf" => selected_cod_inc_irrf,
			"selected_cod_inc_fgts" => selected_cod_inc_fgts,
			"status" => status
		}
	end

	private

	def sync_selected_incidence_codes
		return unless esocial_nature

		self.selected_cod_inc_cp = esocial_nature.cod_inc_cp if selected_cod_inc_cp.blank?
		self.selected_cod_inc_irrf = esocial_nature.cod_inc_irrf if selected_cod_inc_irrf.blank?
		self.selected_cod_inc_fgts = esocial_nature.cod_inc_fgts if selected_cod_inc_fgts.blank?
	end

	def selected_status_requires_nature
		return unless %w[selected reviewed].include?(status)
		return if esocial_nature.present?

		errors.add(:esocial_nature, "deve ser informada para uma rubrica selecionada")
	end
end