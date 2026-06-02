# MD 006 - Adequacao S-1010 via Pontuacao de Naturezas

Data: 2026-06-01
Projeto: TributaLab
Origem: pesquisa/arquiteto de dados fiscais
Destino: agente de implementacao Rails/frontend
Objetivo: orientar a implementacao da principal tela de adequacao de rubricas: listar todos os eventos da CTE, sugerir as 10 naturezas mais provaveis da Tabela 03 para cada evento, permitir selecao humana e depois listar rubricas ja enquadradas com incidencias editaveis.

## Mudanca de prioridade

Pausar a etapa de parser historico S-1010 por vigencia.

Antes de cruzar o ZIP S-1010 historico, o produto precisa resolver uma etapa mais importante para o usuario: criar o sistema de adequacao por pontuacao entre as rubricas da empresa e as naturezas da Tabela 03.

Esta etapa deve usar a nova planilha enviada pelo Marco:

```text
Tabela de Eventos - Rubricas Marcos + Tab03
```

Arquivo preservado no pacote de pesquisa:

```text
00_CONTEXTO_PROJETO/tabela_eventos_rubricas_marcos_tab03_2026-06-01.xlsx
```

SHA256:

```text
867D8E7B38D0968C94F9721D4202CBD089A3543D31594AE1817A541D71886BA4
```

Fonte original local:

```text
C:\Users\xandao\Downloads\Tabela de Eventos - Rubricas (1).xlsx
```

## Estrutura real da planilha

A planilha tem duas abas: `Plan1` e `tab03`.

### Aba Plan1

Esta aba contem a lista de eventos/rubricas da empresa CTE.

Dimensoes observadas:

- 614 linhas totais.
- 21 colunas.
- Cabecalho util na linha 4.
- 464 eventos com codigo de 4 digitos.
- 464 codigos unicos.
- Sem codigo duplicado na lista de eventos.

Cabecalho util da linha 4:

```text
Tab. | Codigo | Descricao | vazio | Car. | Reg. | Tp. | Nt. | Sl. | Rub. | BR | FN | FD | FNI | FDI | InM | InD | IrM | IrF | IrD | Ir
```

Campos importantes:

- `Tab.`: tabela operacional CTE, preenchida no inicio e depois herdada visualmente.
- `Codigo`: codigo interno da rubrica/evento CTE.
- `Descricao`: descricao operacional da rubrica.
- `Tp.`: tipo operacional da rubrica, ainda precisa legenda confirmada.
- `Nt.`: indicador 0/1 da CTE, nao equivale diretamente a `natRubr` eSocial.
- `FN`: indicador operacional usado como aproximacao de FGTS na leitura anterior.
- `InM`: indicador operacional usado como aproximacao de CP/INSS na leitura anterior.
- `IrM`: indicador operacional usado como aproximacao de IRRF na leitura anterior.

Distribuicoes observadas:

- `Tp.`: 276 com `1`, 119 com `3`, 63 com `4`, 5 com `2`, 1 com `6`.
- `Nt.`: 459 com `0`, 5 com `1`.
- `InM`: 330 `N`, 129 `+`, 5 `-`.
- `IrM`: 330 `N`, 116 `+`, 18 `-`.
- `FN`: 314 `N`, 145 `+`, 5 `-`.

Exemplos reais:

- `0001` - `Salario`.
- `0005` - `Horas Ferias Diurnas`.
- `0017` - `Auxilio Maternidade INSS`.
- `0271` - `Bolsa Estagio`.
- `0558` - `1/3 Ferias`.
- `0750` - `13o Salario Adiantado`.
- `0950` - `Aviso Previo Indenizado`.
- `1951` - `Insalubridade`.
- `1952` - `Periculosidade`.
- `2456` - `Desconto Assist. Medica`.
- `3611` - `eConsignado`.

### Aba tab03

Esta aba contem as naturezas da Tabela 03/eSocial enriquecidas com descricao e codigos de incidencia.

Dimensoes observadas:

- 149 linhas totais.
- 15 colunas.
- 148 linhas de natureza.
- 146 codigos unicos.
- Duplicidades conhecidas para codigos com vigencia diferente: `1016` e `1017`.

Cabecalho:

```text
CODIGO | NOME | NOME (sem acentuacao e caracter especial) | DTINICIO | DTFIM | DESCRICAO | INCIDENCIA EXCLUSIVA EMPREGADO | CODIGO | codIncCP | codIncIRRF | codIncFGTS | sugCP | sugIRRF | sugFGTS | motivo/fonte
```

Campos importantes:

- `CODIGO`: codigo da natureza eSocial.
- `NOME`: nome oficial/legivel da natureza.
- `NOME (sem acentuacao e caracter especial)`: nome normalizado.
- `DTINICIO` e `DTFIM`: vigencia da natureza.
- `DESCRICAO`: descricao oficial/analitica da natureza.
- `codIncCP`: incidencia previdenciaria esperada.
- `codIncIRRF`: incidencia IRRF esperada.
- `codIncFGTS`: incidencia FGTS esperada.
- `motivo/fonte`: observacao juridica/tecnica em algumas linhas.

Distribuicoes observadas:

- `codIncCP`: 88 com `0`, 50 com `11`, 3 com `12`, e demais codigos minoritarios.
- `codIncIRRF`: 53 com `9`, 49 com `11`, 12 com `13`, 11 com `74`, 5 com `79`, 5 com `12`, e outros.
- `codIncFGTS`: 89 com `0`, 52 com `11`, 5 com `12`, e outros.
- `motivo/fonte`: 28 linhas preenchidas.

Observacao critica: a pontuacao deve trabalhar com a linha da `tab03`, nao apenas com o codigo, porque existem codigos repetidos com vigencias e descricoes diferentes.

## Nova secao do sistema

Nome da secao:

```text
Adequacao S-1010 via Pontuacao
```

Esta secao e a principal aplicacao de trabalho da consultoria.

Ela deve ter duas telas ou dois modos principais:

1. `Pontuacao de Naturezas`.
2. `Rubricas + Natureza`.

## Tela 1 - Pontuacao de Naturezas

Objetivo: listar todos os 464 eventos da `Plan1` e, para cada evento, sugerir as 10 naturezas mais provaveis da `tab03` com pontuacao de 0 a 10.

Fluxo esperado:

1. Usuario abre a lista de eventos da CTE.
2. Cada linha mostra codigo, descricao, tipo, indicadores CTE e status de enquadramento.
3. Ao abrir uma rubrica, o sistema mostra as 10 naturezas candidatas da `tab03`.
4. Cada candidata tem pontuacao 0-10, codigos CP/IRRF/FGTS, vigencia e explicacao do score.
5. Usuario escolhe uma natureza ou marca como pendente/ambigua.
6. Ao escolher, o sistema cria uma atribuicao de natureza para a rubrica.

Campos na lista de eventos:

- codigo CTE.
- descricao CTE.
- `Tp.`.
- `Nt.`.
- indicadores `InM`, `IrM`, `FN`.
- status: `sem natureza`, `sugestao alta`, `ambigua`, `selecionada`, `revisar`.
- melhor candidata.
- maior score.
- quantidade de candidatas relevantes.
- acao `avaliar`.

Campos no painel de top 10:

- rank.
- pontuacao 0-10.
- codigo natureza.
- nome natureza.
- descricao resumida.
- vigencia.
- `codIncCP`.
- `codIncIRRF`.
- `codIncFGTS`.
- sinais positivos do match.
- penalidades do match.
- alerta de ambiguidade, se houver.
- acao `selecionar natureza`.

## Tela 2 - Rubricas + Natureza

Objetivo: listar as rubricas que ja receberam natureza e permitir revisar/alterar os codigos de incidencia dos tres tributos.

Cada linha deve mostrar:

- codigo CTE.
- descricao CTE.
- natureza selecionada.
- nome da natureza.
- score usado na escolha.
- origem da escolha: `pontuacao`, `manual`, `importado`, `revisado`.
- `codIncCP` selecionado.
- `codIncIRRF` selecionado.
- `codIncFGTS` selecionado.
- indicadores originais CTE (`InM`, `IrM`, `FN`).
- divergencias entre CTE e incidencia selecionada.
- status de revisao.
- acao `salvar linha`.

Edicao de incidencias:

- o usuario pode alterar `codIncCP`, `codIncIRRF` e `codIncFGTS` na propria linha.
- alteracao deve exigir justificativa curta.
- salvar deve registrar data/hora, valor anterior, valor novo e motivo.
- simulacoes antigas e historico nao devem ser sobrescritos silenciosamente.

Nao chamar isso de credito. Esta tela e de adequacao cadastral/juridica de rubrica.

## Algoritmo de pontuacao

Requisito central: nao pode ser aleatorio e nao pode depender de chute opaco.

O score deve ser deterministico, reproduzivel e explicavel. Se for usar IA/embedding no futuro, ela deve ser apenas uma camada auxiliar, nunca a unica prova.

### Normalizacao

Normalizar todos os textos antes da comparacao:

- lowercase.
- remover acentos.
- remover pontuacao irrelevante.
- normalizar abreviacoes.
- remover stopwords simples.
- preservar termos juridicamente relevantes, como `13`, `1/3`, `dsr`, `fgts`, `inss`, `irrf`, `ferias`, `aviso`, `indenizado`, `maternidade`, `estagio`, `rescisao`.

### Dicionario de sinonimos e abreviacoes

Criar dicionario versionado no codigo para o dominio de folha.

Exemplos obrigatorios:

- `salario`, `salarial`, `vencimento`, `remuneracao`, `soldo`.
- `h.extra`, `h.extras`, `hora extra`, `horas extras`, `extraordinarias`.
- `dsr`, `descanso semanal remunerado`, `repouso remunerado`, `feriado`.
- `ferias`, `feria`.
- `1/3`, `terco`, `terco constitucional`.
- `13`, `13o`, `decimo terceiro`, `gratificacao natalina`.
- `aux`, `auxilio`.
- `mater`, `maternidade`, `salario maternidade`.
- `doenca`, `auxilio doenca`.
- `acidente`, `acidente trabalho`.
- `aviso previo`, `api`, `aviso indenizado`, `aviso trabalhado`.
- `rescisao`, `rescisorio`, `indenizado`, `indenizacao`.
- `adto`, `adiantado`, `adiantamento`.
- `not`, `noturno`, `noturna`.
- `insalubridade`, `periculosidade`.
- `bolsa`, `estagio`, `estagiario`.
- `vr`, `va`, `vale refeicao`, `vale alimentacao`, `alimentacao`.
- `vt`, `vale transporte`, `transporte`.
- `assistencia medica`, `medica`, `odontologica`, `plano de saude`.
- `econsignado`, `consignado`, `emprestimo consignado`.

### Componentes do score 0-10

Sugestao de pesos iniciais:

1. Match semantico de descricao e nome: ate 3 pontos.
2. Match com descricao longa da Tabela 03: ate 2 pontos.
3. Match de categoria de dominio: ate 2 pontos.
4. Compatibilidade de incidencias (`InM`, `IrM`, `FN` versus `codIncCP`, `codIncIRRF`, `codIncFGTS`): ate 1,5 ponto.
5. Compatibilidade de tipo operacional (`Tp.`, `Nt.`, desconto, vencimento, informativo): ate 1 ponto.
6. Bonus por frase forte/exata: ate 0,5 ponto.

Aplicar penalidades fortes antes de ordenar:

- evento fala `13` ou `decimo` e natureza nao fala 13/decimo: penalizar.
- evento nao fala 13/decimo e natureza fala 13/decimo: penalizar.
- evento fala `ferias` e natureza nao e de ferias/terco/abono/dobro: penalizar.
- evento fala `1/3` e natureza nao fala terco constitucional: penalizar.
- evento fala `maternidade` e natureza nao e salario-maternidade/relacionada: penalizar.
- evento fala `estagio/bolsa` e natureza nao e bolsa/estagiario: penalizar.
- evento fala `aviso indenizado` e natureza e aviso trabalhado: penalizar.
- evento fala `desconto` e natureza e verba de vencimento sem desconto: penalizar.
- evento fala `reembolso`, `custo empresa`, `assistencia medica`, `consignado`, `plano` e natureza salarial comum: penalizar.

### Faixas de score

- 8,5 a 10: sugestao forte, ainda revisavel.
- 7,0 a 8,49: boa sugestao, revisar.
- 5,0 a 6,99: sugestao media, exige humano.
- abaixo de 5: baixa confianca; pode aparecer no top 10, mas nao deve ser pre-selecionada.

### Regras de desempate

Em caso de score proximo:

1. Preferir natureza com categoria especifica em vez de natureza generica.
2. Preferir natureza vigente, se a competencia/contexto for conhecido; sem competencia, mostrar duplicatas com vigencia.
3. Preferir codigo com incidencia mais compativel com os indicadores CTE.
4. Se houver empate material, marcar como `ambigua`, nao escolher automaticamente.

## Exemplos de comportamento esperado

Estes exemplos devem orientar testes e validacao manual:

- `0001 Salario`: deve ranquear `1000 Salario, vencimento, soldo` no topo ou muito proximo do topo; naturezas de `13 salario`, `salario-maternidade` ou `salario-familia` devem receber penalidade.
- `0271 Bolsa Estagio`: deve ranquear `1350 Bolsa de estudo - Estagiario` no topo.
- `0558 1/3 Ferias`: deve ranquear `1017 Terco constitucional de ferias` acima de `1015 Adiantamento de ferias`.
- `0005 Horas Ferias Diurnas`: deve ranquear naturezas de ferias (`1016`/`1020`) acima de horas extras comuns.
- `0017 Auxilio Maternidade INSS`: deve ranquear naturezas de salario-maternidade, mas provavelmente marcar ambiguidade entre natureza paga pela empresa/previdencia ou 13o, conforme descricao.
- `0950 Aviso Previo Indenizado`: deve ranquear natureza de aviso previo indenizado, nao aviso previo trabalhado.
- `1951 Insalubridade`: deve ranquear `1202 Adicional de insalubridade`.
- `1952 Periculosidade`: deve ranquear `1203 Adicional de periculosidade`.

## Dados e persistencia sugeridos

Esta etapa provavelmente precisa de persistencia, porque o usuario vai escolher natureza e alterar incidencia.

Modelos candidatos:

### `RubricCompany`

Representa a empresa analisada.

Campos:

- `name`.
- `reference_code`.
- `cnpj_root`, opcional.
- `notes`.

Seed inicial:

```text
CTE CENTRO DE TECNOLOGIA EDI.E HOL. LTDA
```

### `RubricEvent`

Representa uma linha de evento da `Plan1`.

Campos:

- `rubric_company_id`.
- `source_file_hash`.
- `source_sheet`.
- `source_row`.
- `table_code`.
- `event_code`.
- `description`.
- `car`.
- `reg`.
- `tp`.
- `nt`.
- `sl`.
- `rub`.
- indicadores `br`, `fn`, `fd`, `fni`, `fdi`, `inm`, `ind`, `irm`, `irf`, `ird`, `ir`.
- `normalized_description`.

### `EsocialNature`

Representa uma linha da `tab03`.

Campos:

- `source_file_hash`.
- `source_sheet`.
- `source_row`.
- `nature_code`.
- `name`.
- `normalized_name`.
- `valid_from`.
- `valid_to`.
- `description`.
- `exclusive_employee_incidence`.
- `cod_inc_cp`.
- `cod_inc_irrf`.
- `cod_inc_fgts`.
- `suggested_cp`.
- `suggested_irrf`.
- `suggested_fgts`.
- `reason_source`.

### `RubricNatureSuggestion`

Representa sugestao calculada para uma rubrica.

Campos:

- `rubric_event_id`.
- `esocial_nature_id`.
- `rank`.
- `score`.
- `confidence_label`.
- `positive_signals` JSON.
- `penalties` JSON.
- `incidence_alignment` JSON.
- `algorithm_version`.

### `RubricNatureAssignment`

Representa a natureza escolhida para uma rubrica.

Campos:

- `rubric_event_id`.
- `esocial_nature_id`.
- `selected_score`.
- `selection_origin`: `suggested`, `manual`, `imported`, `reviewed`.
- `selected_cod_inc_cp`.
- `selected_cod_inc_irrf`.
- `selected_cod_inc_fgts`.
- `override_cp` boolean.
- `override_irrf` boolean.
- `override_fgts` boolean.
- `justification`.
- `status`: `pending`, `selected`, `reviewed`, `ambiguous`, `rejected`.
- timestamps.

### `RubricNatureAssignmentVersion` ou auditoria simples

Registrar historico de alteracoes.

Campos:

- `rubric_nature_assignment_id`.
- valores anteriores.
- valores novos.
- motivo.
- data/hora.
- usuario/sistema.

## Services sugeridos

- `RubricRecovery::MarcosTab03Workbook`: leitor da nova planilha.
- `RubricRecovery::TextNormalizer`: normalizacao e dicionario de sinonimos.
- `RubricRecovery::NatureScorer`: calcula score 0-10.
- `RubricRecovery::NatureSuggestionBuilder`: gera top 10 por rubrica.
- `RubricRecovery::AssignmentUpdater`: salva natureza e alteracoes de incidencia.

## Rotas e telas sugeridas

Rotas:

```text
GET /rubric_recovery/adequacy
GET /rubric_recovery/adequacy/:rubric_event_id
POST /rubric_recovery/adequacy/:rubric_event_id/assignments
GET /rubric_recovery/rubrics_natures
PATCH /rubric_recovery/rubrics_natures/:assignment_id
```

Nomes de controllers:

- `RubricRecovery::AdequacyController`.
- `RubricRecovery::RubricsNaturesController`.

## Fora de escopo

Nao implementar nesta etapa:

- consulta ao eSocial.
- download de eventos.
- parser do ZIP S-1010 historico.
- folha financeira.
- DCTFWeb/DARF/GPS.
- FGTS Digital.
- calculo de credito em reais.
- protocolo PER/DCOMP.
- decisao juridica automatica.
- selecao automatica obrigatoria sem revisao humana.

## Testes minimos

Criar testes para:

- leitura da planilha nova.
- contagem de 464 eventos em `Plan1`.
- contagem de 148 linhas em `tab03`.
- preservacao de duplicatas `1016` e `1017`.
- normalizacao de acentos e abreviacoes.
- pontuacao deterministica.
- top 10 gerado para todas as 464 rubricas.
- exemplos obrigatorios: `Salario`, `Bolsa Estagio`, `1/3 Ferias`, `Insalubridade`, `Periculosidade`, `Aviso Previo Indenizado`.
- criacao de atribuicao de natureza.
- edicao de `codIncCP`, `codIncIRRF`, `codIncFGTS` com justificativa.
- historico/auditoria de alteracao.
- ausencia de termos financeiros proibidos.

## Criterios de aceite

A etapa so esta pronta quando:

1. A planilha nova estiver registrada em `INDICE_FONTES.md` com hash e papel.
2. O sistema listar todos os 464 eventos da `Plan1`.
3. Cada evento tiver top 10 de naturezas candidatas da `tab03` com score 0-10.
4. O score for deterministico e exibido com explicacao.
5. Casos ambiguos forem marcados como ambiguos, nao escolhidos automaticamente.
6. Usuario puder selecionar natureza para uma rubrica.
7. A tela `Rubricas + Natureza` listar rubricas ja selecionadas.
8. Usuario puder alterar `codIncCP`, `codIncIRRF`, `codIncFGTS` com justificativa.
9. Alteracoes ficarem auditaveis.
10. Testes passarem.
11. Documento de resposta final registrar arquivos, comandos, limites e proximos passos.

## Resposta final esperada do agente

Ao terminar, criar:

```text
docs/03_comunicacao/ETAPA_004C_RESPOSTA.md
```

Incluir:

- resumo do que foi implementado.
- como a planilha foi lida.
- quantos eventos e naturezas foram importados.
- explicacao do algoritmo de pontuacao.
- exemplos reais de top 10.
- telas criadas.
- models/migrations, se houver.
- como alterar incidencias.
- testes executados.
- confirmacao de que nao houve consulta ao eSocial.
- confirmacao de que nao ha credito financeiro calculado.

## Mensagem curta para enviar ao agente

```text
Mudanca de prioridade: pause a etapa de parser historico S-1010. Antes disso, vamos implementar a principal ferramenta de trabalho: Adequacao S-1010 via Pontuacao.

Use a nova planilha preservada em docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/tabela_eventos_rubricas_marcos_tab03_2026-06-01.xlsx.

Ela tem duas abas: Plan1 com 464 eventos CTE e tab03 com 148 linhas de natureza eSocial. A tela deve listar todos os eventos e, para cada um, mostrar as 10 naturezas mais provaveis da tab03 com score 0-10, explicacao do score, codIncCP, codIncIRRF e codIncFGTS.

Depois, criar a tela Rubricas + Natureza para ver as rubricas ja enquadradas e permitir alterar CP/IRRF/FGTS com justificativa e historico.

O algoritmo nao pode ser aleatorio nem opaco. Deve ser deterministico, com normalizacao, sinonimos de folha, penalidades e explicacao. Nao selecionar automaticamente casos ambiguos.

Nao consultar eSocial, nao parsear ZIP S-1010 historico, nao calcular credito em reais e nao avancar para folha/recolhimentos.

Antes de codar, responda com o plano de modelos, services, telas e algoritmo de pontuacao.
```