module RubricasCte
	class DashboardSnapshot
		Metric = Struct.new(:label, :value, :detail, keyword_init: true)

		def initialize(filters = {})
			@query = filters[:q].to_s.strip
			@status = filters[:status].to_s.strip
		end

		attr_reader :query, :status

		def metrics
			@metrics ||= [
				Metric.new(label: "Rubricas CTE", value: total_rubrics, detail: "catalogo importado da planilha"),
				Metric.new(label: "Com eSoc != 0", value: rubrics_with_nonzero_esoc, detail: "natureza esperada direta"),
				Metric.new(label: "Com eSoc = 0", value: rubrics_without_nonzero_esoc, detail: "sem natureza direta nesta fonte"),
				Metric.new(label: "Vinculadas S-1010", value: linked_rubrics, detail: "match unico inicial"),
				Metric.new(label: "Sem vinculo unico", value: unlinked_rubrics, detail: "unmatched ou ambiguas"),
				Metric.new(label: "Divergencia natureza", value: divergent_rubrics(:nature_divergent), detail: "eSoc x natRubr"),
				Metric.new(label: "Divergencia CP", value: divergent_rubrics(:cp_divergent), detail: "indicador CTE x codIncCP"),
				Metric.new(label: "Divergencia IRRF", value: divergent_rubrics(:irrf_divergent), detail: "indicador CTE x codIncIRRF"),
				Metric.new(label: "Divergencia FGTS", value: divergent_rubrics(:fgts_divergent), detail: "indicador CTE x codIncFGTS")
			]
		end

		def rubrics
			@rubrics ||= begin
				scope = CatalogRubric.includes(:expected_mappings, :rubric_identity_link, :findings).ordered
				scope = scope.where("cte_code ILIKE :query OR description ILIKE :query", query: "%#{query}%") if query.present?
				scope = apply_status(scope) if status.present?
				scope.limit(200).to_a
			end
		end

		def status_options
			[
				["Todos", ""],
				["Vinculadas", "linked"],
				["Sem vinculo unico", "unlinked"],
				["Divergencia natureza", "nature"],
				["Divergencia CP", "cp"],
				["Divergencia IRRF", "irrf"],
				["Divergencia FGTS", "fgts"],
				["Nao avaliadas", "not_evaluated"]
			]
		end

		def expected_natures_for(rubric)
			codes = rubric.nonzero_esocial_nature_codes
			codes.any? ? codes.join(", ") : "0"
		end

		def link_label(rubric)
			link = rubric.rubric_identity_link
			return "sem link" unless link

			case link.review_status
			when "matched"
				"#{link.cod_rubr_raw}"
			when "ambiguous"
				"ambiguo"
			else
				"sem vinculo"
			end
		end

		def link_badge_class(rubric)
			case rubric.rubric_identity_link&.review_status
			when "matched"
				"tl-badge tl-badge--success"
			when "ambiguous"
				"tl-badge tl-badge--warning"
			else
				"tl-badge tl-badge--muted"
			end
		end

		def finding_counts(rubric)
			findings = rubric.findings
			{
				nature: findings.count(&:nature_divergent),
				cp: findings.count(&:cp_divergent),
				irrf: findings.count(&:irrf_divergent),
				fgts: findings.count(&:fgts_divergent),
				not_evaluated: findings.count { |finding| finding.divergence_kind == "not_evaluated" }
			}
		end

		def first_period(rubric)
			finding = rubric.findings.min_by { |candidate| candidate.period_start.to_s }
			return "-" unless finding&.period_start.present?

			[finding.period_start, finding.period_end].compact.join(" -> ")
		end

		private

		def total_rubrics
			CatalogRubric.count
		end

		def rubrics_with_nonzero_esoc
			CatalogRubric.joins(:expected_mappings).merge(ExpectedMapping.nonzero_esocial).distinct.count
		end

		def rubrics_without_nonzero_esoc
			total_rubrics - rubrics_with_nonzero_esoc
		end

		def linked_rubrics
			RubricIdentityLink.where(review_status: "matched").count
		end

		def unlinked_rubrics
			RubricIdentityLink.where.not(review_status: "matched").count
		end

		def divergent_rubrics(column)
			Finding.where(column => true).distinct.count(:catalog_rubric_id)
		end

		def apply_status(scope)
			case status
			when "linked"
				scope.joins(:rubric_identity_link).where(rubricas_cte_rubric_identity_links: { review_status: "matched" })
			when "unlinked"
				scope.joins(:rubric_identity_link).where.not(rubricas_cte_rubric_identity_links: { review_status: "matched" })
			when "nature"
				scope.joins(:findings).where(rubricas_cte_findings: { nature_divergent: true }).distinct
			when "cp"
				scope.joins(:findings).where(rubricas_cte_findings: { cp_divergent: true }).distinct
			when "irrf"
				scope.joins(:findings).where(rubricas_cte_findings: { irrf_divergent: true }).distinct
			when "fgts"
				scope.joins(:findings).where(rubricas_cte_findings: { fgts_divergent: true }).distinct
			when "not_evaluated"
				scope.joins(:findings).where(rubricas_cte_findings: { divergence_kind: "not_evaluated" }).distinct
			else
				scope
			end
		end
	end
end