def upsert_by_code(model, attributes)
	record = model.find_or_initialize_by(code: attributes.fetch(:code))
	record.assign_attributes(attributes.except(:code))
	record.save!
	record
end

tax_reform = upsert_by_code(ProductArea, {
	code: "tax_reform",
	name: "Reforma Tributaria",
	description: "Tipo de trabalho voltado a simulacoes futuras de IBS/CBS, operacoes, redutores, creditos e cenarios.",
	position: 1
})

upsert_by_code(ProductArea, {
	code: "credit_recovery",
	name: "Recuperacao de Credito",
	description: "Tipo de trabalho voltado ao passado, com analise de verbas, rubricas, documentos, riscos e potencial de recuperacao.",
	position: 2
})

real_estate = upsert_by_code(Sector, {
	code: "real_estate_construction",
	name: "Imobiliario / Construcao Civil",
	description: "Primeiro recorte operacional do TributaLab, derivado da call com Denis e da planilha-base de 2026-05-28.",
	position: 1
})

tax_module = upsert_by_code(TaxModule, {
	code: "real_estate_tax_reform",
	name: "Reforma Tributaria Imobiliaria",
	description: "Modulo inicial para operacoes imobiliarias e de construcao civil sob a Reforma Tributaria.",
	product_area: tax_reform,
	sector: real_estate,
	status: "active",
	position: 1
})

tax_rule_version = TaxRuleVersion.find_or_initialize_by(tax_module:, code: "real_estate_tax_reform_v1")
tax_rule_version.assign_attributes(
	name: "Reforma Tributaria Imobiliaria v1",
	status: "pending_validation",
	effective_from: Date.new(2026, 5, 28),
	source_summary: "Versao inicial derivada da call com Denis e da planilha-base copiada em 2026-05-28.",
	notes: "Regra pendente de validacao juridica; usada para simulacoes internas da Etapa 002."
)
tax_rule_version.save!

case_file = CaseFile.find_or_initialize_by(reference_code: "RTI-VALIDACAO-001")
case_file.assign_attributes(
	name: "Caso interno de validacao - Reforma Tributaria Imobiliaria",
	description: "Caso inicial para agrupar simulacoes internas sem dados sensiveis de empresas reais.",
	status: "active",
	notes: "Criado na Etapa 003 para validacao guiada do modulo imobiliario."
)
case_file.save!

operations = [
	["sale_property", "Venda de imovel / incorporacao", "Operacao tributada sobre o valor da operacao, com redutor social e reducao de aliquota indicados na planilha.", "active"],
	["sale_residential_lot", "Venda de lote residencial", "Operacao tributada sobre o valor da venda, com redutor por lote residencial.", "active"],
	["lease_property", "Locacao de imoveis", "Operacao com redutor mensal e divergencia pendente sobre exclusao de IPTU e condominio da base.", "active"],
	["civil_construction", "Construcao civil", "Operacao baseada no valor do contrato, com creditos vinculados a materiais, servicos e energia.", "active"],
	["management_brokerage", "Administracao / corretagem", "Servicos imobiliarios com creditos vinculados a atividade, pendente confirmacao de ausencia de redutor.", "active"],
	["rights_assignment", "Cessao de direitos", "Operacao com divergencia entre reducao de 70% indicada em aba geral e aliquota cheia usada na aba de calculo.", "active"],
	["exchange_without_boot", "Permuta sem torna", "Operacao inicialmente tratada como sem incidencia, pendente definicao se tera tela propria.", "informational"],
	["exchange_with_boot", "Permuta com torna", "Operacao com incidencia parcial sobre o valor da torna e creditos vinculados.", "active"]
].each_with_index.to_h do |(code, name, description, status), index|
	operation = Operation.find_or_initialize_by(tax_module:, code:)
	operation.assign_attributes(name:, description:, status:, position: index + 1)
	operation.save!
	[code, operation]
end

parameters = [
	{ code: "full_ibs_cbs_rate", name: "Aliquota cheia IBS/CBS", parameter_type: "rate", value_decimal: "0.265", unit: "decimal", validation_status: "pending", operation: nil, legal_reference: "Planilha Denis - parametro usado nas simulacoes", notes: "Aliquota citada como 26,5%; parametrizavel porque pode mudar." },
	{ code: "sale_property_social_deduction", name: "Redutor venda imovel residencial", parameter_type: "deduction", value_decimal: 100_000, unit: "BRL", validation_status: "pending", operation: operations["sale_property"], legal_reference: "Art. 259 indicado na planilha", notes: "Deduz da base antes do imposto; base legal ainda depende de validacao LC 227/2026 vs LC 214/2025." },
	{ code: "sale_lot_social_deduction", name: "Redutor venda lote residencial", parameter_type: "deduction", value_decimal: 30_000, unit: "BRL", validation_status: "pending", operation: operations["sale_residential_lot"], legal_reference: "Art. 259 indicado na planilha", notes: "Deduz direto da base por lote residencial." },
	{ code: "lease_social_deduction", name: "Redutor locacao residencial", parameter_type: "deduction", value_decimal: 600, unit: "BRL", validation_status: "pending", operation: operations["lease_property"], legal_reference: "Art. 260 indicado na planilha", notes: "Valor mensal por imovel; formula da locacao ainda precisa validar tratamento de IPTU e condominio." },
	{ code: "sale_incorporation_reduction", name: "Reducao venda/incorporacao", parameter_type: "reduction", value_decimal: "0.5", unit: "decimal", validation_status: "pending", operation: operations["sale_property"], legal_reference: "Art. 261 caput indicado na planilha", notes: "Reducao inicial de 50% sobre a aliquota cheia." },
	{ code: "lot_sale_reduction", name: "Reducao venda de lote residencial", parameter_type: "reduction", value_decimal: "0.5", unit: "decimal", validation_status: "pending", operation: operations["sale_residential_lot"], legal_reference: "Art. 261 caput indicado na planilha", notes: "Aplicada por analogia ao bloco de venda/incorporacao da planilha." },
	{ code: "lease_reduction", name: "Reducao locacao", parameter_type: "reduction", value_decimal: "0.7", unit: "decimal", validation_status: "pending", operation: operations["lease_property"], legal_reference: "Art. 261, paragrafo unico indicado na planilha", notes: "Reducao inicial de 70%, pendente validacao final." },
	{ code: "rights_assignment_reduction", name: "Reducao cessao de direitos", parameter_type: "reduction", value_decimal: "0.7", unit: "decimal", validation_status: "divergent", operation: operations["rights_assignment"], legal_reference: "Aba Reducoes de Aliquotas vs Calculo Cessao de direitos", notes: "A aba geral indica reducao de 70%, mas a aba de calculo usa aliquota cheia." }
]

parameters.each do |attributes|
	record = TaxParameter.find_or_initialize_by(tax_module:, operation: attributes[:operation], code: attributes[:code])
	record.assign_attributes(attributes.merge(tax_module:))
	record.save!
end

assumptions = [
	["legal_basis_lc_version", "Confirmar LC 227/2026 vs LC 214/2025", nil, "A planilha esta nomeada como LC 227/2026, mas varias abas citam LC 214/2025.", "Define qual base legal e artigo devem aparecer nos calculos e relatorios."],
	["lease_deduct_iptu_condo", "Confirmar deducao de IPTU e condominio na locacao", operations["lease_property"], "A formula indica excluir IPTU e condominio da base, mas o exemplo usa aluguel integral.", "Afeta a base bruta e o imposto estimado de locacao."],
	["rights_assignment_rate", "Confirmar aliquota de cessao de direitos", operations["rights_assignment"], "A aba de reducoes menciona 70%, mas a aba de calculo usa aliquota cheia.", "Afeta debito IBS/CBS e comparativos de cessao."],
	["civil_construction_full_rate", "Confirmar construcao civil com aliquota cheia", operations["civil_construction"], "Modelo inicial usa aliquota cheia com creditos, sem reducao especifica.", "Afeta simulacao de contratos de construcao civil."],
	["management_brokerage_full_rate", "Confirmar administracao/corretagem sem redutor", operations["management_brokerage"], "Modelo inicial usa aliquota cheia e creditos vinculados, sem redutor ou reducao.", "Afeta servicos imobiliarios recorrentes."],
	["credit_documentation_conditions", "Confirmar condicoes documentais para creditos", nil, "Aproveitamento pode depender de documento, vinculacao direta e destaque do imposto.", "Afeta elegibilidade e risco de creditos informados."],
	["non_negative_tax_base", "Confirmar base negativa apos redutor", nil, "O sistema deve validar se base apos redutor vira zero por max(0, base - redutor).", "Evita imposto negativo ou base inconsistente."],
	["credit_exceeds_debit", "Confirmar tratamento de credito maior que debito", nil, "Pendente definir se credito excedente carrega saldo, zera imposto do periodo ou aparece apenas como excedente.", "Afeta imposto liquido e memoria de calculo."],
	["exchange_without_boot_screen", "Confirmar tela de permuta sem torna", operations["exchange_without_boot"], "Permuta sem torna aparece como sem incidencia no modelo inicial.", "Define se sera apenas informativa ou simulador proprio." ]
]

assumptions.each_with_index do |(code, title, operation, description, impact), index|
	assumption = Assumption.find_or_initialize_by(tax_module:, code:)
	assumption.assign_attributes(
		title:,
		operation:,
		description:,
		impact:,
		status: "pending",
		source_reference: "PESQUISAS_CTE_2026-05-28 / leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md",
		position: index + 1
	)
	assumption.save!
end

[
	["materials_construction", "Materiais de construcao", "Materiais como cimento, vergalhao, tubos, cabos, tintas, revestimentos, portas e vidros."],
	["engineering_services", "Servicos de engenharia", "Servicos vinculados a construcao civil."],
	["electricity", "Energia eletrica", "Energia vinculada a operacao ou atividade analisada."],
	["management_software", "Software de gestao", "Softwares de gestao imobiliaria e ferramentas vinculadas."],
	["legal_services", "Servicos juridicos", "Servicos juridicos vinculados a operacao."],
	["linked_brokerage", "Corretagem vinculada", "Corretagem diretamente vinculada a cessao, permuta ou atividade imobiliaria."],
	["financial_costs_boot", "Custos financeiros vinculados a torna", "Custos financeiros associados a permuta com torna."]
].each do |code, name, description|
	credit_category = CreditCategory.find_or_initialize_by(tax_module:, code:)
	credit_category.assign_attributes(
		name:,
		description:,
		validation_status: "pending",
		source_reference: "Planilha Denis - abas de creditos permitidos"
	)
	credit_category.save!
end

[
	["art_252", "LC 227/2026 ou LC 214/2025", "Art. 252", "Incidencia e base de calculo para operacoes imobiliarias conforme planilha."],
	["art_254_255", "LC 227/2026 ou LC 214/2025", "Art. 254-255", "Base de locacao indicada como aluguel sem IPTU/condominio."],
	["art_259", "LC 227/2026 ou LC 214/2025", "Art. 259", "Redutores para imovel residencial e lote residencial."],
	["art_260", "LC 227/2026 ou LC 214/2025", "Art. 260", "Redutor de locacao residencial."],
	["art_261", "LC 227/2026 ou LC 214/2025", "Art. 261", "Reducoes de aliquota para venda/incorporacao e locacao/cessao/arrendamento."]
].each do |code, law, article, description|
	legal_basis = LegalBasis.find_or_initialize_by(code:)
	legal_basis.assign_attributes(
		law:,
		article:,
		description:,
		source_reference: "Planilha Denis / leitura da tabela 2026-05-28",
		status: "pending",
		notes: "Pendente validar divergencia entre LC 227/2026 e LC 214/2025."
	)
	legal_basis.save!
end

RubricRecovery::AdequacyImporter.ensure_loaded!
