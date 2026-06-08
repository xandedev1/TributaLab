# REBUILD 005 - Plano para Sistema Novo de Rubricas CTE

Data: 2026-06-02
Projeto: Prev Lab

## Resposta curta

Sim, vale a pena recomecar a arquitetura de dados e a interface principal do modulo de rubricas.

Nao recomendo apagar literalmente o repo ou tudo que ja foi feito. A melhor decisao e criar uma `v2` do modulo, com tabelas, importadores e telas novas, mantendo o que existe como prototipo, historico e referencia ate a substituicao.

O motivo: as quatro fontes novas/atuais mudam o centro do produto.

Antes o sistema estava organizado em torno de:

```text
pontuacao -> sugestao de natureza -> revisao humana
```

Agora o sistema deve nascer em torno de:

```text
catalogo CTE oficial/operacional
-> natureza eSocial esperada por rubrica
-> incidencias esperadas CP/IRRF/FGTS por vigencia
-> S-1010 real declarado no tempo
-> divergencia historica
-> tese legal
-> folha/recolhimento
-> dossie e credito potencial
```

## Fontes e papel de cada uma

### 1. Natureza E-Social por Rubrica CTE

Papel: fonte primaria de mapeamento esperado.

Ela traz a coluna `eSoc`, que liga rubrica CTE a natureza eSocial. Por isso, ela substitui o score como fonte principal.

Uso:

- catalogo de rubricas CTE;
- natureza eSocial esperada;
- perfil de incidencia por CP/IRRF/FGTS;
- vigencias de mapeamento;
- fallback para rubricas com `eSoc = 0`.

### 2. S-1010 todos os anos CTE

Papel: fonte historica real declarada no eSocial.

Ela permite responder a pergunta operacional mais importante:

```text
Quando a empresa comecou a declarar essa rubrica com natureza/incidencia errada?
```

Uso:

- chain walk por rubrica;
- linha do tempo 2018-2026;
- comparacao declarado x esperado;
- identificacao do periodo de erro;
- evidencia com XML e recibo.

### 3. relatorio_recuperacao_credito

Papel: biblioteca juridica de teses e base legal.

Uso:

- fundamentacao por rubrica;
- separacao por INSS, FGTS e IRRF;
- texto para dossie;
- priorizacao de oportunidades com tese conhecida.

### 4. arquivo_enquadrado

Papel: diagnostico legado e QA.

Uso:

- conferir divergencias ja conhecidas;
- comparar resultados da v2 contra a etapa anterior;
- priorizar divergencias alta/media;
- fallback quando a fonte nova estiver zerada ou ambigua.

## O que deve ser descartado ou rebaixado

Nao apagar fisicamente agora, mas rebaixar no desenho novo:

- score como decisor principal de natureza;
- telas que nasceram como prova de conceito da 004C;
- visualizacao generica sem fluxo operacional;
- modelagem centrada em sugestoes top 10;
- qualquer promessa de credito financeiro sem folha e recolhimento.

O score deve continuar existindo, mas como:

- fallback;
- detector de conflito;
- explicacao auxiliar;
- fila de revisao humana.

## O que deve ser preservado

Preservar:

- parsers XLSX ja feitos como referencia tecnica;
- regra de nao consultar eSocial sem permissao;
- docs de fontes e hashes;
- testes de leitura;
- design shell do Prev Lab, se ainda fizer sentido visual;
- conhecimento de divergencias do `arquivo_enquadrado`;
- tela Base Legal apenas como visualizador temporario, ate virar biblioteca juridica integrada.

## Modelo de dados recomendado

### Registro de fontes

```text
source_files
id
kind
original_path
repo_path
sha256
loaded_at
notes
```

### Catalogo CTE e mapeamento esperado

```text
cte_rubrics
id
tabela
codigo_cte
descricao
tipo_rubrica
active_from
active_to
```

```text
cte_rubric_expected_mappings
id
cte_rubric_id
esocial_nature_code
source_row
inicio
fim
car
tp
cmp_inc
seq
confidence_source
```

```text
cte_rubric_expected_incidences
id
expected_mapping_id
tax_kind        -- CP, IRRF, FGTS
expected_flag   -- incide, nao_incide, informativo, deducao, desconhecido
raw_column
raw_value
```

### Historico S-1010

```text
s1010_events
id
source_file_id
nested_zip_path
xml_path
xml_sha256
event_action
nr_recibo
ide_tab_rubr
cod_rubr_raw
cod_rubr_normalized
dsc_rubr
ini_valid
fim_valid
nat_rubr
tp_rubr
cod_inc_cp
cod_inc_irrf
cod_inc_fgts
observacao
```

```text
s1010_timeline_segments
id
s1010_key
period_start
period_end
nat_rubr
cod_inc_cp
cod_inc_irrf
cod_inc_fgts
previous_segment_id
changed_fields
```

### Cruzamento e achados

```text
rubric_identity_links
id
cte_rubric_id
s1010_key
match_method     -- exact_code, suffix_code, description, manual
score
review_status
```

```text
rubric_findings
id
cte_rubric_id
s1010_segment_id
tax_kind
expected_value
declared_value
finding_type     -- divergence, missing_mapping, legal_opportunity, needs_review
severity
first_detected_period
last_detected_period
legal_thesis_id
review_status
```

### Base legal

```text
legal_theses
id
category
subcategory
legal_basis_text
risk_level
status
```

```text
legal_thesis_rubrics
id
legal_thesis_id
cte_rubric_id
esocial_nature_code
tax_kind
expected_treatment
source_sheet
source_row
```

### Valores futuros

```text
payroll_amounts
tax_payments
recovery_estimates
```

Essas tabelas so devem ser ativadas quando houver fonte de folha e recolhimento. Sem isso, o sistema deve falar em oportunidade, divergencia e periodo exposto, nao em valor recuperavel fechado.

## Chain walk: regra central

O chain walk deve montar uma linha do tempo por rubrica real do S-1010:

```text
2018-07 -> natRubr A / CP X / IRRF Y / FGTS Z
2019-01 -> natRubr B / CP X / IRRF Y / FGTS Z
2019-11 -> natRubr B / CP X2 / IRRF Y2 / FGTS Z
...
```

Depois comparar cada segmento com o esperado:

```text
esperado pela fonte CTE/eSoc
base legal aplicavel
declarado no S-1010
```

Resultado esperado por segmento:

```text
OK
divergente CP
divergente IRRF
divergente FGTS
natureza divergente
sem mapeamento esperado
sem link confiavel entre CTE e S-1010
revisao humana obrigatoria
```

## Telas novas recomendadas

### 1. Importacao e Fontes

- lista fontes carregadas;
- hashes;
- contagens;
- status do parser;
- diferenca entre versoes.

### 2. Catalogo de Rubricas CTE

- 470 rubricas da fonte nova;
- eSoc esperado;
- linhas com eSoc 0;
- rubricas com multiplas naturezas;
- incidencias CP/IRRF/FGTS esperadas.

### 3. Chain Walk S-1010

- timeline por rubrica;
- filtros por ano, rubrica, natureza, tributo;
- destaque de mudancas;
- link para XML/recibo.

### 4. Divergencias Declarado x Esperado

- compara CTE/eSoc esperado contra S-1010 real;
- separa CP, IRRF e FGTS;
- mostra periodo afetado;
- status de revisao.

### 5. Base Legal e Tese

- tese por rubrica;
- artigos e jurisprudencia;
- tributo afetado;
- risco/status.

### 6. Dossie de Recuperacao

- evidencia S-1010;
- base legal;
- periodo exposto;
- pendencias de folha/recolhimento;
- sem valor financeiro ate importar as fontes de pagamento.

## Regra de cinco anos

O historico S-1010 vai de 2018 a 2026, mas a recuperacao tributaria normalmente exigira recorte prescricional. Em 2026-06, a janela operacional inicial de cinco anos seria aproximadamente 2021-06 a 2026-06, sujeita a validacao juridica.

Mesmo assim, manter 2018-2020 e util porque mostra a origem da parametrizacao e prova continuidade do erro.

## Ordem recomendada de implementacao

1. Criar novo namespace/modulo `RubricAudit` ou `RecoveryAudit`.
2. Criar registro de fontes e importadores idempotentes.
3. Importar `Natureza E-Social por Rubrica CTE.xlsx` como catalogo esperado.
4. Importar ZIP S-1010 recursivo e gerar timeline.
5. Criar vinculador CTE <-> S-1010, com revisao humana para casos prefixados.
6. Importar `relatorio_recuperacao_credito` como biblioteca legal.
7. Importar `arquivo_enquadrado` como diagnostico legado/QA.
8. Gerar achados por rubrica/tributo/periodo.
9. Criar telas de catalogo, chain walk e divergencias.
10. Somente depois importar folha/recolhimento e calcular estimativas financeiras.

## Decisao final

Vale a pena comecar do zero no modulo de rubricas, sim.

Mas a forma correta e:

```text
nao apagar o que existe agora;
construir uma v2 limpa;
migrar apenas o que foi validado;
desligar as telas antigas quando a v2 cobrir o fluxo.
```

O sistema novo deve ser menos uma tela de score e mais uma plataforma de auditoria historica:

```text
rubrica CTE atual
-> natureza/incidencia esperada
-> S-1010 real no tempo
-> divergencia por periodo
-> base legal
-> evidencia
-> recuperacao potencial com folha/recolhimento
```
