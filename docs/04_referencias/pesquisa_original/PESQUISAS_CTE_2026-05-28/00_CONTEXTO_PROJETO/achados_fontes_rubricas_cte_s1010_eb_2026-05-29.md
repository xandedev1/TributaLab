# Achados iniciais - Rubricas CTE, S-1010 e Tabela EB

Data: 2026-05-29

## Objetivo

Registrar os primeiros achados sobre os tres pontos solicitados:

1. Tabela enviada pela CTE: `Tabela de Eventos - Rubricas.xlsx`.
2. Arquivo local `S1010 todos os anos CTE.zip`, com eventos S-1010 baixados/localizados em Downloads.
3. Arquivo local `Tabela EB.xlsx`.

Esta leitura nao fez consulta externa ao eSocial. Foram usados apenas os arquivos locais preservados no pacote de pesquisa.

## Fontes preservadas

### 1. Tabela de Eventos - Rubricas CTE

Arquivo no pacote:

- `tabela_eventos_rubricas_cte_2026-05-29.xlsx`

Hash SHA256:

- `C11C46E1129D85D22BCB862ED27B53A5E1623C8D461A156EC8B2A10128659DA8`

Leitura detalhada ja registrada em:

- `leitura_tabela_eventos_rubricas_cte_2026-05-29.md`

### 2. S1010 todos os anos CTE

Arquivo original:

- `C:\Users\xandao\Downloads\S1010 todos os anos CTE.zip`

Arquivo no pacote:

- `s1010_todos_os_anos_cte_2026-05-29.zip`

Hash SHA256:

- `2780DCF583DA164216414B0B21AC83E3B8B16CF6D415781DADCECCDAE12DF467`

### 3. Tabela EB

Arquivo original:

- `C:\Users\xandao\Downloads\Tabela EB.xlsx`

Arquivo no pacote:

- `tabela_eb_2026-05-29.xlsx`

Hash SHA256:

- `F1F581571B47F05DA66A91772F2D5712927C0B2CA93B34525644D445658197AB`

## Achado principal

As tres fontes nao sao a mesma tabela em formatos diferentes. Elas sao camadas diferentes do problema:

| Fonte | Papel real | O que responde bem | Limite principal |
| --- | --- | --- | --- |
| Tabela CTE | Catalogo operacional interno de eventos/rubricas da folha | Como os eventos da CTE entram em bases de remuneracao, FGTS, INSS e IRRF por tipo de base | Nao e S-1010 puro; usa codigos/eventos internos e linhas complementares |
| S-1010 | Historico oficial declarado no eSocial | O que foi enviado/alterado/excluido no eSocial, com validade, natureza, incidencias e recibo | Codigos podem ser prefixedos por contexto (`ENORMAL_`, `EFERIAS_`, `ERESCIS_`, etc.) e nao batem diretamente com toda a tabela CTE |
| Tabela EB | Tabela analitica/legal de rubricas | Base legal, incidencia esperada e rubricas marcadas como inconsistentes | Mistura linhas de rubrica com linhas continuadas de base legal; nao e historico temporal do eSocial |

Conclusao curta: **CTE + S-1010 ja ajudam muito a entender o que foi configurado e declarado, mas a Tabela EB ainda e essencial para indicar base legal e possiveis oportunidades/inconsistencias.**

## 1. Tabela enviada pela CTE

A tabela da CTE e uma planilha operacional de eventos/rubricas. Ela tem uma aba (`Plan1`) e veio em formato de relatorio paginado, com cabecalho repetido e legenda no rodape.

Numeros confirmados:

- 464 eventos com codigo e descricao.
- 78 eventos com linhas complementares.
- 82 linhas complementares associadas a eventos anteriores.
- 546 linhas evento + incidencia quando as continuacoes sao consideradas.
- 9 cabecalhos repetidos.
- 1 legenda final explicando abreviacoes.

Colunas principais identificadas:

- `Tab.`, `Codigo`, `Descricao`, `Car.`, `Reg.`, `Tp.`, `Nt.`, `Sl.`, `Rub.`.
- Bases/incidencias: `BR`, `FN`, `FD`, `FNI`, `FDI`, `InM`, `InD`, `IrM`, `IrF`, `IrD`, `IR`.

Interpretacao inicial da legenda:

- `BR`: remuneracao.
- `FN`: FGTS mensal.
- `FD`: FGTS 13o.
- `FNI`: FGTS mensal indenizado.
- `FDI`: FGTS 13o indenizado.
- `InM`: INSS mensal.
- `InD`: INSS 13o.
- `IrM`: IRRF mensal.
- `IrF`: IRRF ferias.
- `IrD`: IRRF 13o.
- `IR`: IRRF participacao nos lucros.

Essa fonte e muito boa para entender a configuracao interna da folha da CTE. O cuidado principal e nao importar uma linha como uma rubrica isolada, porque ha eventos com varias linhas de incidencia.

Exemplos relevantes ja identificados:

| Codigo CTE | Descricao | Observacao inicial |
| --- | --- | --- |
| `0204` | Ferias | Incide em bases especificas de FGTS/INSS/IRRF conforme colunas da CTE |
| `0558` | 1/3 Ferias | Evento separado de ferias |
| `0600` | Abono Pecuniario Ferias | Tratamento proprio, com incidencia de IRRF ferias na tabela CTE |
| `0650` | Ferias Vencidas Rescisao | Rescisao/ferias indenizadas precisam de regra propria |
| `0651` | Ferias Proporc.Rescisao | Rescisao/ferias indenizadas precisam de regra propria |
| `0950` | Aviso Previo Indenizado | Tem multiplas linhas na tabela CTE |
| `1963` | Premio | Tem multiplas linhas na tabela CTE |
| `3004` | Ajuda de custo | Evento tratado como sem incidencia nas colunas observadas |
| `0614` | Desconto Multa Transito | Evento sem incidencia nas colunas observadas |

## 2. S1010 todos os anos CTE

O arquivo `S1010 todos os anos CTE.zip` contem ZIPs mensais com XMLs S-1010. A estrutura lida foi:

- 85 entradas no ZIP externo.
- 76 ZIPs mensais internos.
- 2.018 XMLs S-1010 processados.
- 0 erros de parse.
- Periodo encontrado no arquivo: 2018 a 2025.
- Nao foi encontrado 2026 dentro do ZIP analisado.

Cobertura por ano, conforme os arquivos do ZIP:

| Ano | XMLs S-1010 | Meses presentes |
| --- | ---: | --- |
| 2018 | 535 | 08, 11, 12 |
| 2019 | 738 | 01 a 12 |
| 2020 | 138 | 01, 02, 03, 04, 05, 06, 07, 08, 10, 11, 12 |
| 2021 | 89 | 01 a 12 |
| 2022 | 140 | 01, 02, 03, 04, 05, 07, 09, 10, 11, 12 |
| 2023 | 274 | 01 a 12 |
| 2024 | 65 | 02, 04, 05, 06, 07, 08, 09, 10, 12 |
| 2025 | 39 | 01, 02, 03, 04, 06, 07, 11 |

Campos eSocial extraidos dos XMLs:

- Operacao: `inclusao`, `alteracao`, `exclusao`.
- Identificacao: `codRubr`, `ideTabRubr`, `iniValid`, `fimValid`.
- Dados: `dscRubr`, `natRubr`, `tpRubr`, `codIncCP`, `codIncIRRF`, `codIncFGTS`, `codIncSIND`.
- Processamento: `dhRecepcao`, `nrRecibo`, `cdResposta`, `descResposta`.
- Empregador: `tpInsc`, `nrInsc`.

Numeros confirmados:

- 1.083 `codRubr` unicos.
- 1.083 pares unicos `ideTabRubr + codRubr`.
- Operacoes: 1.750 inclusoes, 264 alteracoes, 4 exclusoes.
- Ambiente: todos os XMLs com `tpAmb = 1`.
- CNPJ raiz/inscricao encontrada: `64030638`.
- `ideTabRubr`: 1.600 eventos com `1` e 418 eventos com `0001`.
- Validade inicial variando de `2018-07` a `2025-11`.
- Recepcao variando de `2018-08-31T14:17:14.213` a `2025-11-27T17:04:25.91`.

Layouts encontrados:

- `evtTabRubrica/v02_04_02`: 536 XMLs.
- `evtTabRubrica/v02_05_00`: 931 XMLs.
- `evtTabRubrica/v_S_01_00_00`: 179 XMLs.
- `evtTabRubrica/v_S_01_01_00`: 268 XMLs.
- `evtTabRubrica/v_S_01_02_00`: 73 XMLs.
- `evtTabRubrica/v_S_01_03_00`: 31 XMLs.

Distribuicao das incidencias no S-1010:

| Campo | Principais valores |
| --- | --- |
| `tpRubr` | `1` = 1.240, `2` = 614, `3` = 118, `4` = 42 |
| `codIncCP` | `00` = 1.134, `11` = 642, `12` = 118, `31` = 57 |
| `codIncIRRF` | `11` = 586, `00` = 585, `13` = 195, `12` = 137, `79` = 118, `09` = 110 |
| `codIncFGTS` | `00` = 1.180, `11` = 644, `12` = 167, `21` = 16 |
| `codIncSIND` | `00` = 1.443, `11` = 19, `31` = 2 |

Naturezas mais frequentes no S-1010:

| Natureza | Quantidade |
| --- | ---: |
| `1020` | 95 |
| `9299` | 93 |
| `1003` | 91 |
| `1099` | 78 |
| `6006` | 66 |
| `1002` | 65 |
| `9213` | 62 |
| `1000` | 62 |
| `9200` | 60 |
| `6007` | 51 |

Achado importante: os `codRubr` do S-1010 aparecem em varios estilos, por exemplo:

- Numericos puros: `12`, `22`, `803`, etc.
- Prefixados por contexto: `ENORMAL_0001`, `EFERIAS_5710`, `ERESCIS_1240`, `INSSAVD_1240`, `IRRFSFE_1310`, etc.
- Codigos longos gerados por sistema: `SECTECENT200000000000000000...`.

Isso quer dizer que o S-1010 e fonte forte para historico eSocial, mas nao deve ser unido automaticamente a CTE/EB apenas pelo numero final do codigo.

## 3. Tabela EB

A `Tabela EB.xlsx` tem uma aba chamada `Tabela EB`, com 1.225 linhas e 10 colunas.

Cabecalho:

| Coluna | Nome |
| --- | --- |
| A | Cod Rubrica |
| B | Rubrica |
| C | Cod Natureza |
| D | INSS |
| E | IRRF |
| F | FGTS |
| G | Analise |
| H | Incid./Base Legal INSS |
| I | Incid./Base Legal IRRF |
| J | Incid./Base Legal FGTS |

Achado estrutural: nem toda linha e uma rubrica. A aba mistura linhas de rubrica com linhas de continuacao de base legal.

Classificacao inicial:

- 1.033 linhas reais de rubrica, identificadas por `Cod Rubrica` numerico.
- 191 linhas de continuacao de base legal, identificadas por texto juridico na primeira coluna.
- 1.033 codigos de rubrica unicos.
- Codigo minimo: `1`.
- Codigo maximo: `9287`.
- 93 naturezas eSocial distintas.

Distribuicao de analise:

| Analise | Quantidade |
| --- | ---: |
| `-` | 662 |
| Rubrica com inconsistencia de IRRF | 288 |
| Rubrica com inconsistencia de INSS, IRRF e FGTS | 49 |
| Rubrica com inconsistencia de INSS e FGTS | 12 |
| Rubrica com inconsistencia de FGTS | 11 |
| Rubrica com inconsistencia de IRRF e FGTS | 8 |
| Rubrica com inconsistencia de INSS e IRRF | 3 |

Total com alguma inconsistencia marcada: 371 rubricas.

Distribuicao das incidencias na EB:

| Campo | Principais valores |
| --- | --- |
| INSS | `0` = 508, `11` = 492, `12` = 17, `21` = 7 |
| IRRF | `11` = 490, `0` = 232, `9` = 209, `13` = 34, `12` = 19 |
| FGTS | `11` = 505, `0` = 479, `12` = 21, `31` = 18, `21` = 10 |

Naturezas mais frequentes na EB:

| Natureza | Quantidade |
| --- | ---: |
| `1003` | 160 |
| `1000` | 86 |
| `9299` | 78 |
| `1205` | 57 |
| `1211` | 40 |
| `2920` | 37 |
| `9232` | 34 |
| `6006` | 27 |
| `1806` | 24 |
| `1002` | 22 |
| `9209` | 22 |

Exemplos de codigos altos na EB indicam rubricas informativas eSocial:

| Codigo | Rubrica | Natureza |
| --- | --- | --- |
| `9276` | VALE TRANSPORTE (INFORMATIIVO ESOCIAL) | `1810` |
| `9277` | VALE REFEICAO (INFORMATIIVO ESOCIAL) | `1806` |
| `9278` | CESTA BASICA (INFORMATIIVO ESOCIAL) | `1808` |
| `9279` | ASSISTENCIA MEDICA (INFORMATIIVO ESOCIAL) | `9911` |
| `9284` | VALE ALIMENTACAO (INFORMATIIVO ESOCIAL) | `1806` |
| `9285` | BENEFICIO OUTROS (INFORMATIIVO ESOCIAL) | `9989` |

## Cruzamento inicial entre as tres fontes

Foi feito um cruzamento simples e conservador por codigo normalizado:

- CTE: codigo de evento de 4 digitos, removendo zeros a esquerda para comparar.
- EB: `Cod Rubrica` numerico.
- S-1010: sufixo numerico de `codRubr` quando existe, e tambem codigos numericos puros.

Resultados brutos:

| Cruzamento | Quantidade |
| --- | ---: |
| CTE x EB | 194 codigos coincidentes |
| CTE x S-1010 por sufixo | 73 codigos coincidentes |
| EB x S-1010 por sufixo | 210 codigos coincidentes |
| CTE x EB x S-1010 | 48 codigos coincidentes |

Mas este resultado bruto tem muitas falsas coincidencias. Exemplos:

| Codigo | CTE | EB | S-1010 |
| --- | --- | --- | --- |
| `0204` / `204` | Ferias | DIF. SALARIO 01/2015 | Sem match por sufixo |
| `0558` / `558` | 1/3 Ferias | DESC. ANTEC. ADIC. INSALUBRIDADE S/13o | Sem match por sufixo |
| `0600` / `600` | Abono Pecuniario Ferias | DESC. ACIDENTE DE TRABALHO (F.G.T.S.) | Sem match por sufixo |
| `0650` / `650` | Ferias Vencidas Rescisao | COMPL AJ COMPUSORIA MP936 | Sem match por sufixo |
| `0950` / `950` | Aviso Previo Indenizado | DIF. ASSISTENCIA MEDICA | Sem match por sufixo |
| `1000` | Aviso Previo Reavido | ADIC. NOTURNO C/20% - HORA EXTRA 100% | S-1010 `ENORMAL_1000` = periculosidade |
| `1400` | Ferias Indenizad.Rescisao | Sem EB | S-1010 `ENORMAL_1400` = reembolso |

Portanto, o achado tecnico mais importante e:

> **Nao usar codigo igual como chave unica entre CTE, S-1010 e EB.**

O codigo pode coincidir numericamente e representar rubricas completamente diferentes. A associacao precisa usar um conjunto de sinais: origem, codigo completo, descricao normalizada, natureza eSocial, tipo de rubrica, incidencias e contexto de folha.

## Como cada fonte deve entrar no TributaLab no futuro

### Fonte CTE

Usar como `source_kind = cte_event_table`.

Entidades sugeridas:

- Documento fonte.
- Evento CTE.
- Linha de incidencia CTE.
- Legenda/semantica das colunas.

Chave natural provavel:

- `source_document_id + tabela + codigo + numero_da_linha_ou_sequencia`.

### Fonte S-1010

Usar como `source_kind = esocial_s1010_xml`.

Entidades sugeridas:

- Documento fonte ZIP.
- ZIP mensal.
- Evento S-1010.
- Rubrica eSocial versionada.
- Recibo/processamento.

Chave natural provavel:

- `ideTabRubr + codRubr + iniValid + operacao + id_evento`.

Para estado vigente, aplicar linha do tempo por `ideTabRubr + codRubr`, considerando inclusao, alteracao, exclusao e validade.

### Fonte EB

Usar como `source_kind = eb_legal_rubric_table`.

Entidades sugeridas:

- Documento fonte.
- Rubrica EB.
- Natureza eSocial indicada.
- Incidencias esperadas por INSS/IRRF/FGTS.
- Analise/inconsistencia.
- Bases legais por tributo, preservando linhas de continuacao.

Chave natural provavel:

- `source_document_id + cod_rubrica`.

## Recomendacao de arquitetura para rubricas

O modelo futuro nao deve assumir uma tabela unica de rubricas. Deve permitir multiplas fontes e mapeamentos com confianca.

Modelo conceitual recomendado:

- `SourceDocument`: arquivo original, hash, origem, data de leitura.
- `RubricSourceRecord`: registro bruto de cada fonte, preservando campos originais.
- `RubricVersion`: representacao normalizada quando houver confianca suficiente.
- `IncidenceProfile`: incidencias por INSS, IRRF, FGTS, sindicato e bases especiais.
- `LegalBasis`: bases legais por tributo e por codigo de incidencia.
- `RubricMapping`: vinculos entre registros de fontes diferentes, com `confidence`, `method` e justificativa.
- `MappingReview`: fila de revisao manual para matches duvidosos.

Regras de ouro:

1. Preservar sempre o registro bruto antes de normalizar.
2. Nunca juntar fontes diferentes apenas por codigo numerico.
3. Tratar S-1010 como historico versionado, nao como catalogo plano.
4. Tratar a EB como camada legal/analitica, nao como substituto do historico S-1010.
5. Tratar a tabela CTE como configuracao operacional da folha, nao como eSocial puro.

## Proximo passo de pesquisa

Depois deste MD inicial, a pesquisa pode ser aprofundada em tres frentes:

1. Montar um extrato tabular do S-1010 com todos os 2.018 XMLs e um segundo extrato de estado mais recente por `ideTabRubr + codRubr`.
2. Montar uma leitura detalhada da EB, preservando as 191 linhas de continuacao de base legal e agrupando por rubrica.
3. Fazer matching assistido entre CTE, S-1010 e EB por descricao + natureza + incidencia, com grau de confianca, separando matches certos de falsos positivos.

Prioridade sugerida para recuperacao de credito:

- Comecar pelas 371 rubricas com inconsistencia na EB.
- Dentro delas, priorizar as 288 marcadas com inconsistencia de IRRF, pois sao o maior bloco.
- Cruzar depois com S-1010 para ver o que foi efetivamente declarado e com a tabela CTE para entender como a folha calculou cada base.
