require "pathname"
require "rexml/document"
require "zip"

module Esocial
	class PrevidenciaryProcessAnalyzer
		Suspension = Data.define(:code, :indicator, :decision_date, :full_deposit)
		ProcessRecord = Data.define(
			:source,
			:event_id,
			:receipt,
			:employer_registration,
			:action,
			:process_type,
			:process_number,
			:valid_from,
			:valid_until,
			:subject_indicator,
			:suspensions
		)
		RubricLink = Data.define(
			:source,
			:event_id,
			:receipt,
			:employer_registration,
			:action,
			:rubric_code,
			:table_identifier,
			:valid_from,
			:valid_until,
			:previdenciary_incidence,
			:process_type,
			:process_number,
			:decision_scope,
			:suspension_code
		)
		LotationLink = Data.define(
			:source,
			:event_id,
			:receipt,
			:employer_registration,
			:action,
			:lotation_code,
			:valid_from,
			:valid_until,
			:fpas,
			:third_party_code,
			:suspended_third_party_code,
			:third_party_entity_code,
			:process_number,
			:suspension_code
		)
		Match = Data.define(:rubric_link, :processes)
		LotationMatch = Data.define(:lotation_link, :processes)
		Result = Data.define(
			:processes,
			:rubric_links,
			:matches,
			:unmatched_links,
			:lotation_links,
			:lotation_matches,
			:unmatched_lotation_links,
			:errors
		)

		def initialize(paths)
			@paths = Array(paths).map { |path| Pathname(path) }
			@processes = []
			@rubric_links = []
			@lotation_links = []
			@errors = []
		end

		def call
			@paths.each { |path| read_path(path) }
			matches, unmatched_links = match_links
			lotation_matches, unmatched_lotation_links = match_lotation_links

			Result.new(
				processes: @processes.freeze,
				rubric_links: @rubric_links.freeze,
				matches: matches.freeze,
				unmatched_links: unmatched_links.freeze,
				lotation_links: @lotation_links.freeze,
				lotation_matches: lotation_matches.freeze,
				unmatched_lotation_links: unmatched_lotation_links.freeze,
				errors: @errors.freeze
			)
		end

		private

		def read_path(path)
			unless path.exist?
				@errors << { source: path.to_s, error: "Arquivo ou diretório não encontrado" }
				return
			end

			if path.directory?
				path.glob("**/*").select(&:file?).sort.each { |entry| read_path(entry) }
			elsif path.extname.casecmp?(".xml")
				parse_xml(path.binread, path.to_s)
			elsif path.extname.casecmp?(".zip")
				read_zip(path.binread, path.to_s)
			end
		rescue StandardError => error
			@errors << { source: path.to_s, error: error.message }
		end

		def read_zip(buffer, source)
			Zip::File.open_buffer(buffer) do |zip|
				zip.entries.reject(&:directory?).sort_by(&:name).each do |entry|
					entry_source = "#{source}/#{entry.name}"
					if File.extname(entry.name).casecmp?(".xml")
						parse_xml(entry.get_input_stream.read, entry_source)
					elsif File.extname(entry.name).casecmp?(".zip")
						read_zip(entry.get_input_stream.read, entry_source)
					end
				end
			end
		rescue StandardError => error
			@errors << { source: source, error: error.message }
		end

		def parse_xml(xml, source)
			document = REXML::Document.new(xml)
			if (event = descendant(document, "evtTabProcesso"))
				parse_process(document, event, source)
			elsif (event = descendant(document, "evtTabRubrica"))
				parse_rubric_links(document, event, source)
			elsif (event = descendant(document, "evtTabLotacao"))
				parse_lotation_links(document, event, source)
			end
		rescue StandardError => error
			@errors << { source: source, error: error.message }
		end

		def parse_process(document, event, source)
			action = action_node(descendant(event, "infoProcesso"))
			return unless action

			identity = descendant(action, "ideProcesso")
			data = descendant(action, "dadosProc")
			suspensions = descendants(data, "infoSusp").map do |node|
				Suspension.new(
					code: text(node, "codSusp"),
					indicator: text(node, "indSusp"),
					decision_date: text(node, "dtDecisao"),
					full_deposit: text(node, "indDeposito")
				)
			end

			@processes << ProcessRecord.new(
				source: source,
				event_id: event.attributes["Id"],
				receipt: text(document, "nrRecibo"),
				employer_registration: text(descendant(event, "ideEmpregador"), "nrInsc"),
				action: action.name,
				process_type: text(identity, "tpProc"),
				process_number: text(identity, "nrProc"),
				valid_from: text(identity, "iniValid"),
				valid_until: text(identity, "fimValid"),
				subject_indicator: text(data, "indMatProc"),
				suspensions: suspensions.freeze
			)
		end

		def parse_rubric_links(document, event, source)
			action = action_node(descendant(event, "infoRubrica"))
			return unless action

			identity = descendant(action, "ideRubrica")
			data = descendant(action, "dadosRubrica")
			descendants(data, "ideProcessoCP").each do |process|
				@rubric_links << RubricLink.new(
					source: source,
					event_id: event.attributes["Id"],
					receipt: text(document, "nrRecibo"),
					employer_registration: text(descendant(event, "ideEmpregador"), "nrInsc"),
					action: action.name,
					rubric_code: text(identity, "codRubr"),
					table_identifier: text(identity, "ideTabRubr"),
					valid_from: text(identity, "iniValid"),
					valid_until: text(identity, "fimValid"),
					previdenciary_incidence: text(data, "codIncCP"),
					process_type: text(process, "tpProc"),
					process_number: text(process, "nrProc"),
					decision_scope: text(process, "extDecisao"),
					suspension_code: text(process, "codSusp")
				)
			end
		end

		def parse_lotation_links(document, event, source)
			action = action_node(descendant(event, "infoLotacao"))
			return unless action

			identity = descendant(action, "ideLotacao")
			data = descendant(action, "dadosLotacao")
			fpas_data = descendant(data, "fpasLotacao")
			descendants(fpas_data, "procJudTerceiro").each do |process|
				@lotation_links << LotationLink.new(
					source: source,
					event_id: event.attributes["Id"],
					receipt: text(document, "nrRecibo"),
					employer_registration: text(descendant(event, "ideEmpregador"), "nrInsc"),
					action: action.name,
					lotation_code: text(identity, "codLotacao"),
					valid_from: text(identity, "iniValid"),
					valid_until: text(identity, "fimValid"),
					fpas: text(fpas_data, "fpas"),
					third_party_code: text(fpas_data, "codTercs"),
					suspended_third_party_code: text(fpas_data, "codTercsSusp"),
					third_party_entity_code: text(process, "codTerc"),
					process_number: text(process, "nrProcJud"),
					suspension_code: text(process, "codSusp")
				)
			end
		end

		def match_links
			index = Hash.new { |hash, key| hash[key] = [] }
			@processes.each do |process|
				process.suspensions.each do |suspension|
					index[process_key(process.employer_registration, process.process_type, process.process_number, suspension.code)] << process
				end
			end

			matched = []
			unmatched = []
			@rubric_links.each do |link|
				processes = index[process_key(link.employer_registration, link.process_type, link.process_number, link.suspension_code)]
				if processes.empty?
					unmatched << link
				else
					matched << Match.new(rubric_link: link, processes: processes.freeze)
				end
			end

			[matched, unmatched]
		end

		def match_lotation_links
			index = process_index
			matched = []
			unmatched = []
			@lotation_links.each do |link|
				processes = index[process_key(link.employer_registration, "2", link.process_number, link.suspension_code)]
				if processes.empty?
					unmatched << link
				else
					matched << LotationMatch.new(lotation_link: link, processes: processes.freeze)
				end
			end

			[matched, unmatched]
		end

		def process_index
			@processes.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |process, index|
				process.suspensions.each do |suspension|
					index[process_key(process.employer_registration, process.process_type, process.process_number, suspension.code)] << process
				end
			end
		end

		def process_key(employer, type, number, suspension_code)
			[employer.to_s.gsub(/\D/, ""), type.to_s, number.to_s.gsub(/\D/, ""), suspension_code.to_s.sub(/\A0+/, "")]
		end

		def action_node(info_node)
			info_node&.elements&.find { |element| %w[inclusao alteracao exclusao].include?(element.name) }
		end

		def descendant(node, name)
			return nil unless node

			node.each_element do |element|
				return element if element.name == name

				found = descendant(element, name)
				return found if found
			end

			nil
		end

		def descendants(node, name, found = [])
			return found unless node

			node.each_element do |element|
				found << element if element.name == name
				descendants(element, name, found)
			end
			found
		end

		def text(node, name)
			descendant(node, name)&.text.to_s.strip
		end
	end
end