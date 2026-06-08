# REBUILD 004 - Fonte relatorio_recuperacao_credito

Data: 2026-06-02
Projeto: Prev Lab

## Fonte analisada

Arquivo original:

```text
C:/Users/xandao/Downloads/relatorio_recuperacao_credito (2).xlsx
```

Copia preservada no repo:

```text
docs/04_referencias/pesquisa_original/base_legal/relatorio_recuperacao_credito.xlsx
```

SHA256:

```text
75064F89D788D4E23778E5AB560331E7E33205A83B68A69D5B859E6B8355C2E4
```

## Estrutura encontrada

Abas:

```text
Resumo: 10 linhas, 4 colunas, 9 linhas de dados
Rubricas: 42 linhas, 14 colunas, 41 linhas de dados
INSS - FGTS: 29 linhas, 14 colunas, 28 linhas de dados
IRPF: 13 linhas, 14 colunas, 12 linhas de dados
FGTS: 2 linhas, 14 colunas, 1 linha de dados
```

Colunas das abas operacionais:

```text
Categoria
Subcategoria
Base Legal
Plan1.Codigo
Plan1.Descricao
Plan1.Tipo RB
Plan1.InM (INSS)
Plan1.IrM (IRRF)
Plan1.FN (FGTS)
tab03.Codigo
tab03.Nome
Validacao INSS
Validacao IRRF
Validacao FGTS
```

Resumo quantitativo:

```text
Rubricas CTE unicas: 32
Validacoes VERDADEIRO: 240
Validacoes FALSO: 6
```

Categorias:

```text
INSS / FGTS: 56 linhas somando abas operacionais
IRPF: 24 linhas somando abas operacionais
FGTS: 2 linhas somando abas operacionais
```

Exemplos de base legal:

```text
5998 - Aviso Indenizado -> Art. 487 CLT; Sumula 305 TST
0650 - Ferias Vencidas Rescisao -> Art. 148 CLT; OJ 195 SDI-1 TST
0651 - Ferias Proporc.Rescisao -> Art. 148 CLT; OJ 195 SDI-1 TST
0659 - 1/3 Ferias Rescisao -> OJ 195 SDI-1 TST + OJ 356 SDI-1 TST
1408 - 1/3 Ferias Ind.Rescisao -> OJ 195 SDI-1 TST + OJ 356 SDI-1 TST
1150 - Indenizacao Lei 6708/79 -> Lei 6.708/79 + Lei 7.238/84
```

## O que essa fonte resolve

Ela e a fonte de sustentacao juridica/tributaria para oportunidades selecionadas.

Resolve principalmente:

- quais teses existem;
- qual base legal sustenta a nao incidencia ou incidencia correta;
- quais rubricas CTE estao ligadas a cada tese;
- quais tributos sao afetados, especialmente INSS, FGTS e IRRF;
- como separar oportunidades por categoria e subcategoria.

## O que ela nao resolve sozinha

Ela cobre apenas 32 rubricas unicas, portanto nao e catalogo completo da CTE.

Ela tambem nao diz o historico real declarado no S-1010 e nao contem valores de folha/recolhimento.

Logo, nao deve virar motor de calculo financeiro isolado.

## Como usar no sistema novo

Criar uma biblioteca de teses e fundamentos:

```text
legal_theses
legal_thesis_rubrics
legal_basis_references
legal_tax_impacts
```

Campos essenciais:

```text
categoria
subcategoria
base_legal_texto
codigo_cte
descricao_cte
tipo_rubrica
incidencia_cte_cp
incidencia_cte_irrf
incidencia_cte_fgts
esocial_nature_code
esocial_nature_name
validacao_cp
validacao_irrf
validacao_fgts
source_sheet
source_row
```

Uso na interface:

- painel de teses por rubrica;
- explicacao juridica no dossie;
- filtro de oportunidade por tributo;
- alerta quando uma rubrica tem divergencia tecnica mas nao tem tese legal cadastrada;
- alerta quando ha tese legal, mas ainda falta folha/recolhimento.

## Decisao para o rebuild

Essa fonte nao substitui as fontes tecnicas. Ela deve ser a camada juridica do novo sistema, acoplada a mapeamento CTE/eSocial e ao chain walk S-1010.
