# REBUILD 002 - Fonte Natureza E-Social por Rubrica CTE

Data: 2026-06-02
Projeto: Prev Lab

## Fonte analisada

Arquivo original:

```text
C:/Users/xandao/Downloads/Natureza E-Social por Rubrica CTE.xlsx
```

Copia preservada no repo:

```text
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/natureza_esocial_por_rubrica_cte.xlsx
```

SHA256:

```text
0B1B647B44D083CFD161787E28FB53DB88E493D38A59A596F5678F063C0FC2B7
```

## Estrutura encontrada

```text
Aba: Plan1
Linhas: 1725
Colunas: 33
Cabecalho real: linha 5
```

Colunas:

```text
Tabela
Codigo
Descricao
[coluna vazia]
eSoc
Car.
Tp.
CmpInc
Seq.
FN
FD
FNI
FDI
InM
InD
InA
IRR
IrM
IrF
IrD
Ir
IrA
PIS
PID
IPM
IPD
IPF
RP
TR
Rem
Vinculo
Inicio
Fim
```

Resumo limpo da coluna `eSoc`:

```text
Linhas com eSoc preenchido: 1575
Linhas numericas com eSoc: 1509
Linhas com eSoc = 0: 1120
Linhas com eSoc diferente de 0: 389
Rubricas CTE unicas com eSoc numerico: 470
Rubricas CTE unicas com eSoc diferente de 0: 220
Naturezas eSocial unicas, sem contar zero: 65
Rubricas com mais de uma natureza eSocial diferente de zero: 22
```

Naturezas mais frequentes com eSoc diferente de zero:

```text
1000: 26
1003: 23
9989: 16
9213: 15
1016: 14
1350: 13
9201: 13
1023: 12
5001: 12
6003: 12
1020: 12
6007: 11
9200: 11
1203: 11
9219: 10
9299: 10
```

Exemplos reais:

```text
0609 - 1/3 Abono Pecuniario Fer -> eSoc 1023
0558 - 1/3 Ferias -> eSoc 1016 e 1017
1408 - 1/3 Ferias Ind.Rescisao -> eSoc 6006, com linha anterior eSoc 0
0659 - 1/3 Ferias Rescisao -> eSoc 6007 e 6006
0900 - 13o Indenizado Rescisao -> eSoc 6001
0750 - 13o Salario Adiantado -> eSoc 5504
0800 - 13o Salario Integral -> eSoc 5001
1950 - Adicional Noturno -> eSoc 1205
0270 - Ajuda Compensatoria MP936 -> eSoc 1619
3004 - Ajuda de custo -> eSoc 1603
```

Rubricas com mais de uma natureza nao devem ser achatadas para uma unica resposta. Exemplos:

```text
0558 -> 1016, 1017, 1020
0659 -> 6006, 6007
0278 -> 1003, 1004
0277 -> 1003, 1004
3609 -> 1002, 1012, 9910
1756 -> 1016, 1020
0610 -> 1016, 1023
```

## O que essa fonte resolve

Esta planilha muda a hierarquia do sistema.

Antes, o sistema estava tentando sugerir natureza eSocial por pontuacao. Agora existe uma fonte direta:

```text
Rubrica CTE -> natureza eSocial esperada/principal
```

Portanto, a coluna `eSoc` deve virar fonte primaria de enquadramento, e o score deve virar apoio:

- validar se a natureza escolhida faz sentido;
- encontrar divergencias quando o S-1010 historico declarou outra coisa;
- preencher sugestao quando `eSoc = 0`;
- ranquear alternativas para revisao humana.

As colunas de incidencia ajudam a formar a matriz esperada por tributo:

```text
FN, FD, FNI, FDI
InM, InD, InA
IRR, IrM, IrF, IrD, Ir, IrA
PIS, PID, IPM, IPD, IPF
RP, TR, Rem
Inicio, Fim
```

Para o produto atual, as principais colunas operacionais sao:

```text
Codigo
Descricao
eSoc
FN
InM
IrM
Inicio
Fim
```

## O que ela nao resolve sozinha

Ela nao prova o que a empresa declarou no eSocial historico. Para isso, usar o ZIP S-1010.

Ela tambem nao prova pagamento indevido. Para dinheiro, ainda faltam folha e recolhimento.

Outro cuidado: `eSoc = 0` nao deve ser interpretado automaticamente como erro ou inexistencia de oportunidade. Pode significar ausencia de mapeamento direto na fonte, exigindo fallback por score, texto, incidencia e revisao humana.

## Como usar no sistema novo

Criar uma camada de catalogo CTE:

```text
cte_rubric_catalogs
cte_rubrics
cte_rubric_esocial_mappings
cte_rubric_incidence_profiles
```

Campos essenciais:

```text
tabela
codigo_cte
descricao_cte
esocial_nature_code
car
tp
cmp_inc
seq
fn
inm
irm
inicio
fim
source_row
source_sha256
```

Regra de modelagem:

- uma rubrica CTE pode ter varias linhas;
- uma rubrica CTE pode ter varias naturezas;
- a escolha correta pode depender de vigencia, tipo, complemento e incidencia;
- preservar `source_row` para auditoria.

## Decisao para o rebuild

Essa fonte e o motivo mais forte para recomecar a arquitetura de dados. Ela torna obsoleto tratar o sistema como apenas um motor de pontuacao. O novo sistema deve nascer com mapeamento fonte-primaria, fallback por score e comparacao contra S-1010 historico.
