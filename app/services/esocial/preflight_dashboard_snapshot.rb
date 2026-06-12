module Esocial
	class PreflightDashboardSnapshot
		TARGET_COMPANY_CNPJ = "64030638000158"
		TARGET_COMPANY_NAME = "CTE - CENTRO DE TECNOLOGIA DE EDIFICACOES E HOLDING LTDA"

		Metric = Struct.new(:label, :value, :detail, keyword_init: true)
		Step = Struct.new(:label, :status, :detail, keyword_init: true) do
			def badge_status
				case status
				when "ok" then "completed"
				when "attention" then "pending"
				else "failed"
				end
			end
		end

		CertificateRow = Struct.new(:certificate, :authorization, :relationship_label, :relationship_status, keyword_init: true) do
			def ready_for_official_test?
				certificate.valid_now? && %w[direct verified declared].include?(relationship_status)
			end
		end

		def target_company_cnpj
			TARGET_COMPANY_CNPJ
		end

		def target_company_name
			TARGET_COMPANY_NAME
		end

		def certificates
			@certificates ||= EsocialCertificate.includes(:esocial_company_authorizations).order(active: :desc, expires_at: :desc, created_at: :desc)
		end

		def primary_certificate
			certificates.first
		end

		def legacy_certificate
			@legacy_certificate ||= LegacyCertificateInventory.call
		end

		def authorizations
			@authorizations ||= EsocialCompanyAuthorization.includes(:esocial_certificate).order(updated_at: :desc)
		end

		def rows
			@rows ||= certificates.map do |certificate|
				authorization = certificate.authorization_for(target_company_cnpj)
				CertificateRow.new(
					certificate: certificate,
					authorization: authorization,
					relationship_label: relationship_label(certificate, authorization),
					relationship_status: relationship_status(certificate, authorization)
				)
			end
		end

		def metrics
			[
				Metric.new(label: "Certificados", value: certificates.size, detail: legacy_certificate.available? ? "importados no TributaLab; legado detectado" : "importados no TributaLab"),
				Metric.new(label: "Validos agora", value: certificates.count(&:valid_now?), detail: "PFX abre e esta dentro da validade"),
				Metric.new(label: "Vinculos CTE", value: rows.count { |row| %w[direct verified declared].include?(row.relationship_status) }, detail: "titular direto ou procuracao cadastrada"),
				Metric.new(label: "Pode testar", value: ready_rows.size, detail: "sem consumir cota ate clicar em consulta oficial")
			]
		end

		def used_queries
			OfficialTablesSyncPlan.used_queries(Date.current)
		end

		def remaining_queries
			OfficialTablesSyncPlan.remaining_queries(Date.current)
		end

		def required_queries
			OfficialTablesSyncPlan::OPERATIONS.size
		end

		def enough_daily_balance?
			remaining_queries >= required_queries
		end

		def ready_for_official_query?
			best_row.present? && enough_daily_balance?
		end

		def official_gate_title
			return "Certificado pronto para consulta" if ready_for_official_query?
			return "Cota insuficiente para o plano" if best_row.present? && !enough_daily_balance?

			"Certificado pendente"
		end

		def official_gate_detail
			if ready_for_official_query?
				return "Certificado valido para a empresa. O proximo passo pode preparar S-1005 e S-1020 sem rodar script solto." if best_row.relationship_status == "direct"
				return "Certificado valido e procuracao confirmada. O proximo passo pode preparar S-1005 e S-1020." if best_row.relationship_status == "verified"

				"Certificado valido e procuracao informada. A primeira chamada oficial ainda e quem confirma se o eSocial aceita esse vinculo."
			elsif best_row.present?
				"Ha certificado candidato, mas o saldo local de hoje e #{remaining_queries}/#{OfficialTablesSyncPlan::DAILY_LIMIT}; o plano atual precisa de #{required_queries} chamadas."
			else
				"Importe um PFX A1 valido antes de criar nova consulta oficial."
			end
		end

		def candidate_label
			return "sem candidato" unless best_row

			"#{best_row.certificate.label} / #{best_row.relationship_label}"
		end

		def certificate_state_label
			return "Nenhum certificado" unless primary_certificate
			return "Pronto" if primary_certificate.valid_now?

			case primary_certificate.status
			when "expired" then "Vencido"
			when "not_yet_valid" then "Ainda nao valido"
			else "Precisa revisar"
			end
		end

		def connection_state_label
			return "Nao testada" unless primary_certificate

			primary_certificate.last_connection_test_status_label
		end

		def connection_state_detail
			return "Importe o certificado para liberar o teste." unless primary_certificate
			last_test = primary_certificate.last_connection_test
			return "Clique em testar para validar a conexao com o endpoint do eSocial." if last_test.blank?

			[primary_certificate.last_connection_test_message, last_test["tested_at"]].compact.join(" - ")
		end

		def steps
			[
				certificate_step,
				validity_step,
				relationship_step,
				official_test_step
			]
		end

		def ready_rows
			@ready_rows ||= rows.select(&:ready_for_official_test?)
		end

		def best_row
			ready_rows.find { |row| %w[direct verified].include?(row.relationship_status) } || ready_rows.first
		end

		private

		def certificate_step
			if certificates.any?
				Step.new(label: "Certificado A1", status: "ok", detail: "Ha certificado importado para avaliacao.")
			else
				Step.new(label: "Certificado A1", status: "attention", detail: "Importe um PFX A1 para iniciar.")
			end
		end

		def validity_step
			if certificates.any?(&:valid_now?)
				Step.new(label: "Validade", status: "ok", detail: "Pelo menos um certificado abre com senha e esta valido hoje.")
			elsif certificates.any?
				Step.new(label: "Validade", status: "error", detail: "Os certificados importados estao vencidos, futuros ou invalidos.")
			else
				Step.new(label: "Validade", status: "attention", detail: "A validade aparece depois do upload.")
			end
		end

		def relationship_step
			if rows.any? { |row| row.relationship_status == "direct" }
				Step.new(label: "Empresa", status: "ok", detail: "O titular do certificado e o CNPJ alvo.")
			elsif rows.any? { |row| row.relationship_status == "verified" }
				Step.new(label: "Empresa", status: "ok", detail: "Ha procuracao confirmada por retorno oficial.")
			elsif rows.any? { |row| row.relationship_status == "declared" }
				Step.new(label: "Empresa", status: "attention", detail: "Ha procuracao informada; a confirmacao vem na primeira chamada oficial.")
			else
				Step.new(label: "Empresa", status: "attention", detail: "Use o certificado da empresa ou informe uma procuracao.")
			end
		end

		def official_test_step
			if best_row&.relationship_status.in?(%w[direct verified])
				Step.new(label: "Consulta oficial", status: "ok", detail: "A proxima consulta pode testar o Download Cirurgico com baixo risco operacional.")
			elsif best_row
				Step.new(label: "Consulta oficial", status: "attention", detail: "Pode testar, mas a procuracao ainda nao esta confirmada pelo eSocial.")
			else
				Step.new(label: "Consulta oficial", status: "error", detail: "Ainda nao ha certificado valido para consultar.")
			end
		end

		def relationship_label(certificate, authorization)
			return "Titular direto" if certificate.direct_holder_for?(target_company_cnpj)
			return "Procuracao confirmada" if authorization&.verified?
			return "Procuracao informada" if authorization&.declared?
			return "Procuracao com falha" if authorization&.status == "failed"

			"Sem procuracao"
		end

		def relationship_status(certificate, authorization)
			return "direct" if certificate.direct_holder_for?(target_company_cnpj)
			return "verified" if authorization&.verified?
			return "declared" if authorization&.declared?
			return "failed" if authorization&.status == "failed"

			"missing"
		end
	end
end