# MD 009 - Handoff Unico para Outra IA

Data: 2026-06-01
Projeto: Prev Lab
Repo alvo: `C:\Users\xandao\Documents\GitHub\TributaLab`

Este documento e o resumo unico para outra IA ler antes de continuar qualquer trabalho no Prev Lab. Ele junta contexto de produto, regras duras, o que ja foi implementado, validacoes executadas e proximos cuidados.

## 1. Contexto rapido

Prev Lab e um app Rails operacional para trabalho previdenciario/fiscal, simulacoes, casos internos e revisao de rubricas/eSocial. O repositorio e o modulo Rails ainda usam nomes tecnicos antigos em alguns caminhos internos, como `TributaLab`, mas a marca exibida ao usuario agora e Prev Lab.

Stack atual observada e mantida:

- Rails 8.1.3.
- ERB views.
- Hotwire/Turbo/Stimulus.
- Tailwind via `tailwindcss-rails`.
- Importmap.
- PostgreSQL local.
- Nao existe `package.json`.

Rotas principais:

```text
/
/case_files
/simulations
/simulations/new
/rubric_recovery/radar
/rubric_recovery/adequacy
/rubric_recovery/rubrics_natures
/legal_basis
/tax_parameters
/assumptions
```

## 2. Regras duras

Nao fazer:

- Nao consultar eSocial sem pedido explicito do usuario.
- Nao rodar scripts de download/consulta eSocial.
- Nao chamar `consultar_lote`, `solicitar_download`, `consultar_identificadores` ou similares.
- Nao implementar calculo financeiro de credito recuperavel sem aprovacao.
- Nao exibir promessa de valor recuperavel, economia garantida ou credito em reais.
- Nao mexer em scoring, importacao, calculadoras ou regra fiscal se a tarefa for apenas frontend.
- Nao migrar Rails/ERB para React/Next.
- Nao adicionar `package.json`, Motion, GSAP, shadcn, lucide ou dependencia frontend sem aprovacao.
- Nao apagar rotas existentes.
- Nao usar a tabela `explorador_eventos` como fonte de recibo.

Regra critica eSocial:

- O Download Cirurgico tem limite de 10 consultas/dia.
- Erro `500 ServiceActivationException` pode significar limite diario atingido, nao servico fora.
- Qualquer consulta real ao eSocial precisa de permissao explicita do usuario.

## 3. O que foi implementado na Etapa 004B

Etapa 004B: importacao/navegacao real do `arquivo_enquadrado`, sem S-1010.

Arquivos/documento principais:

- `app/services/rubric_recovery/enquadramento_workbook.rb`
- `app/services/rubric_recovery/radar_snapshot.rb`
- `app/views/rubric_recovery/radar/show.html.erb`
- `test/controllers/rubric_recovery/radar_controller_test.rb`
- `test/services/rubric_recovery/radar_snapshot_test.rb`
- `docs/03_comunicacao/ETAPA_004B_RESPOSTA.md`

Fonte usada:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquivo_enquadrado_2026-05-29.xlsx
```

Numeros reais recalculados no radar:

- 464 eventos analisados.
- 247 com pelo menos uma divergencia.
- 224 registros/eventos divergentes com confianca alta/media.
- 140 divergencias CP/INSS.
- 245 divergencias IRRF.
- 126 divergencias FGTS.
- 217 sem divergencia CP/IRRF/FGTS.

Limite da 004B:

- Sem parser S-1010.
- Sem persistencia dos registros em banco.
- Sem folha, recolhimentos ou calculo financeiro.

## 4. O que foi implementado na Etapa 004C

Etapa 004C: Adequacao S-1010 via Pontuacao de Naturezas.

Objetivo implementado:

- Ler a planilha Marcos + Tab03.
- Persistir eventos/rubricas CTE.
- Persistir naturezas eSocial preservando duplicidades por vigencia.
- Gerar top 10 de naturezas candidatas por rubrica.
- Criar score deterministico e explicavel.
- Permitir selecao humana da natureza.
- Permitir edicao de CP/IRRF/FGTS com justificativa obrigatoria quando houver alteracao.
- Manter historico auditavel das alteracoes.

Documento final:

```text
docs/03_comunicacao/ETAPA_004C_RESPOSTA.md
```

Fonte usada:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/tabela_eventos_rubricas_marcos_tab03_2026-06-01.xlsx
```

SHA256 validado:

```text
867D8E7B38D0968C94F9721D4202CBD089A3543D31594AE1817A541D71886BA4
```

Contagens importadas:

```text
events: 464
natures: 148
suggestions_v2: 4640
```

Cada evento recebeu 10 sugestoes.

Migration principal:

```text
db/migrate/20260601090000_create_rubric_adequacy_tables.rb
```

Tabelas criadas:

- `rubric_companies`
- `rubric_events`
- `esocial_natures`
- `rubric_nature_suggestions`
- `rubric_nature_assignments`
- `rubric_nature_assignment_versions`

Models criados:

- `RubricCompany`
- `RubricEvent`
- `EsocialNature`
- `RubricNatureSuggestion`
- `RubricNatureAssignment`
- `RubricNatureAssignmentVersion`

Services criados:

- `RubricRecovery::MarcosTab03Workbook`
- `RubricRecovery::TextNormalizer`
- `RubricRecovery::IncidenceComparator`
- `RubricRecovery::NatureScorer`
- `RubricRecovery::NatureSuggestionBuilder`
- `RubricRecovery::AdequacyImporter`
- `RubricRecovery::AssignmentUpdater`

Controllers criados:

- `RubricRecovery::AdequacyController`
- `RubricRecovery::AdequacyAssignmentsController`
- `RubricRecovery::RubricsNaturesController`

Views principais:

- `app/views/rubric_recovery/adequacy/index.html.erb`
- `app/views/rubric_recovery/adequacy/show.html.erb`
- `app/views/rubric_recovery/rubrics_natures/index.html.erb`

Rotas 004C:

```text
/rubric_recovery/adequacy
/rubric_recovery/adequacy/:id
/rubric_recovery/rubrics_natures
```

Score:

- Algoritmo atual: `nature-score-v2`.
- Deterministico, reproduzivel e explicavel.
- Usa tokens, termos de dominio, alinhamento de CP/IRRF/FGTS, bonus e penalidades.
- Casos ambiguos nao devem ser auto-decididos.

Exemplos esperados em teste:

- `0001` -> top `1000`.
- `0271` -> top `1350`.
- `0558` -> top `1017`.
- `0005` -> top esperado dentro de `1016` ou `1020` no teste original; atualmente top real `1016`.
- `0950` -> top `6003`.
- `1951` -> top `1202`.
- `1952` -> top `1203`.

## 5. O que foi implementado na Base Legal

Objetivo implementado:

- Criar uma aba/tela `Base Legal` para visualizar a planilha `relatorio_recuperacao_credito.xlsx` enviada por Marcos.
- Preservar cada aba da planilha como tabela navegavel no Rails.
- Exibir contagem de linhas por aba e uma tabela legivel com cabecalho fixo e rolagem horizontal/vertical.
- Oferecer modo `Tela cheia` por aba, mantendo troca de abas e rolagem ampla para leitura de tabelas densas.
- Nao calcular credito, nao exibir valor financeiro e nao misturar com consulta eSocial.

Fonte usada:

```text
docs/04_referencias/pesquisa_original/base_legal/relatorio_recuperacao_credito.xlsx
```

SHA256 validado:

```text
75064F89D788D4E23778E5AB560331E7E33205A83B68A69D5B859E6B8355C2E4
```

Abas lidas:

```text
Resumo
Rubricas
INSS - FGTS
IRPF
FGTS
```

Arquivos principais:

- `app/services/base_legal/recovery_credit_workbook.rb`
- `app/controllers/legal_basis_controller.rb`
- `app/views/legal_basis/index.html.erb`
- `test/services/base_legal/recovery_credit_workbook_test.rb`
- `test/controllers/legal_basis_controller_test.rb`

Rota:

```text
/legal_basis
```

## 6. O que foi implementado no Frontend 004 / MD 007 + MD 008

Documentos criados:

- `docs/03_comunicacao/FRONTEND_004_PLANO_IMPECCABLE_TASTE.md`
- `docs/04_referencias/FRONTEND_008_DESIGN_SYSTEM_TRIBUTALAB.md`
- `docs/03_comunicacao/FRONTEND_004_RESPOSTA_IMPECCABLE_TASTE.md`

Referencias usadas apenas como guia, sem instalar dependencias:

- `pbakaus/impeccable`
- `Leonxlnx/taste-skill`
- `langfuse/langfuse`
- `dubinc/dub`

Design read:

```text
B2B fiscal operations workbench for consultants reviewing tax rules, simulations and eSocial rubrics, with a quiet technical audit-room language, leaning toward dense product UI, Rails ERB/Tailwind components, restrained motion and high readability.
```

Dials:

- DESIGN_VARIANCE: 3/10.
- MOTION_INTENSITY: 1/10.
- VISUAL_DENSITY: 8/10.

Arquivos alterados principais:

- `app/assets/tailwind/application.css`
- `app/controllers/dashboard_controller.rb`
- `app/helpers/application_helper.rb`
- `app/views/layouts/application.html.erb`
- `app/views/dashboard/index.html.erb`
- `app/views/rubric_recovery/adequacy/index.html.erb`
- `app/views/rubric_recovery/adequacy/show.html.erb`
- `app/views/rubric_recovery/rubrics_natures/index.html.erb`
- `app/views/rubric_recovery/radar/show.html.erb`

Menu lateral novo:

```text
Painel

Laboratorio [abre/fecha]
  Casos
  Simulacoes
  Radar de Rubricas

Eventos [abre/fecha]
  Base Legal
  S-1010
    Pontuacao S-1010
    Rubricas + Natureza

Engrenagem de configuracoes [abre/fecha]
  Parametros
  Premissas
```

O item `Painel` fica sozinho. `Laboratorio` e `Eventos` sao grupos recolhiveis no menu lateral. `Configuracoes` aparece como simbolo de engrenagem e abre `Parametros`/`Premissas`. O bloco inferior antigo `Dossie local` foi removido do sidebar.

No mobile, o menu foi compactado em:

```text
Painel
Laboratorio
Eventos
Configuracoes
```

Componentes/padroes CSS adicionados ou consolidados:

- `tl-nav-section`
- `tl-nav-subgroup`
- `tl-nav-sublink`
- `tl-section-tabs`
- `tl-tab`
- `tl-score-bar`
- `tl-score-badge`
- `tl-signal-chip`
- `tl-penalty-chip`
- `tl-incidence-pill`
- `tl-row-selected`
- `tl-row-reviewed`
- `tl-row-warning`
- `tl-evidence-panel`
- `tl-decision-panel`
- `tl-history-rail`
- `tl-history-item`
- `tl-required-hint`
- `tl-cockpit-action`
- `tl-legal-table-wrap`
- `tl-legal-table`
- `tl-legal-cell`

Paleta funcional aplicada:

- Verde: selecionado, OK, revisado, score forte.
- Vermelho: divergencia, penalidade, erro, bloqueio, alteracao critica.
- Ambar: ambiguidade, revisao pendente, score medio.
- Azul/ciano: informacao, fonte, evidencia, drill-down.
- Neutros/slate: superficies e tabelas.
- Cobre: apenas acento de marca.

Mudancas por tela:

### Painel

- O hero foi reduzido para cockpit operacional.
- Foram removidos chips/blocos que poluiam a leitura inicial, como contadores soltos de operacoes/alertas, atalhos de Laboratorio/Eventos/Configuracoes e o readout `rubricas/naturezas/ambiente local`.
- Foram mantidos os elementos animados principais, mais contidos.
- A primeira tela agora fica somente com o cockpit visual principal para receber o logo/identidade que sera retrabalhado depois.

### 004C - Pontuacao S-1010

- Virou fila de revisao com tabs S-1010.
- Score aparece como numero + barra visual.
- Natureza selecionada tem destaque verde.
- Sinais positivos aparecem em verde/azul.
- Penalidades aparecem em vermelho.
- CP/IRRF/FGTS aparecem como pills de incidencia.

### 004C - Rubricas + Natureza

- Linhas revisadas/selecionadas recebem estado visual.
- Score selecionado usa barra visual.
- Overrides CP/IRRF/FGTS aparecem como marcador vermelho.
- Justificativa obrigatoria aparece como alerta vermelho.
- Historico aparece em trilha compacta.

### Radar

- Kicker ajustado para Laboratorio/Folha eSocial.
- Divergencias usam vermelho.
- Confianca e score receberam leitura visual mais clara.

## 7. Validacoes ja executadas

Comandos executados com sucesso:

```text
ruby bin/rails tailwindcss:build
```

```text
ruby bin/rails test
49 runs, 304 assertions, 0 failures, 0 errors, 0 skips
```

```text
ruby bin/rails zeitwerk:check
All is good!
```

Rotas verificadas via HTTP local:

```text
/                                200
/case_files                      200
/simulations                     200
/rubric_recovery/radar           200
/rubric_recovery/adequacy        200
/rubric_recovery/rubrics_natures 200
/legal_basis                     200
/legal_basis?sheet=IRPF          200
/legal_basis?sheet=INSS%20-%20FGTS 200
/tax_parameters                  200
/assumptions                     200
```

## 8. Como rodar localmente

Instalacao/dependencias ja estao no projeto. Para subir localmente:

```text
ruby bin/rails server
```

URL esperada:

```text
http://localhost:3000
```

Se a porta 3000 estiver ocupada, usar outra porta:

```text
ruby bin/rails server -p 3001
```

## 9. Comandos uteis para a proxima IA

Preparar test DB, se necessario:

```text
ruby bin/rails db:test:prepare
```

Rodar testes:

```text
ruby bin/rails test
```

Build Tailwind:

```text
ruby bin/rails tailwindcss:build
```

Checar autoload:

```text
ruby bin/rails zeitwerk:check
```

Reimportar/garantir dados 004C locais:

```text
ruby bin/rails runner "RubricRecovery::AdequacyImporter.ensure_loaded!"
```

Conferir contagens 004C:

```text
ruby bin/rails runner "RubricRecovery::AdequacyImporter.ensure_loaded!; puts({events: RubricEvent.count, natures: EsocialNature.count, suggestions: RubricNatureSuggestion.where(algorithm_version: RubricRecovery::NatureScorer::VERSION).count}.to_json)"
```

## 10. Atencao ao worktree

O repo pode estar com muitas alteracoes nao commitadas de etapas anteriores, incluindo arquivos de app, docs, logs e cache. Nao use `git reset --hard`. Nao reverta mudancas que nao forem claramente suas.

Antes de editar, leia o arquivo atual. Houve alteracoes em `db/schema.rb` entre etapas.

Evite `apply_patch` paralelo em arquivos sobrepostos. Isso ja causou duplicacao de classes/views antes e precisou ser corrigido.

## 11. Proximo trabalho sugerido

Se o usuario pedir continuar frontend:

- melhorar responsividade mobile das tabelas densas;
- criar row expansion/drawer leve com Stimulus para edicao em `rubrics_natures`;
- fazer revisao visual com screenshots;
- polir `simulations/new`, `simulations/show`, `case_files/show`, `tax_parameters` e `assumptions` com o mesmo design system.

Se o usuario pedir continuar S-1010 historico:

- pedir confirmacao explicita do escopo;
- nao consultar eSocial automaticamente;
- trabalhar primeiro com ZIP local ja baixado, se existir;
- preservar vigencias e retificacoes;
- nunca assumir recibo por tabela obsoleta.

Se o usuario pedir o rebuild do modulo de rubricas CTE:

- ler primeiro `docs/03_comunicacao/REBUILD_005_PLANO_SISTEMA_NOVO_RUBRICAS_CTE.md`;
- tratar `Natureza E-Social por Rubrica CTE.xlsx` como fonte primaria de rubrica CTE -> natureza eSocial pela coluna `eSoc`;
- tratar o score/top 10 da 004C como fallback, QA e comparacao, nao como decisor principal;
- tratar o ZIP `S1010 todos os anos CTE.zip` como fonte local de chain walk historico, abrindo os ZIPs mensais aninhados;
- manter `relatorio_recuperacao_credito` como biblioteca de base legal/tese, nao como catalogo completo;
- nao calcular credito financeiro sem folha e recolhimentos.

Documentos do rebuild criados:

```text
docs/03_comunicacao/REBUILD_001_FONTE_S1010_CHAIN_WALK.md
docs/03_comunicacao/REBUILD_002_FONTE_NATUREZA_ESOCIAL_RUBRICA_CTE.md
docs/03_comunicacao/REBUILD_003_FONTE_ARQUIVO_ENQUADRADO.md
docs/03_comunicacao/REBUILD_004_FONTE_RELATORIO_RECUPERACAO_CREDITO.md
docs/03_comunicacao/REBUILD_005_PLANO_SISTEMA_NOVO_RUBRICAS_CTE.md
```

## 12. Estado final conhecido

Estado conhecido apos a ultima validacao:

- Frontend 004 implementado.
- Etapa 004C implementada.
- Base Legal implementada com leitura XLSX local e rota `/legal_basis`.
- Analise de rebuild das quatro fontes de rubricas/eSocial documentada em `REBUILD_001` a `REBUILD_005`.
- Testes Rails verdes.
- Tailwind build verde.
- Zeitwerk verde.
- Rotas principais respondendo 200 no servidor local.
- Nenhuma consulta eSocial feita.
- Nenhuma dependencia frontend nova adicionada.