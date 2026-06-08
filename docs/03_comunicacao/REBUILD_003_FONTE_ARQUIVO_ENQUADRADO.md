# REBUILD 003 - Fonte arquivo_enquadrado

Data: 2026-06-02
Projeto: Prev Lab

## Fonte analisada

Arquivo:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquivo_enquadrado_2026-05-29.xlsx
```

SHA256:

```text
AC18F3C2E78D9F990207E8FE817D56416E7FFF85834B0D3A0D5D86F2AA866341
```

## Estrutura encontrada

```text
Aba: Enquadramento
Linhas: 465
Colunas: 19
Cabecalho: linha 1
Linhas de dados: 464
Rubricas Plan1 unicas: 464
Naturezas tab03 unicas usadas: 68
```

Colunas:

```text
Plan1.Codigo
Plan1.Descricao
Plan1.Tipo RB
tab03.Tipo RB
tab03.Codigo
tab03.Nome
Plan1.InM
tab03.codIncCP
Validacao CP
Plan1.IrM
tab03.codIncIRRF
Validacao IRRF
Plan1.FN
tab03.codIncFGTS
Validacao FGTS
score_match
confianca
grupo_evento
incompativel_tipo
```

Resumo de confianca:

```text
ALTA: 297
MEDIA: 106
BAIXA: 37
MUITO_BAIXA: 24
```

Resumo de divergencias:

```text
Registros com alguma divergencia: 247
Registros divergentes com confianca alta/media: 224
CP verdadeiro: 324
CP falso: 140
IRRF verdadeiro: 219
IRRF falso: 245
FGTS verdadeiro: 338
FGTS falso: 126
```

Naturezas tab03 mais frequentes no enquadramento:

```text
1016: 55
9989: 44
5001: 29
4050: 26
1003: 23
1050: 19
1099: 15
5504: 13
1629: 13
1203: 11
1619: 11
1023: 11
```

Exemplos de divergencia alta/media:

```text
0005 - Horas Ferias Diurnas -> tab03 1016 / Ferias
CP OK, IRRF divergente, FGTS OK, score 1, confianca ALTA

0007 - Horas Auxilio Doenca -> tab03 4010 / Complementacao salarial de auxilio-doenca
CP OK, IRRF divergente, FGTS OK, score 1, confianca ALTA, tipo incompativel

0008 - Horas Servico Militar -> tab03 1050 / Remuneracao de dias de afastamento
CP divergente, IRRF divergente, FGTS OK, score 0.6264, confianca MEDIA
```

## O que essa fonte resolve

O `arquivo_enquadrado` e uma excelente fonte de diagnostico inicial:

- cobre as 464 rubricas/eventos CTE da etapa anterior;
- traz uma natureza tab03 sugerida;
- compara incidencias declaradas na Plan1 contra codigos esperados da tab03;
- aponta divergencias CP/IRRF/FGTS;
- separa confianca e incompatibilidade de tipo.

Ele e util para montar uma fila de revisao e para validar se o novo sistema esta reproduzindo os principais achados antigos.

## O que ela nao resolve sozinha

Ela nao deve ser mais a fonte primaria de natureza eSocial, porque a planilha nova `Natureza E-Social por Rubrica CTE.xlsx` traz a coluna `eSoc` direta por rubrica.

Tambem nao substitui o S-1010 historico, porque nao diz quando a empresa declarou cada incidencia no tempo.

E tambem nao prova pagamento indevido, pois nao contem valores pagos/recolhidos.

## Como usar no sistema novo

Usar como camada de QA, comparacao e bootstrap:

```text
legacy_enquadramento_rows
legacy_enquadramento_findings
```

Finalidades:

- comparar o novo mapeamento CTE -> eSoc contra o enquadramento antigo;
- marcar regressao quando o novo sistema perder uma divergencia relevante;
- priorizar casos com alta/media confianca;
- alimentar uma tela de `Conflitos entre fontes`.

Regra importante:

```text
Natureza E-Social por Rubrica CTE = fonte primaria de mapeamento.
arquivo_enquadrado = evidencia auxiliar, diagnostico e regressao.
```

## Decisao para o rebuild

O arquivo continua valioso, mas nao deve comandar a arquitetura. No rebuild ele entra como fonte historica de comparacao e validacao dos novos achados.
