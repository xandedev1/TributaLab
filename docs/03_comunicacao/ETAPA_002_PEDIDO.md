# ETAPA 002 - Pedido

## Objetivo

Implementar calculos auditaveis do modulo Reforma Tributaria Imobiliaria para as quatro primeiras operacoes: venda de imovel/incorporacao, venda de lote residencial, locacao de imoveis e permuta com torna.

## Contexto

A Etapa 001 criou o esqueleto Rails, a modelagem inicial, seeds, fontes de pesquisa copiadas e tela operacional inicial. A revisao arquitetural aprovou a hierarquia `ProductArea -> Sector -> TaxModule -> Operation`, manteve `TaxModule` e pediu calculators por operacao, versionamento leve de regras e snapshots auditaveis.

## Escopo

- Criar `TaxRuleVersion` com migration, model, fixture, seed e testes.
- Associar `Simulation` a `TaxRuleVersion`.
- Criar calculators por operacao em `TaxRules::RealEstate`.
- Criar fluxo de persistencia de `Simulation` e `SimulationResult`.
- Criar UI minima para executar as quatro simulacoes.
- Salvar snapshots de inputs, parametros, assumptions, alertas, bases legais e versao de regra.
- Exibir alerta obrigatorio de divergencia na locacao.
- Criar testes para calculators, persistencia, snapshots e fluxo basico.
- Criar decisao tecnica e resposta final da etapa.

## Fora de escopo

- Login.
- Cadastro real de empresas.
- Multi-tenant.
- Recuperacao de credito.
- Importacao automatica da planilha.
- Relatorios finais.
- Motor tributario generico universal.
- NCM detalhado.
- Regras definitivas para pontos pendentes.
- Modulo completo de construcao civil, administracao/corretagem ou cessao de direitos.

## Criterios de aceite

- `TaxRuleVersion` existe e esta seedado.
- Calculators das quatro operacoes existem e usam `BigDecimal`/`decimal`, nao float.
- Simulacoes e resultados sao persistidos.
- Snapshots auditaveis sao salvos.
- UI minima executa as quatro simulacoes.
- Locacao exibe alerta de divergencia.
- `docs/02_decisoes/DECISAO_002_versionamento_regras_simulacoes.md` existe.
- `docs/03_comunicacao/ETAPA_002_RESPOSTA.md` existe.
- Testes passam ou falhas ficam documentadas.

## Restricoes

- Manter Rails 8.1.3, PostgreSQL, Tailwind/Hotwire e Minitest.
- Nao inventar regra tributaria ausente.
- Pontos pendentes devem continuar como assumptions/alertas.
- Interface e documentacao de negocio em portugues; codigo em ingles.

## Arquivos de referencia

- `docs/03_comunicacao/MD_002_PARA_AGENTE_IMPLEMENTACAO_RAILS.md`
- `docs/03_comunicacao/ETAPA_001_RESPOSTA.md`
- `docs/04_referencias/INDICE_FONTES.md`
- `docs/02_decisoes/DECISAO_001_setup_inicial.md`
- `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`
- `docs/00_brief/README_INICIAL_TRIBUTALAB.md`
- `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md`
- `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquitetura_inicial_sistema.md`

## Duvidas conhecidas

As perguntas pendentes continuam em `docs/03_comunicacao/PERGUNTAS_ABERTAS.md` e nao bloqueiam a Etapa 002.
