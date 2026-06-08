module RubricasCte
	class ChainWalkSnapshot
		DEFAULT_STATUS = "divergent".freeze

		Metric = Struct.new(:label, :value, :detail, keyword_init: true)
		TimelineEntry = Struct.new(:segment, :event, :finding, :changed_fields, :divergence_kinds, keyword_init: true)
		ComparisonRow = Struct.new(:field, :expected, :declared, :reading, :divergent, :changed, keyword_init: true)

		def initialize(filters = {})
			@query = filters[:q].to_s.strip
			@status = filters[:status].presence || DEFAULT_STATUS
			@rubric_id = filters[:rubric_id].to_s.strip
			@segment_id = filters[:segment_id].to_s.strip
		end

		attr_reader :query, :status, :rubric_id, :segment_id

		def metrics
			@metrics ||= [
				Metric.new(label: "Divergentes", value: divergent_rubrics_count, detail: "foco de trabalho"),
				Metric.new(label: "Sem vinculo", value: unlinked_rubrics_count, detail: "match pendente"),
				Metric.new(label: "Mudaram no historico", value: changed_rubrics_count, detail: "natureza ou incidencia"),
				Metric.new(label: "Eventos XML", value: S1010Event.count, detail: "S-1010 local parseado")
			]
		end

		def rubrics
			@rubrics ||= begin
				scope = CatalogRubric.left_outer_joins(:rubric_identity_link, :findings)
					.includes(:expected_mappings, :rubric_identity_link, findings: :s1010_timeline_segment)
				scope = scope.where(search_sql, query: "%#{query}%") if query.present?
				scope = apply_status(scope) if status.present?
				scope.distinct.to_a.sort_by { |rubric| queue_sort_key(rubric) }.first(180)
			end
		end

		def selected_rubric
			@selected_rubric ||= begin
				candidate = CatalogRubric.includes(:expected_mappings, :rubric_identity_link, findings: :s1010_timeline_segment).find_by(id: rubric_id) if rubric_id.present?
				candidate || rubrics.find(&:linked_to_s1010?) || rubrics.first
			end
		end

		def selected_link
			selected_rubric&.rubric_identity_link
		end

		def timeline_entries
			@timeline_entries ||= begin
				return [] unless selected_link&.linked?

				findings = selected_rubric.findings.index_by(&:s1010_timeline_segment_id)
				S1010TimelineSegment.includes(:s1010_event)
					.where(s1010_key: selected_link.s1010_key)
					.ordered
					.map do |segment|
						finding = findings[segment.id]
						TimelineEntry.new(
							segment: segment,
							event: segment.s1010_event,
							finding: finding,
							changed_fields: Array(segment.changed_fields),
							divergence_kinds: Array(finding&.divergence_kinds)
						)
					end
			end
		end

		def selected_entry
			@selected_entry ||= timeline_entries.find { |entry| entry.segment.id.to_s == segment_id } || timeline_entries.last || timeline_entries.first
		end

		def status_options
			[
				["Fila priorizada", "divergent"],
				["Sem vinculo", "unlinked"],
				["Mudaram no historico", "changed"],
				["Com vinculo S-1010", "linked"],
				["Todas", "all"]
			]
		end

		def expected_summary
			return {} unless selected_rubric

			mappings = selected_rubric.expected_mappings
			{
				"eSoc" => selected_rubric.nonzero_esocial_nature_codes.presence || ["0"],
				"CP" => expected_flags_for(mappings, "CP"),
				"IRRF" => expected_flags_for(mappings, "IRRF"),
				"FGTS" => expected_flags_for(mappings, "FGTS"),
				"linhas" => mappings.size
			}
		end

		def candidates
			Array(selected_link&.candidates)
		end

		def comparison_rows(entry = selected_entry)
			return [] unless entry

			[
				ComparisonRow.new(
					field: "Natureza eSocial",
					expected: nature_label(expected_nature_for(entry)),
					declared: nature_label(entry.segment.nat_rubr),
					reading: nature_reading(entry),
					divergent: entry.finding&.nature_divergent? || false,
					changed: entry.changed_fields.include?("nature")
				),
				comparison_row_for(entry, "CP"),
				comparison_row_for(entry, "IRRF"),
				comparison_row_for(entry, "FGTS")
			]
		end

		def rubric_status_label(rubric)
			link = rubric.rubric_identity_link
			return "Sem vinculo" unless link&.linked?
			return "Divergente" if rubric.findings.any? { |finding| divergent_finding?(finding) }

			"Alinhada"
		end

		def rubric_status_classes(rubric)
			case rubric_status_label(rubric)
			when "Divergente"
				"tl-badge tl-badge--danger"
			when "Alinhada"
				"tl-badge tl-badge--success"
			else
				"tl-badge tl-badge--muted"
			end
		end

		def rubric_hint(rubric)
			link = rubric.rubric_identity_link
			return "Sem vinculo unico: precisa escolher ou confirmar candidato" unless link&.linked?

			parts = []
			parts << "eSoc #{rubric.nonzero_esocial_nature_codes.presence&.join(', ') || '0'}"
			parts << "S-1010 #{link.cod_rubr_raw}"
			parts.join(" / ")
		end

		def queue_title
			case status
			when "unlinked"
				"Fila de vinculos pendentes"
			when "changed"
				"Fila de mudancas historicas"
			when "linked"
				"Rubricas vinculadas ao S-1010"
			when "all"
				"Todas as rubricas"
			else
				"Fila de trabalho priorizada"
			end
		end

		def queue_subtitle
			case status
			when "unlinked"
				"Casos que ainda nao podem ser julgados sem confirmar o match CTE x S-1010."
			when "changed"
				"Casos em que o historico S-1010 mudou natureza ou incidencia ao longo do tempo."
			when "linked"
				"Casos com uma chave S-1010 unica encontrada pelo match deterministico."
			when "all"
				"Catalogo completo, mantendo a mesma leitura de prioridade e dossie."
			else
				"A ordem combina severidade, tipos de divergencia e mudancas historicas."
			end
		end

		def priority_breakdown(rubric)
			return ["Confirmar vinculo com S-1010"] unless rubric.rubric_identity_link&.linked?

			findings = rubric.findings.to_a
			kinds = findings.flat_map { |finding| Array(finding.divergence_kinds) }.map(&:to_s).uniq
			items = []
			items << "Natureza divergente" if kinds.include?("nature")
			items << "CP divergente" if kinds.include?("cp")
			items << "IRRF divergente" if kinds.include?("irrf")
			items << "FGTS divergente" if kinds.include?("fgts")
			items << "Mudou no historico" if findings.any? { |finding| finding.s1010_timeline_segment&.changed_fields.present? }
			items.presence || ["Sem divergencia ativa"]
		end

		def priority_breakdown_classes(item)
			case item
			when /Natureza|CP|IRRF|FGTS/
				"tl-chip tl-chip--danger"
			when /Mudou/
				"tl-chip tl-chip--warning"
			when /Confirmar/
				"tl-chip tl-chip--info"
			else
				"tl-chip"
			end
		end

		def priority_score(rubric)
			findings = rubric.findings.to_a
			return nil unless findings.any? { |finding| divergent_finding?(finding) }

			kinds = findings.flat_map { |finding| Array(finding.divergence_kinds) }.map(&:to_s).uniq
			score = 0
			score += 40 if kinds.include?("nature")
			score += 20 if kinds.include?("cp")
			score += 20 if kinds.include?("irrf")
			score += 20 if kinds.include?("fgts")
			score += 10 if findings.any? { |finding| finding.s1010_timeline_segment&.changed_fields.present? }
			[score, 100].min
		end

		def priority_label(rubric)
			score = priority_score(rubric)
			return "Sem pontuacao" unless score

			"Pontuacao #{score}"
		end

		def priority_classes(rubric)
			score = priority_score(rubric)
			return "tl-badge tl-badge--muted" unless score
			return "tl-badge tl-badge--danger" if score >= 70
			return "tl-badge tl-badge--warning" if score >= 40

			"tl-badge tl-badge--info"
		end

		def dossier_cards
			return [] unless selected_rubric

			[
				Metric.new(label: "Status", value: rubric_status_label(selected_rubric), detail: dossier_status_detail),
				Metric.new(label: "Pontuacao", value: priority_score(selected_rubric) || "-", detail: "aplicada apenas a divergentes"),
				Metric.new(label: "Vinculo", value: selected_link&.cod_rubr_raw || "pendente", detail: selected_link&.match_method || "sem match unico"),
				Metric.new(label: "Natureza CTE", value: Array(expected_summary["eSoc"]).join(", "), detail: "coluna eSoc da planilha")
			]
		end

		def dossier_status_detail
			return "match CTE x S-1010 pendente" unless selected_link&.linked?
			return "revisar disputa CTE x declaracao" if selected_rubric.findings.any? { |finding| divergent_finding?(finding) }

			"sem conflito ativo nesta leitura"
		end

		def entry_status_label(entry)
			return "Divergente" if entry.divergence_kinds.any?
			return "Alterou no S-1010" if entry.changed_fields.any?

			"Sem divergencia"
		end

		def entry_change_label(entry)
			return "Primeiro marco" if entry.segment.previous_signature.blank?
			return "Sem mudanca desde o marco anterior" if entry.changed_fields.empty?

			"Mudou: #{human_changed_fields(entry.changed_fields).join(', ')}"
		end

		def human_changed_fields(fields)
			Array(fields).map do |field|
				case field.to_s
				when "nature"
					"Natureza"
				when "cp"
					"CP"
				when "irrf"
					"IRRF"
				when "fgts"
					"FGTS"
				else
					field.to_s.upcase
				end
			end
		end

		def comparison_badge_classes(row)
			return "tl-badge tl-badge--danger" if row.divergent
			return "tl-badge tl-badge--warning" if row.changed

			"tl-badge tl-badge--success"
		end

		def comparison_status_label(row)
			return "Divergente" if row.divergent
			return "Mudou no historico" if row.changed

			"Ok"
		end

		def action_label(action)
			case action.to_s
			when "inclusao"
				"Inclusao"
			when "alteracao"
				"Alteracao"
			when "exclusao"
				"Exclusao"
			else
				"Evento"
			end
		end

		def action_badge_classes(action)
			case action.to_s
			when "inclusao"
				"tl-badge tl-badge--success"
			when "alteracao"
				"tl-badge tl-badge--warning"
			when "exclusao"
				"tl-badge tl-badge--danger"
			else
				"tl-badge tl-badge--muted"
			end
		end

		def timeline_badge_classes(entry)
			return "tl-badge tl-badge--danger" if entry.divergence_kinds.any?
			return "tl-badge tl-badge--warning" if entry.changed_fields.any?

			"tl-badge tl-badge--success"
		end

		def timeline_node_classes(entry)
			classes = ["tl-event-rail-node"]
			classes << "tl-event-rail-node--active" if selected_entry&.segment&.id == entry.segment.id
			classes << "tl-event-rail-node--danger" if entry.divergence_kinds.any?
			classes << "tl-event-rail-node--warning" if entry.changed_fields.any? && entry.divergence_kinds.empty?
			classes.join(" ")
		end

		def period_label(segment)
			[segment.period_start.presence || "sem inicio", segment.period_end.presence || "vigente"].join(" -> ")
		end

		def expected_nature_for(entry)
			entry.finding&.expected_nature_code.presence || expected_summary.fetch("eSoc", ["0"]).join(", ")
		end

		def expected_indicator_for(entry, tax_kind)
			case tax_kind
			when "CP"
				entry.finding&.expected_cp_indicator.presence || expected_summary.fetch("CP", ["unknown"]).join(", ")
			when "IRRF"
				entry.finding&.expected_irrf_indicator.presence || expected_summary.fetch("IRRF", ["unknown"]).join(", ")
			when "FGTS"
				entry.finding&.expected_fgts_indicator.presence || expected_summary.fetch("FGTS", ["unknown"]).join(", ")
			else
				"unknown"
			end
		end

		def declared_code_for(entry, tax_kind)
			case tax_kind
			when "CP"
				entry.segment.cod_inc_cp
			when "IRRF"
				entry.segment.cod_inc_irrf
			when "FGTS"
				entry.segment.cod_inc_fgts
			end
		end

		def tax_divergent?(entry, tax_kind)
			case tax_kind
			when "CP"
				entry.finding&.cp_divergent?
			when "IRRF"
				entry.finding&.irrf_divergent?
			when "FGTS"
				entry.finding&.fgts_divergent?
			else
				false
			end
		end

		def tax_cell_classes(entry, tax_kind)
			tax_divergent?(entry, tax_kind) ? "tl-badge tl-badge--danger" : "tl-badge tl-badge--success"
		end

		private

		def queue_sort_key(rubric)
			status_rank = case rubric_status_label(rubric)
			when "Divergente"
				0
			when "Sem vinculo"
				1
			else
				2
			end

			[status_rank, -(priority_score(rubric) || 0), rubric.cte_code]
		end

		def comparison_row_for(entry, tax_kind)
			expected = expected_indicator_for(entry, tax_kind)
			declared = declared_code_for(entry, tax_kind)
			ComparisonRow.new(
				field: tax_kind,
				expected: expected_incidence_label(expected),
				declared: declared_incidence_label(tax_kind, declared),
				reading: incidence_reading(expected, declared),
				divergent: tax_divergent?(entry, tax_kind) || false,
				changed: entry.changed_fields.include?(tax_kind.downcase)
			)
		end

		def divergent_finding?(finding)
			Array(finding.divergence_kinds).any? { |kind| %w[nature cp irrf fgts].include?(kind.to_s) }
		end

		def nature_label(code)
			value = code.to_s.strip
			value.present? ? value : "Sem codigo"
		end

		def nature_reading(entry)
			expected = expected_nature_for(entry).to_s.strip
			declared = entry.segment.nat_rubr.to_s.strip
			return "Mesma natureza" if expected.present? && declared.present? && expected == declared
			return "Nao avaliada por falta de codigo" if expected.blank? || declared.blank?

			"CTE aponta #{expected}; S-1010 declarou #{declared}"
		end

		def expected_incidence_label(flag)
			case flag.to_s
			when "nao_incide"
				"Nao incide pela planilha CTE"
			when "incide"
				"Incide pela planilha CTE"
			else
				"Planilha CTE sem regra clara"
			end
		end

		def declared_incidence_label(_tax_kind, code)
			value = code.to_s.strip
			return "Sem codigo no XML" if value.blank?
			return "#{value} - nao incide" if value == "00" || value == "0"
			return "#{value} - incide/base mensal" if value == "11"
			return "#{value} - incide/13o" if value == "12"

			"#{value} - #{flag_label(IncidenceClassifier.declared_flag(value))}"
		end

		def incidence_reading(expected, declared_code)
			declared = IncidenceClassifier.declared_flag(declared_code)
			return "Nao avaliado por falta de regra/codigo" if expected == "unknown" || declared == "unknown"
			return "Mesma direcao: #{flag_label(expected)}" if expected == declared

			"Conflito: CTE #{flag_label(expected)}; S-1010 #{flag_label(declared)}"
		end

		def flag_label(flag)
			case flag.to_s
			when "nao_incide"
				"nao incide"
			when "incide"
				"incide"
			else
				"desconhecido"
			end
		end

		def expected_flags_for(mappings, tax_kind)
			flags = mappings.map { |mapping| mapping.incidence_profile&.dig(tax_kind, "flag") }.compact_blank.uniq
			flags.presence || ["unknown"]
		end

		def divergent_rubrics_count
			Finding.where("nature_divergent = TRUE OR cp_divergent = TRUE OR irrf_divergent = TRUE OR fgts_divergent = TRUE").distinct.count(:catalog_rubric_id)
		end

		def unlinked_rubrics_count
			CatalogRubric.left_outer_joins(:rubric_identity_link)
				.where("rubricas_cte_rubric_identity_links.id IS NULL OR rubricas_cte_rubric_identity_links.review_status <> ?", "matched")
				.distinct
				.count
		end

		def changed_rubrics_count
			S1010TimelineSegment.where.not(changed_fields: []).distinct.count(:s1010_key)
		end

		def search_sql
			<<~SQL.squish
				rubricas_cte_catalog_rubrics.cte_code ILIKE :query OR
				rubricas_cte_catalog_rubrics.description ILIKE :query OR
				rubricas_cte_rubric_identity_links.cod_rubr_raw ILIKE :query
			SQL
		end

		def apply_status(scope)
			case status
			when "all"
				scope
			when "linked"
				scope.where(rubricas_cte_rubric_identity_links: { review_status: "matched" })
			when "changed"
				scope.where.not(rubricas_cte_findings: { s1010_timeline_segment_id: nil })
					.where("EXISTS (SELECT 1 FROM rubricas_cte_s1010_timeline_segments s WHERE s.id = rubricas_cte_findings.s1010_timeline_segment_id AND s.changed_fields <> '[]'::jsonb)")
			when "divergent"
				scope.where("rubricas_cte_findings.nature_divergent = TRUE OR rubricas_cte_findings.cp_divergent = TRUE OR rubricas_cte_findings.irrf_divergent = TRUE OR rubricas_cte_findings.fgts_divergent = TRUE")
			when "unlinked"
				scope.where("rubricas_cte_rubric_identity_links.id IS NULL OR rubricas_cte_rubric_identity_links.review_status <> ?", "matched")
			else
				scope
			end
		end
	end
end