require "set"

module RubricRecovery
	class TextNormalizer
		STOPWORDS = %w[a ao aos as de da das do dos e em na nas no nos o os ou para por com sem sobre um uma].freeze
		DOMAIN_PATTERNS = {
			"salario" => [/\bsalario\b/, /\bsalarial\b/, /\bvencimento\b/, /\bremuneracao\b/, /\bsoldo\b/],
			"hora_extra" => [/\bh\s*extra\b/, /\bhora\s+extra\b/, /\bhoras\s+extras\b/, /\bextraordinaria/],
			"dsr" => [/\bdsr\b/, /descanso\s+semanal/, /repouso\s+remunerado/, /\bferiado\b/],
			"ferias" => [/\bferias\b/, /\bferia\b/],
			"terco_ferias" => [/1\s*\/\s*3/, /\bterco\b/, /terco\s+constitucional/],
			"decimo_terceiro" => [/\b13\b/, /\b13o\b/, /decimo\s+terceiro/, /gratificacao\s+natalina/],
			"auxilio" => [/\baux\b/, /\bauxilio\b/],
			"maternidade" => [/maternidade/, /salario\s+maternidade/, /\bmater\b/],
			"doenca" => [/doenca/, /auxilio\s+doenca/],
			"acidente" => [/acidente/, /acidente\s+trabalho/],
			"aviso_previo" => [/aviso\s+previo/, /\bapi\b/],
			"aviso_indenizado" => [/aviso.*indeniz/, /indeniz.*aviso/],
			"aviso_trabalhado" => [/aviso\s+previo\s+trabalhad[oa]/],
			"rescisao" => [/rescisao/, /rescisorio/],
			"indenizacao" => [/indeniz/],
			"adiantamento" => [/\badto\b/, /adiantad/, /adiantamento/],
			"noturno" => [/\bnot\b/, /noturn/],
			"insalubridade" => [/insalubridade/],
			"periculosidade" => [/periculosidade/],
			"estagio" => [/\bbolsa\b/, /estagio/, /estagiario/],
			"alimentacao" => [/\bvr\b/, /\bva\b/, /vale\s+refeicao/, /vale\s+alimentacao/, /alimentacao/],
			"transporte" => [/\bvt\b/, /vale\s+transporte/, /transporte/],
			"assistencia_medica" => [/assistencia\s+medica/, /\bmedica\b/, /odontologica/, /plano\s+de\s+saude/],
			"consignado" => [/econsignado/, /consignado/, /emprestimo/],
			"desconto" => [/desconto/, /desc\b/],
			"reembolso" => [/reembolso/, /ressarcimento/]
		}.freeze

		def self.normalize(text)
			new.normalize(text)
		end

		def self.tokens(text)
			new.tokens(text)
		end

		def self.domain_terms(text)
			new.domain_terms(text)
		end

		def normalize(text)
			value = I18n.transliterate(text.to_s).downcase
			value.gsub!(/13[ºo]?/, " 13 decimo terceiro ")
			value.gsub!(/1\s*\/\s*3/, " 1/3 terco constitucional ")
			value.gsub!(/h\.\s*extra/, " hora extra ")
			value.gsub!(/a\.\s*p\.\s*i\.?/, " aviso previo indenizado ")
			value.gsub!(/e\s*consignado/, " econsignado consignado ")
			value.gsub!(/[^a-z0-9\/]+/, " ")
			value.squish
		end

		def tokens(text)
			normalize(text).split.reject { |token| STOPWORDS.include?(token) }
		end

		def domain_terms(text)
			normalized = normalize(text)
			DOMAIN_PATTERNS.each_with_object(Set.new) do |(term, patterns), terms|
				terms << term if patterns.any? { |pattern| normalized.match?(pattern) }
			end
		end
	end
end