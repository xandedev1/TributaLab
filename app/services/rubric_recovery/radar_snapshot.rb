module RubricRecovery
	class RadarSnapshot
		CONFIDENCE_ORDER = %w[ALTA MEDIA BAIXA MUITO_BAIXA].freeze
		CONFLICT_PATTERN_LABELS = {
			"CP+IRRF+FGTS" => "CP + IRRF + FGTS",
			"IRRF" => "Apenas IRRF",
			"CP+IRRF" => "CP + IRRF",
			"IRRF+FGTS" => "IRRF + FGTS",
			"FGTS" => "Apenas FGTS",
			"CP" => "Apenas CP"
		}.freeze
		EVIDENCE_TRAIL = [
			{ label: "CTE", status: "presente", state: :present, detail: "Tabela operacional usada no enquadramento inicial." },
			{ label: "Marco/enquadramento", status: "presente", state: :present, detail: "Ponte CTE -> Tabela 03/eSocial ja materializada." },
			{ label: "S-1010", status: "pendente nesta etapa", state: :pending, detail: "Adequacao historica fica para a camada 004C." },
			{ label: "EB/base legal", status: "pendente nesta etapa", state: :pending, detail: "Analise legal ainda nao cruzada na 004B." },
			{ label: "Folha", status: "pendente", state: :pending, detail: "Valores por trabalhador/rubrica ainda ausentes." },
			{ label: "Recolhimento", status: "pendente", state: :pending, detail: "DCTFWeb, DARF, GPS, SEFIP ou FGTS Digital ainda ausentes." },
			{ label: "Parecer", status: "pendente", state: :pending, detail: "Validacao tecnica/juridica ainda necessaria." }
		].map(&:freeze).freeze

		attr_reader :filters, :records

		def initialize(filters = {}, workbook: EnquadramentoWorkbook.new)
			@filters = filters.to_h.symbolize_keys
			@records = workbook.rows
		end

		def metrics
			[
				{ label: "Eventos analisados", value: total_events, detail: "#{total_events} eventos analisados", tone: :neutral },
				{ label: "Com divergencia", value: divergent_records.size, detail: "#{divergent_records.size} com pelo menos uma divergencia", tone: :warning },
				{ label: "Alta/media", value: high_medium_divergent_count, detail: "#{high_medium_divergent_count} registros/eventos divergentes com confianca alta/media", tone: :warning },
				{ label: "CP/INSS", value: cp_divergence_count, detail: "#{cp_divergence_count} divergencias CP/INSS", tone: :danger },
				{ label: "IRRF", value: irrf_divergence_count, detail: "#{irrf_divergence_count} divergencias IRRF", tone: :danger },
				{ label: "FGTS", value: fgts_divergence_count, detail: "#{fgts_divergence_count} divergencias FGTS", tone: :danger },
				{ label: "Sem divergencia", value: non_divergent_count, detail: "#{non_divergent_count} sem divergencia CP/IRRF/FGTS", tone: :success }
			]
		end

		def divergence_map
			with_percentages([
				{ key: "cp", label: "CP/INSS", value: cp_divergence_count, total: total_events },
				{ key: "irrf", label: "IRRF", value: irrf_divergence_count, total: total_events },
				{ key: "fgts", label: "FGTS", value: fgts_divergence_count, total: total_events }
			])
		end

		def confidence_distribution
			counts = records.group_by(&:confidence).transform_values(&:size)

			with_percentages(CONFIDENCE_ORDER.map do |confidence|
				{ key: confidence, label: confidence, value: counts.fetch(confidence, 0), total: total_events }
			end)
		end

		def conflict_patterns
			counts = divergent_records.group_by(&:conflict_pattern).transform_values(&:size)

			CONFLICT_PATTERN_LABELS.map do |key, label|
				{ key: key, label: label, value: counts.fetch(key, 0) }
			end
		end

		def group_conflicts
			divergent_records
				.group_by(&:normalized_group)
				.map { |group, group_records| { key: group, label: group_records.first.group_label, value: group_records.size } }
				.sort_by { |group| [-group[:value], group[:label]] }
				.first(7)
		end

		def evidence_trail
			EVIDENCE_TRAIL
		end

		def rubrics
			filtered_records.map(&:to_radar_row)
		end

		def tax_options
			[["Todos", ""], ["CP/INSS", "cp"], ["IRRF", "irrf"], ["FGTS", "fgts"]]
		end

		def confidence_options
			[["Todas", ""]] + CONFIDENCE_ORDER.map { |confidence| [confidence, confidence] }
		end

		def group_options
			[["Todos", ""]] + divergent_records
				.group_by(&:normalized_group)
				.map { |group, group_records| [group_records.first.group_label, group] }
				.sort_by(&:first)
		end

		def conflict_pattern_options
			[["Todos", ""]] + conflict_patterns.reject { |pattern| pattern[:value].zero? }.map { |pattern| [pattern[:label], pattern[:key]] }
		end

		def high_medium_only?
			filters[:priority] == "high_medium"
		end

		def total_events
			records.size
		end

		def divergent_records
			@divergent_records ||= records.select(&:divergent?)
		end

		private

		def filtered_records
			divergent_records.select { |record| matches_filters?(record) }
		end

		def matches_filters?(record)
			return false if filters[:tax].present? && record.public_send("#{filters[:tax]}_status") != "Divergente"
			return false if filters[:confidence].present? && record.confidence != filters[:confidence]
			return false if filters[:group].present? && record.normalized_group != filters[:group]
			return false if filters[:conflict_pattern].present? && record.conflict_pattern != filters[:conflict_pattern]
			return false if high_medium_only? && !%w[ALTA MEDIA].include?(record.confidence)

			true
		end

		def high_medium_divergent_count
			divergent_records.count { |record| %w[ALTA MEDIA].include?(record.confidence) }
		end

		def cp_divergence_count
			records.count { |record| record.cp_status == "Divergente" }
		end

		def irrf_divergence_count
			records.count { |record| record.irrf_status == "Divergente" }
		end

		def fgts_divergence_count
			records.count { |record| record.fgts_status == "Divergente" }
		end

		def non_divergent_count
			records.count { |record| !record.divergent? }
		end

		def with_percentages(items)
			items.map do |item|
				item.merge(percentage: item[:total].positive? ? ((item[:value].to_f / item[:total]) * 100).round(1) : 0)
			end
		end
	end
end