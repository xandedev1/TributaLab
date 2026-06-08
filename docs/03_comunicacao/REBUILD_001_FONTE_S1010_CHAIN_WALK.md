# REBUILD 001 - Fonte S-1010 Historico / Chain Walk

Data: 2026-06-02
Projeto: Prev Lab

## Fonte analisada

Arquivo original:

```text
C:/Users/xandao/Downloads/S1010 todos os anos CTE.zip
```

Copia preservada no repo:

```text
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/s1010_todos_os_anos_cte_2026_06_02.zip
```

SHA256:

```text
D86534A1C783FE639937641556D998E9BD7E8BA60AC6488E38FFD68025B97DF8
```

Observacao: a pasta `S1010 todos os anos CTE 2` nao apareceu como pasta solta em Downloads. Ela esta dentro do ZIP principal como diretorio raiz, contendo ZIPs mensais por ano.

## Estrutura encontrada

O ZIP principal contem ZIPs mensais aninhados:

```text
S1010 todos os anos CTE 2/2018/mes 08.zip
S1010 todos os anos CTE 2/2019/mes 2.zip
...
S1010 todos os anos CTE 2/2026/mes 5.zip
```

Resumo tecnico:

```text
Entradas no ZIP principal: 90
ZIPs mensais aninhados: 80
XMLs S-1010 encontrados recursivamente: 2031
XMLs parseados com codRubr: 2031
Erros de parse: 0
Periodo por iniValid: 2018-07 ate 2026-04
Rubricas unicas por ideTabRubr + codRubr: 1094
Naturezas eSocial unicas declaradas: 121
Rubricas com mais de uma versao: 674
Rubricas com mudanca real de natureza/incidencias: 107
```

Acoes encontradas:

```text
inclusao: 1761
alteracao: 266
exclusao: 4
```

Distribuicao por ano de `iniValid`:

```text
2018: 1061
2019: 745
2020: 6
2021: 4
2022: 4
2023: 96
2024: 67
2025: 35
2026: 13
```

## O que essa fonte resolve

Esta e a fonte central para a linha do tempo real do que foi enviado ao eSocial.

Ela permite montar o `chain walk` de cada rubrica:

- quando a rubrica apareceu no S-1010;
- qual `natRubr` foi declarada em cada vigencia;
- quais codigos de incidencia foram declarados em CP, IRRF e FGTS;
- quando houve alteracao de natureza ou incidencia;
- qual recibo/documento sustenta cada versao;
- qual periodo historico ficou exposto a uma parametrizacao possivelmente errada.

Exemplos de mudanca detectada:

```text
ENORMAL_5610 / ADIANTAMENTO (VALE)
2019-01: natRubr 9200, CP 00, IRRF 00, FGTS 00
2019-09: natRubr 9200, CP 00, IRRF 11, FGTS 00
2020-01: natRubr 9200, CP 00, IRRF 00, FGTS 00

ENORMAL_4965 / ADIC. PERIC. S/ ABONO
mudou de natRubr 1021, CP 00, IRRF 00, FGTS 00
para natRubr 1203, CP 11, IRRF 11, FGTS 11

ENORMAL_4950 / 1/3 SOBRE AS MEDIAS
mudou de natRubr 1020, CP 11, IRRF 11, FGTS 11
para natRubr 6006, CP 00, IRRF 13, FGTS 00
```

## O que ela nao resolve sozinha

O S-1010 mostra o cadastro enviado, nao prova pagamento indevido sozinho.

Para recuperacao financeira ainda faltam:

- valores efetivamente pagos em folha;
- bases de INSS/IRRF/FGTS por periodo;
- DCTFWeb/DARF/FGTS ou equivalentes de recolhimento;
- tese juridica aplicavel por verba/natureza;
- validacao humana antes de afirmar credito recuperavel.

Tambem ha uma diferenca importante de codificacao: muitas rubricas no S-1010 aparecem com prefixos como `ENORMAL_`, `EFERIAS_`, `ERESCIS_`, `IRRFSFE_` ou codigos especiais. Portanto, nao se pode cruzar com as tabelas CTE apenas por codigo numerico de quatro digitos.

## Como usar no sistema novo

Criar uma tabela historica de eventos S-1010, preservando cada XML como evidencia imutavel:

```text
s1010_sources
s1010_events
s1010_rubric_versions
s1010_rubric_timeline_segments
```

Campos essenciais:

```text
source_zip
nested_zip
xml_path
nrRecibo
action
ideTabRubr
codRubr_raw
codRubr_normalized
dscRubr
iniValid
fimValid
natRubr
tpRubr
codIncCP
codIncIRRF
codIncFGTS
observacao
xml_sha256
```

Depois, gerar segmentos de linha do tempo por rubrica:

```text
vigencia_inicio
vigencia_fim
natRubr_declarada
incidencia_cp_declarada
incidencia_irrf_declarada
incidencia_fgts_declarada
mudou_desde_segmento_anterior
tipo_mudanca
```

## Tela esperada

Uma tela `Chain Walk S-1010` deve permitir:

- procurar por rubrica CTE, descricao ou codRubr S-1010;
- ver a linha do tempo de 2018 a 2026;
- comparar natureza/incidencias declaradas contra a natureza esperada;
- destacar quando a empresa comecou a declarar diferente;
- indicar o periodo potencialmente recuperavel, sem calcular dinheiro sem folha/recolhimento;
- abrir o XML/recibo de cada marco historico.

## Decisao para o rebuild

Essa fonte justifica uma arquitetura nova. O sistema atual nao nasceu com timeline S-1010 como eixo central. Para o produto de recuperacao retroativa, o chain walk deve ser uma das entidades principais, nao um detalhe posterior.
