module ApplicationHelper
	def shell_nav_items
		[
			["Painel", root_path],
			["Rubricas CTE", rubricas_cte_root_path],
			["Lotacao Tributaria", esocial_lotacoes_path],
			["Estabelecimentos e Obras", esocial_estabelecimentos_obras_path],
			["Base Legal", legal_basis_path],
			["Parametros", tax_parameters_path],
			["Premissas", assumptions_path]
		]
	end

	def shell_nav_sections
		[
			{ label: "Painel", path: root_path },
			{
				label: "Eventos",
				items: [
					{ label: "Rubricas CTE", path: rubricas_cte_root_path },
					{ label: "Base Legal", path: legal_basis_path }
				]
			},
			{
				label: "Tabelas do Cliente",
				items: [
					{ label: "Lotacao Tributaria", path: esocial_lotacoes_path },
					{ label: "Estabelecimentos e Obras", path: esocial_estabelecimentos_obras_path }
				]
			},
			{
				label: "Configuracoes",
				icon: "gear",
				items: [
					{ label: "Parametros", path: tax_parameters_path },
					{ label: "Premissas", path: assumptions_path }
				]
			}
		]
	end

	def shell_nav_link_classes(path)
		base = "tl-nav-link"
		if shell_nav_active?(path)
			"#{base} tl-nav-link--active"
		else
			base
		end
	end

	def shell_nav_sublink_classes(path)
		base = "tl-nav-sublink"
		if shell_nav_active?(path)
			"#{base} tl-nav-sublink--active"
		else
			base
		end
	end

	def shell_nav_section_active?(section)
		return shell_nav_active?(section[:path]) if section[:path].present?

		Array(section[:items]).any? { |item| shell_nav_item_active?(item) }
	end

	def shell_nav_item_active?(item)
		return shell_nav_active?(item[:path]) if item[:path].present?

		Array(item[:children]).any? { |child| shell_nav_active?(child[:path]) }
	end

	def shell_nav_active?(path)
		return current_page?(path) if path == root_path

		request.path == path || request.path.start_with?("#{path}/")
	end

	def button_classes(variant = :secondary)
		case variant
		when :primary
			"tl-button tl-button--primary"
		when :success
			"tl-button tl-button--success"
		when :danger
			"tl-button tl-button--danger"
		when :info
			"tl-button tl-button--info"
		when :accent
			"tl-button tl-button--accent"
		else
			"tl-button tl-button--secondary"
		end
	end

	def panel_classes
		"tl-card"
	end

	def status_label(status)
		status.to_s.tr("_", " ")
	end

	def status_badge_classes(status)
		case status.to_s
		when "active", "validated", "completed", "selected", "reviewed", "sugestao alta"
			"tl-badge tl-badge--success"
		when "pending", "pending_validation", "ambiguous", "ambigua", "revisar"
			"tl-badge tl-badge--warning"
		when "divergent", "rejected", "divergente"
			"tl-badge tl-badge--danger"
		when "paused", "archived", "sem natureza"
			"tl-badge tl-badge--muted"
		else
			"tl-badge"
		end
	end

	def score_tone(score)
		value = score.to_f
		return "strong" if value >= 8.5
		return "good" if value >= 7.0
		return "medium" if value >= 5.0

		"low"
	end

	def score_badge_classes(score)
		"tl-badge tl-score-badge tl-score-badge--#{score_tone(score)}"
	end

	def score_bar_classes(score)
		"tl-score-bar tl-score-bar--#{score_tone(score)}"
	end

	def score_percentage(score)
		[[score.to_f * 10.0, 0.0].max, 100.0].min
	end

	def s1010_tab_classes(path)
		base = "tl-tab"
		shell_nav_active?(path) ? "#{base} tl-tab--active" : base
	end

	def incidence_tone_from_alignment(alignment)
		return "muted" if alignment.blank?

		score = alignment[:score] || alignment["score"]
		return "success" if score.to_f >= 0.55
		return "warning" if score.to_f.positive?

		"danger"
	end

	def incidence_pill_classes(alignment)
		"tl-incidence-pill tl-incidence-pill--#{incidence_tone_from_alignment(alignment)}"
	end

	def suggestion_row_classes(suggestion, assignment = nil)
		classes = ["tl-decision-row", "tl-decision-row--#{score_tone(suggestion.score)}"]
		classes << "tl-row-selected" if assignment&.esocial_nature_id == suggestion.esocial_nature_id
		classes.join(" ")
	end

	def assignment_row_classes(assignment)
		classes = ["tl-assignment-row"]
		classes << "tl-row-reviewed" if assignment.status == "reviewed"
		classes << "tl-row-selected" if assignment.status == "selected"
		classes << "tl-row-warning" if assignment.status == "ambiguous"
		classes.join(" ")
	end
end
