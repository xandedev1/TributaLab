# ETAPA 004D - Nucleo Rubricas CTE v2

Data: 2026-06-02
Projeto: Prev Lab

## Resumo

Foi implementada a primeira entrega minima da v2 do modulo de rubricas CTE.

A v2 foi criada isolada em `RubricasCte`, sem apagar tabelas antigas, sem alterar o score antigo, sem alterar calculadoras, sem consultar eSocial e sem calcular credito financeiro.

O novo fluxo implementado nesta etapa e:

```text
planilha Natureza E-Social por Rubrica CTE
-> catalogo CTE por codigo de rubrica
-> mapeamento esperado pela coluna eSoc
-> incidencias esperadas CP/IRRF/FGTS capturadas da planilha
-> ZIP S-1010 local parseado recursivamente
-> timeline simples S-1010
-> matching inicial CTE x S-1010
-> findings simples de natureza, CP, IRRF e FGTS
-> tela operacional Rubricas CTE v2
-> tela Chain Walk S-1010 para navegar pelo historico de alteracoes
```

## Fontes usadas

Somente fontes locais:

```text
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/natureza_esocial_por_rubrica_cte.xlsx
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/s1010_todos_os_anos_cte_2026_06_02.zip
```

Nenhuma consulta ao eSocial foi feita.

## Migrations e models criados

Migrations:

```text
db/migrate/20260602090000_create_rubricas_cte_v2_tables.rb
db/migrate/20260602091000_adjust_rubricas_cte_catalog_unique_code.rb
```

Models:

```text
app/models/rubricas_cte.rb
app/models/rubricas_cte/source_file.rb
app/models/rubricas_cte/import_run.rb
app/models/rubricas_cte/catalog_rubric.rb
app/models/rubricas_cte/expected_mapping.rb
app/models/rubricas_cte/expected_incidence.rb
app/models/rubricas_cte/s1010_event.rb
app/models/rubricas_cte/s1010_timeline_segment.rb
app/models/rubricas_cte/rubric_identity_link.rb
app/models/rubricas_cte/finding.rb
```

## Servicos criados

```text
app/services/rubricas_cte/source_file_registry.rb
app/services/rubricas_cte/natureza_esocial_workbook.rb
app/services/rubricas_cte/incidence_classifier.rb
app/services/rubricas_cte/natureza_esocial_importer.rb
app/services/rubricas_cte/s1010_zip_importer.rb
app/services/rubricas_cte/timeline_builder.rb
app/services/rubricas_cte/identity_matcher.rb
app/services/rubricas_cte/audit_engine.rb
app/services/rubricas_cte/pipeline.rb
app/services/rubricas_cte/dashboard_snapshot.rb
app/services/rubricas_cte/chain_walk_snapshot.rb
```

## Tela criada

Rota:

```text
/rubricas_cte
/rubricas_cte/dashboard
/rubricas_cte/chain_walk
```

`/rubricas_cte` passou a ser a entrada oficial do produto. A rota antiga `/rubricas_cte/dashboard` foi mantida, mas redireciona para `/rubricas_cte`, para evitar duas telas competindo entre si.

Controller e view:

```text
app/controllers/rubricas_cte/dashboard_controller.rb
app/views/rubricas_cte/dashboard/index.html.erb
app/controllers/rubricas_cte/chain_walk_controller.rb
app/views/rubricas_cte/chain_walk/index.html.erb
```

Menu minimo adicionado em:

```text
app/helpers/application_helper.rb
config/routes.rb
```

A tela mostra:

- total de rubricas CTE importadas;
- rubricas com `eSoc != 0`;
- rubricas com `eSoc = 0` ou sem natureza direta;
- rubricas vinculadas ao S-1010;
- rubricas sem vinculo unico;
- divergencias de natureza;
- divergencias CP;
- divergencias IRRF;
- divergencias FGTS.

A tela `Chain Walk S-1010` mostra:

- lista navegavel de rubricas CTE;
- selecao por rubrica;
- chave S-1010 vinculada por `ideTabRubr + codRubr`;
- sequencia historica compacta de marcos por vigencia;
- disputa do marco selecionado em tabela `CTE esperado x S-1010 declarado`;
- pontuacao/prioridade somente para rubricas divergentes;
- filtro padrao em rubricas divergentes;
- aba de legenda com significado de `sem vinculo`, `divergente`, `mudou no historico`, `00` e `11`;
- traducao dos codigos de incidencia, por exemplo `11 - incide/base mensal`;
- diferenca clara entre mudanca historica no S-1010 e divergencia contra a planilha CTE;
- XML local, ZIP mensal aninhado e recibo em area recolhivel.

Tambem foi feito um corte de navegacao: Laboratorio, Radar antigo, Pontuacao S-1010 antiga e Rubricas + Natureza antiga nao aparecem mais como caminhos principais do produto. As rotas antigas continuam existindo para consulta direta, mas nao disputam a experiencia oficial.

Auditoria de origem dos dados:

- nao ha dados mockados na Chain Walk operacional;
- `codIncCP`, `codIncIRRF`, `codIncFGTS` sao lidos diretamente dos XMLs S-1010 locais;
- exemplo validado: rubrica CTE `0003 - Horas Faltas- B.Horas`;
- CTE esperado para `0003`: natureza `9209` e CP/IRRF/FGTS como `nao_incide`;
- S-1010 local para `ENORMAL_0003`: natureza `1000` e CP/IRRF/FGTS como `11/11/11`;
- por isso a tela marca divergencia: nao e valor inventado, e conflito entre fonte CTE e declaracao S-1010 local.

## Regras de incidencia na primeira entrega

A etapa 004D nao deixou CP/IRRF/FGTS para depois.

Da planilha CTE foram persistidos:

```text
FN, FD, FNI, FDI
InM, InD, InA
IRR, IrM, IrF, IrD, Ir, IrA
PIS, PID, IPM, IPD, IPF
RP, TR, Rem
```

Tambem foi criada a tabela `rubricas_cte_expected_incidences`, com um registro por indicador operacional de CP, IRRF e FGTS.

Do S-1010 foram persistidos:

```text
codIncCP
codIncIRRF
codIncFGTS
natRubr
iniValid
fimValid
nrRecibo
xml_sha256
nested_zip_path
xml_path
```

No finding foram persistidos:

```text
nature_divergent
cp_divergent
irrf_divergent
fgts_divergent
divergence_kind
divergence_kinds
```

## Contagens validadas

Leitura limpa da planilha CTE:

```text
linhas operacionais importadas pelo workbook: 1610
codigos CTE unicos importados no catalogo: 469
linhas com eSoc diferente de 0: 389
linhas com eSoc = 0: 1120
codigos CTE unicos com eSoc diferente de 0: 219
```

S-1010 local:

```text
eventos S-1010 importados: 2031
segmentos simples de timeline: 2031
```

Observacao: o catalogo foi fechado por codigo CTE numerico de quatro digitos. Cabecalhos e rodapes repetidos da planilha foram filtrados para nao inflar o catalogo.

## Testes criados

```text
test/services/rubricas_cte/natureza_esocial_workbook_test.rb
test/services/rubricas_cte/pipeline_test.rb
test/controllers/rubricas_cte/dashboard_controller_test.rb
test/controllers/rubricas_cte/chain_walk_controller_test.rb
```

## Validacao executada

Comandos usados:

```text
$env:DISABLE_BOOTSNAP='1'; $env:RAILS_ENV='test'; ruby bin/rails db:migrate
$env:DISABLE_BOOTSNAP='1'; $env:RAILS_ENV='test'; ruby bin/rails test test/services/rubricas_cte test/controllers/rubricas_cte/dashboard_controller_test.rb
$env:DISABLE_BOOTSNAP='1'; $env:RAILS_ENV='test'; ruby bin/rails test test/controllers/rubricas_cte/chain_walk_controller_test.rb
$env:DISABLE_BOOTSNAP='1'; $env:RAILS_ENV='test'; $env:PARALLEL_WORKERS='1'; ruby bin/rails db:test:prepare; ruby bin/rails test
```

Resultado dos testes focados:

```text
3 runs, 59 assertions, 0 failures, 0 errors, 0 skips
1 run, 27 assertions, 0 failures, 0 errors, 0 skips
2 runs, 52 assertions, 0 failures, 0 errors, 0 skips
```

Resultado da suite completa em serial:

```text
53 runs, 372 assertions, 0 failures, 0 errors, 0 skips
```

Validacao HTTP da nova tela Chain Walk:

```text
GET /rubricas_cte/chain_walk
STATUS=200
HAS_CHAIN=True
HAS_TIMELINE=True
HAS_S1010=True

GET /rubricas_cte/chain_walk?q=0003
STATUS=200
HAS_0003=True
HAS_TRANSLATED_11=True
HAS_CONFLICT=True
HAS_DISPUTA=True

GET /rubricas_cte
MAIN_STATUS=200
HAS_CHAIN=True
HAS_LEGENDA=True
HAS_PONTUACAO=True
HAS_TIMELINE_CLASS=True

GET /rubricas_cte/dashboard
LEGACY_STATUS=302
LEGACY_LOCATION=http://127.0.0.1:3000/rubricas_cte

GET /rubricas_cte?q=0003
STATUS=200
HAS_0003=True
HAS_TRANSLATED_11=True
HAS_CONFLICT=True
HAS_OLD_LAB=False
HAS_OLD_PONTUACAO=False
```

Diagnostics dos arquivos criticos: sem erros.

## Observacao sobre ambiente Windows

O Windows bloqueou extensoes nativas `.so` de gems no ambiente local:

```text
bootsnap/bootsnap.so
bindex/internal/cruby.so
```

Por isso foi adicionado suporte a `DISABLE_BOOTSNAP=1` em `config/boot.rb`, e a validacao foi executada em `RAILS_ENV=test`. O bloqueio e de politica local do Windows, nao da implementacao 004D.

A suite completa em paralelo apresentou deadlocks de fixtures/constraints no PostgreSQL local. Em serial (`PARALLEL_WORKERS=1`), a suite completa passou verde.

## Fora de escopo mantido

Nao foi feito:

- consulta ao eSocial;
- Download Cirurgico;
- calculo de credito financeiro;
- alteracao no score/top 10 antigo;
- alteracao em calculadoras;
- remocao de tabelas antigas;
- substituicao da Base Legal detalhada.

## Proxima rodada sugerida

Na 004E, o proximo passo natural e:

- detalhar tela de rubrica individual;
- melhorar matching ambiguo;
- integrar Base Legal como tese por finding;
- adicionar revisao manual com justificativa;
- melhorar regra de equivalencia CP/IRRF/FGTS por codigo eSocial, sem transformar isso em calculo financeiro.