# Relatorio - Auxilio doenca / atestado CTE - 5 anos

Data-base: 2026-07-02
Corte operacional: 2021-07 a 2026-07.
Observacao: segmentos S-1010 iniciados antes de 2021-07 aparecem quando continuavam vigentes dentro do corte de 5 anos.

## Conclusao executiva

A varredura local encontrou cadastro S-1010 e enquadramento CTE relacionados aos codigos da imagem, mas nao encontrou fonte de folha/S-1200, valores pagos ou guias/recolhimentos para quantificar ocorrencias ou afirmar estorno em dinheiro. Portanto, este dossie prova parametrizacao e evidencias cadastrais; a decisao de recuperacao depende do cruzamento financeiro.

Achados principais:

- 3302 e 3605 existem no catalogo CTE como complemento auxilio-doenca, natureza esperada 4010. Nao houve match direto pelos codigos no S-1010, mas ha S-1010 relacionado por descricao em 2025 para complemento auxilio-doenca.
- 0218 existe no catalogo como desconto de adiantamento de auxilio-doenca, natureza esperada 9209. Nao houve match direto, mas ha candidato S-1010 de 2025-06 com descricao de desconto adiantamento complemento auxilio Doenca.
- 0014 e 0213 tiveram match S-1010 por descricao. 0213 ficou alinhado no motor local; 0014 teve divergencia de FGTS, pois o esperado CTE marcava incidencia e o S-1010 declarou FGTS 00.
- A expressao 'poucas ocorrencias' nao pode ser confirmada com as fontes atuais. O ZIP S-1010 mostra cadastro, nao quantidade de pagamentos.

## Resumo por grupo

| Grupo | Codigos | S1010 5 anos | Achados | Nao avaliados | Decisao |
| --- | --- | --- | --- | --- | --- |
| Grupo 2 - verde | 3302 - Auxilio Doenca, 3605 - Complement Auxilio Doenca | 7 | 2 | 2 | Prioridade de revisao. Catalogo CTE aponta natureza 4010 e ha S-1010 relacionado em 2025 para complemento auxilio-doenca, mas sem match direto pelos codigos 3302/3605. Quantificacao depende de folha/S-1200 e recolhimentos. |
| Grupo 3 - amarelo | 0218 - Desc adto Auxilio doenca, 0213 - Dias Lic. Medica ate 15d, 0014 - Hrs Atestado ate 15 dias | 9 | 3 | 1 | Revisao mista. 0014 e 0213 tem match S-1010 por descricao; 0218 nao tem match direto, mas ha candidato S-1010 de desconto adiantamento complemento auxilio-doenca em 2025. Nao concluir estorno sem folha e prova da natureza real. |
| Grupo 4 - amarelo | 0014 - Hrs Atestado ate 15 dias | 2 | 1 | 0 | Mesmo nucleo da rubrica 0014. Evidencia S-1010 mostra CP/IRRF incidindo e FGTS 00; o motor marcou divergencia apenas de FGTS contra o esperado CTE. Nao e tese forte de nao incidencia previdenciaria pelos dados atuais. |

## Grupo 2 - verde

Rubricas verdes da imagem: auxilio doenca / complemento auxilio doenca.

### Enquadramento CTE
| Codigo | Descricao | Linha | Natureza | CP | IRRF | FGTS | Campos |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3302 | Complement Auxílio Doença | 115 | 4010 | incide | nao_incide | nao_incide | CAR=39Z TP=1 CMP=367 SEQ=01 |
| 3302 | Complement Auxílio Doença | 1218 | 4010 | nao_incide | nao_incide | nao_incide | CAR=03G TP=1 CMP=367 SEQ=01 |
| 3605 | Complement Auxílio Doença | 116 | 4010 | nao_incide | nao_incide | nao_incide | CAR=39Z TP=4 CMP=367 SEQ=01 |
| 3605 | Complement Auxílio Doença | 1219 | 4010 | nao_incide | nao_incide | nao_incide | CAR=03G TP=4 CMP=367 SEQ=01 |

### S-1010 relacionado no corte
| Inicio | Fim | CodRubr | Descricao | Natureza | CP | IRRF | FGTS | Fonte | XML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2018-07 |  | 8870 | DIAS AFAST PDOENCA CDIRINTEGRAIS | 1050 | 11 / incide | 11 / incide | 11 / incide | descricao:afastamento_doenca | ID1640306380000002022112108325800001.S-1010.xml |
| 2018-07 |  | 9505 | DIAS AFAST PDOENCA IGUALINF 15 DIAS | 1050 | 00 / nao_incide | 11 / incide | 11 / incide | descricao:afastamento_doenca | ID1640306380000002021040814270800004.S-1010.xml |
| 2019-01 |  | ENORMAL_1140 | AUXÍLIO ENFERMIDADE | 1050 | 11 / incide | 11 / incide | 11 / incide | descricao:enfermidade | ID1640306380000002019021111212600141.S-1010.xml |
| 2024-11 |  | SECTECENT200000000000000000258 | Dias Auxílio Doença | 9933 | 00 / nao_incide | 09 / incide | 00 / nao_incide | descricao:auxilio_doenca | ID1640306380000002024120517395300003.S-1010.xml |
| 2025-05 |  | SECTECENT200000000000000000288 | Complemento Auxílio Doença (Informativo na folha) | 4010 | 00 / nao_incide | 09 / incide | 00 / nao_incide | descricao:auxilio_doenca, descricao:complemento_auxilio_doenca | ID1640306380000002025060316093200004.S-1010.xml |
| 2025-05 |  | SECTECENT200000000000000000289 | Complemento Auxílio Doença (Provento) | 4010 | 11 / incide | 09 / incide | 00 / nao_incide | descricao:auxilio_doenca, descricao:complemento_auxilio_doenca | ID1640306380000002025060316093200006.S-1010.xml |
| 2025-06 |  | SECTECENT200000000000000000291 | Desconto adiantamento domplemento auxilio Doença | 9209 | 11 / incide | 11 / incide | 11 / incide | descricao:auxilio_doenca | ID1640306380000002025071017471400001.S-1010.xml |

### Achados do motor
| Codigo | Periodo | Esperado | Declarado | Divergencia | Confianca | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 3302 | sem S-1010 vinculado | nat 4010 CP incide IRRF nao_incide FGTS nao_incide | sem S-1010 vinculado | not_evaluated | needs_review | pending |
| 3605 | sem S-1010 vinculado | nat 4010 CP nao_incide IRRF nao_incide FGTS nao_incide | sem S-1010 vinculado | not_evaluated | needs_review | pending |

### Leitura operacional

Prioridade de revisao. Catalogo CTE aponta natureza 4010 e ha S-1010 relacionado em 2025 para complemento auxilio-doenca, mas sem match direto pelos codigos 3302/3605. Quantificacao depende de folha/S-1200 e recolhimentos.

## Grupo 3 - amarelo

Rubricas amarelas da pergunta 3: desc adto auxilio doenca, dias licenca medica, horas atestado ate 15 dias.

### Enquadramento CTE
| Codigo | Descricao | Linha | Natureza | CP | IRRF | FGTS | Campos |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0218 | Desc adto Auxilio doença | 143 | 9209 | unknown | unknown | unknown | CAR=49H TP=3 CMP=367 SEQ=01 |
| 0213 | Dias Lic. Médica até 15d | 216 | 1050 | incide | incide | incide | CAR=03N TP=1 CMP=367 SEQ=01 |
| 0213 | Dias Lic. Médica até 15d | 775 | 0 | incide | incide | incide | CAR=03N TP=1 CMP=367 SEQ=01 |
| 0213 | Dias Lic. Médica até 15d | 1314 | 1000 | incide | incide | incide | CAR=03N TP=1 CMP=367 SEQ=01 |
| 0014 | Hrs Atestado até 15 dias | 340 | 1000 | incide | incide | incide | CAR=01N TP=1 CMP=367 SEQ=01 |
| 0014 | Hrs Atestado até 15 dias | 886 | 0 | incide | incide | incide | CAR=01N TP=1 CMP=367 SEQ=01 |
| 0014 | Hrs Atestado até 15 dias | 1442 | 1000 | incide | incide | incide | CAR=01N TP=1 CMP=367 SEQ=01 |

### S-1010 relacionado no corte
| Inicio | Fim | CodRubr | Descricao | Natureza | CP | IRRF | FGTS | Fonte | XML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2018-07 |  | 8870 | DIAS AFAST PDOENCA CDIRINTEGRAIS | 1050 | 11 / incide | 11 / incide | 11 / incide | descricao:dias_afastamento_doenca | ID1640306380000002022112108325800001.S-1010.xml |
| 2018-07 |  | 9505 | DIAS AFAST PDOENCA IGUALINF 15 DIAS | 1050 | 00 / nao_incide | 11 / incide | 11 / incide | descricao:dias_afastamento_doenca | ID1640306380000002021040814270800004.S-1010.xml |
| 2018-07 |  | SECTECENT200000000000000000003 | Hrs Atestado at 15 dias | 1000 | 11 / incide | 11 / incide | 11 / incide | descricao:atestado | ID1640306380000002023051616352000002.S-1010.xml |
| 2023-12 |  | SECTECENT200000000000000000199 | Hrs Atestado até 15 dias | 1000 | 11 / incide | 11 / incide | 00 / nao_incide | descricao:atestado, link_identidade | ID1640306380000002023121517282400003.S-1010.xml |
| 2024-02 |  | SECTECENT200000000000000000205 | Dias Lic. Médica até 15d | 1050 | 11 / incide | 11 / incide | 11 / incide | descricao:licenca_medica, link_identidade | ID1640306380000002024022812514100003.S-1010.xml |
| 2024-11 |  | SECTECENT200000000000000000258 | Dias Auxílio Doença | 9933 | 00 / nao_incide | 09 / incide | 00 / nao_incide | descricao:auxilio_doenca | ID1640306380000002024120517395300003.S-1010.xml |
| 2025-05 |  | SECTECENT200000000000000000288 | Complemento Auxílio Doença (Informativo na folha) | 4010 | 00 / nao_incide | 09 / incide | 00 / nao_incide | descricao:auxilio_doenca | ID1640306380000002025060316093200004.S-1010.xml |
| 2025-05 |  | SECTECENT200000000000000000289 | Complemento Auxílio Doença (Provento) | 4010 | 11 / incide | 09 / incide | 00 / nao_incide | descricao:auxilio_doenca | ID1640306380000002025060316093200006.S-1010.xml |
| 2025-06 |  | SECTECENT200000000000000000291 | Desconto adiantamento domplemento auxilio Doença | 9209 | 11 / incide | 11 / incide | 11 / incide | descricao:auxilio_doenca, descricao:desc_adto_auxilio_doenca | ID1640306380000002025071017471400001.S-1010.xml |

### Achados do motor
| Codigo | Periodo | Esperado | Declarado | Divergencia | Confianca | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 0014 | 2023-12 | nat 1000 CP incide IRRF incide FGTS incide | nat 1000 CP 11 IRRF 11 FGTS 00 | fgts | needs_review | pending |
| 0213 | 2024-02 | nat 1050 CP incide IRRF incide FGTS incide | nat 1050 CP 11 IRRF 11 FGTS 11 | none | aligned | aligned |
| 0218 | sem S-1010 vinculado | nat 9209 CP unknown IRRF unknown FGTS unknown | sem S-1010 vinculado | not_evaluated | needs_review | pending |

### Leitura operacional

Revisao mista. 0014 e 0213 tem match S-1010 por descricao; 0218 nao tem match direto, mas ha candidato S-1010 de desconto adiantamento complemento auxilio-doenca em 2025. Nao concluir estorno sem folha e prova da natureza real.

## Grupo 4 - amarelo

Rubrica amarela da pergunta 4: horas atestado ate 15 dias.

### Enquadramento CTE
| Codigo | Descricao | Linha | Natureza | CP | IRRF | FGTS | Campos |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0014 | Hrs Atestado até 15 dias | 340 | 1000 | incide | incide | incide | CAR=01N TP=1 CMP=367 SEQ=01 |
| 0014 | Hrs Atestado até 15 dias | 886 | 0 | incide | incide | incide | CAR=01N TP=1 CMP=367 SEQ=01 |
| 0014 | Hrs Atestado até 15 dias | 1442 | 1000 | incide | incide | incide | CAR=01N TP=1 CMP=367 SEQ=01 |

### S-1010 relacionado no corte
| Inicio | Fim | CodRubr | Descricao | Natureza | CP | IRRF | FGTS | Fonte | XML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2018-07 |  | SECTECENT200000000000000000003 | Hrs Atestado at 15 dias | 1000 | 11 / incide | 11 / incide | 11 / incide | descricao:atestado | ID1640306380000002023051616352000002.S-1010.xml |
| 2023-12 |  | SECTECENT200000000000000000199 | Hrs Atestado até 15 dias | 1000 | 11 / incide | 11 / incide | 00 / nao_incide | descricao:atestado, link_identidade | ID1640306380000002023121517282400003.S-1010.xml |

### Achados do motor
| Codigo | Periodo | Esperado | Declarado | Divergencia | Confianca | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 0014 | 2023-12 | nat 1000 CP incide IRRF incide FGTS incide | nat 1000 CP 11 IRRF 11 FGTS 00 | fgts | needs_review | pending |

### Leitura operacional

Mesmo nucleo da rubrica 0014. Evidencia S-1010 mostra CP/IRRF incidindo e FGTS 00; o motor marcou divergencia apenas de FGTS contra o esperado CTE. Nao e tese forte de nao incidencia previdenciaria pelos dados atuais.

## Fontes e limitacoes

Fontes usadas:

- S-1010 todos os anos CTE: `docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/s1010_todos_os_anos_cte_2026_06_02.zip`; origem `C:/Users/xandao/Downloads/S1010 todos os anos CTE.zip`; SHA256 `D86534A1C783FE639937641556D998E9BD7E8BA60AC6488E38FFD68025B97DF8`
- Natureza E-Social por Rubrica CTE: `docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/natureza_esocial_por_rubrica_cte.xlsx`; origem `C:/Users/xandao/Downloads/Natureza E-Social por Rubrica CTE.xlsx`
- Metodologia de prazo e incidencias: `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/02_MARCO_LEGAL_E_PERIODO_DE_CADA_VERBA/prazo_de_recuperacao_e_excecoes.md`
- Metodologia de prazo e incidencias: `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/02_MARCO_LEGAL_E_PERIODO_DE_CADA_VERBA/tributos_e_incidencias_afetados.md`
- Metodologia de prazo e incidencias: `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/02_MARCO_LEGAL_E_PERIODO_DE_CADA_VERBA/identificar_se_verba_e_tributavel_ou_nao.md`

Limitacoes:

- O workspace nao contem S-1200/folha mensal nem guias/recolhimentos suficientes para quantificar valor ou numero real de pagamentos por competencia.
- S-1010 prova cadastro parametrico da rubrica, nao prova pagamento ou recolhimento indevido sozinho.
- A decisao de estorno/recuperacao exige cruzamento com folha, DCTFWeb/GFIP/DARF/FGTS e documento que demonstre a natureza real da verba.

## Checklist para transformar em pedido de estorno/recuperacao

1. Obter folha/S-1200 dos ultimos 5 anos para os codigos e candidatos S-1010 listados na planilha.
2. Cruzar por competencia com DCTFWeb/GFIP/DARF/GPS e, separadamente, FGTS/FGTS Digital/Caixa.
3. Confirmar documentos de afastamento, atestado, auxilio-doenca e politica/rotina de complemento para provar a natureza real.
4. Separar CP/RAT/terceiros, FGTS e IRRF em trilhas distintas.
5. So pedir estorno quando houver valor pago, base indevida e prova documental por competencia.
