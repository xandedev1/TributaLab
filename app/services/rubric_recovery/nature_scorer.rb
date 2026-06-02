module RubricRecovery
	class NatureScorer
		VERSION = "nature-score-v2"
		ScoreResult = Struct.new(:score, :confidence_label, :positive_signals, :penalties, :incidence_alignment, keyword_init: true)

		def initialize(normalizer: TextNormalizer.new, incidence_comparator: IncidenceComparator.new)
			@normalizer = normalizer
			@incidence_comparator = incidence_comparator
		end

		def call(event, nature)
			positive_signals = []
			penalties = []
			score = 0.0

			event_tokens = normalizer.tokens(event.description)
			name_tokens = normalizer.tokens(nature.name)
			description_tokens = normalizer.tokens(nature.description)
			event_terms = normalizer.domain_terms(event.description)
			nature_terms = normalizer.domain_terms([nature.name, nature.description].join(" "))

			name_score = overlap_score(event_tokens, name_tokens, 3.0)
			score += name_score
			positive_signals << "descricao conversa com o nome da natureza" if name_score >= 1.2

			description_score = overlap_score(event_tokens, description_tokens, 2.0)
			score += description_score
			positive_signals << "descricao longa da Tabela 03 contem termos da rubrica" if description_score >= 0.8

			category_intersection = event_terms & nature_terms
			if category_intersection.any?
				category_score = [0.75 + (category_intersection.size * 0.45), 2.0].min
				score += category_score
				positive_signals << "categoria de dominio: #{category_intersection.to_a.sort.join(', ')}"
			end

			incidence_alignment = incidence_alignment_for(event, nature)
			incidence_score = incidence_alignment.values.sum { |item| item[:score].to_f }
			score += incidence_score
			positive_signals << "incidencias CTE proximas da Tabela 03" if incidence_score >= 1.0

			type_score = type_score(event, nature, event_terms, nature_terms)
			score += type_score
			positive_signals << "tipo operacional compativel" if type_score >= 0.7

			phrase_bonus = strong_phrase_bonus(event_terms, nature_terms)
			score += phrase_bonus
			positive_signals << "frase forte ou termo especifico preservado" if phrase_bonus.positive?

			penalty_total = apply_penalties(event_terms, nature_terms, penalties)
			score -= penalty_total

			final_score = [[score, 0.0].max, 10.0].min.round(2)
			ScoreResult.new(
				score: final_score,
				confidence_label: confidence_label(final_score),
				positive_signals: positive_signals.uniq,
				penalties: penalties.uniq,
				incidence_alignment: incidence_alignment
			)
		end

		private

		attr_reader :normalizer, :incidence_comparator

		def overlap_score(source_tokens, target_tokens, max_score)
			return 0.0 if source_tokens.empty? || target_tokens.empty?

			overlap = source_tokens.to_set & target_tokens.to_set
			ratio = overlap.size.to_f / source_tokens.to_set.size
			(max_score * ratio).round(2)
		end

		def incidence_alignment_for(event, nature)
			{
				cp: incidence_comparator.alignment(event.inm, nature.cod_inc_cp, :cp),
				irrf: incidence_comparator.alignment(event.irm, nature.cod_inc_irrf, :irrf),
				fgts: incidence_comparator.alignment(event.fn, nature.cod_inc_fgts, :fgts)
			}
		end

		def type_score(event, _nature, event_terms, nature_terms)
			return 1.0 if event_terms.include?("desconto") && nature_terms.include?("desconto")
			return 0.8 if event.tp.to_s == "4" && nature_terms.include?("desconto")
			return 0.8 if event_terms.include?("adiantamento") && nature_terms.include?("adiantamento")
			return 0.6 if event.tp.to_s == "1" && !nature_terms.include?("desconto")

			0.2
		end

		def strong_phrase_bonus(event_terms, nature_terms)
			strong_terms = %w[terco_ferias decimo_terceiro maternidade estagio aviso_indenizado insalubridade periculosidade consignado assistencia_medica]
			(strong_terms & event_terms.to_a & nature_terms.to_a).any? ? 0.5 : 0.0
		end

		def apply_penalties(event_terms, nature_terms, penalties)
			total = 0.0

			penalize(total, penalties, 3.5, "rubrica fala 13o, natureza nao") if event_terms.include?("decimo_terceiro") && !nature_terms.include?("decimo_terceiro")
			total += 3.5 if event_terms.include?("decimo_terceiro") && !nature_terms.include?("decimo_terceiro")
			penalties << "natureza fala 13o, rubrica nao" if !event_terms.include?("decimo_terceiro") && nature_terms.include?("decimo_terceiro")
			total += 3.0 if !event_terms.include?("decimo_terceiro") && nature_terms.include?("decimo_terceiro")

			penalties << "rubrica fala 1/3, natureza nao e terco de ferias" if event_terms.include?("terco_ferias") && !nature_terms.include?("terco_ferias")
			total += 4.0 if event_terms.include?("terco_ferias") && !nature_terms.include?("terco_ferias")
			penalties << "rubrica fala ferias, natureza nao e de ferias" if event_terms.include?("ferias") && !(nature_terms.include?("ferias") || nature_terms.include?("terco_ferias"))
			total += 2.5 if event_terms.include?("ferias") && !(nature_terms.include?("ferias") || nature_terms.include?("terco_ferias"))

			penalties << "rubrica fala maternidade, natureza nao e maternidade" if event_terms.include?("maternidade") && !nature_terms.include?("maternidade")
			total += 3.0 if event_terms.include?("maternidade") && !nature_terms.include?("maternidade")
			penalties << "rubrica fala estagio/bolsa, natureza nao e estagio" if event_terms.include?("estagio") && !nature_terms.include?("estagio")
			total += 3.0 if event_terms.include?("estagio") && !nature_terms.include?("estagio")
			penalties << "rubrica fala aviso indenizado, natureza nao trata aviso indenizado" if event_terms.include?("aviso_indenizado") && !nature_terms.include?("aviso_indenizado")
			total += 3.0 if event_terms.include?("aviso_indenizado") && !nature_terms.include?("aviso_indenizado")
			penalties << "aviso indenizado nao deve cair em aviso trabalhado" if event_terms.include?("aviso_indenizado") && nature_terms.include?("aviso_trabalhado")
			total += 3.0 if event_terms.include?("aviso_indenizado") && nature_terms.include?("aviso_trabalhado")

			penalties << "rubrica fala desconto, natureza nao e desconto" if event_terms.include?("desconto") && !nature_terms.include?("desconto")
			total += 2.5 if event_terms.include?("desconto") && !nature_terms.include?("desconto")
			penalties << "natureza fala adiantamento, rubrica nao" if !event_terms.include?("adiantamento") && nature_terms.include?("adiantamento")
			total += 1.8 if !event_terms.include?("adiantamento") && nature_terms.include?("adiantamento")
			penalties << "natureza fala terco de ferias, rubrica nao" if !event_terms.include?("terco_ferias") && nature_terms.include?("terco_ferias")
			total += 1.4 if !event_terms.include?("terco_ferias") && nature_terms.include?("terco_ferias")
			penalties << "rubrica indenizatoria/assistencial nao deve cair em natureza salarial comum" if (event_terms & %w[reembolso assistencia_medica consignado]).any? && nature_terms.include?("salario")
			total += 2.0 if (event_terms & %w[reembolso assistencia_medica consignado]).any? && nature_terms.include?("salario")

			total
		end

		def penalize(_total, penalties, _amount, message)
			penalties << message
		end

		def confidence_label(score)
			case score
			when 8.5..10
				"sugestao forte"
			when 7.0...8.5
				"boa sugestao"
			when 5.0...7.0
				"sugestao media"
			else
				"baixa confianca"
			end
		end
	end
end