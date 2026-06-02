# Leitura da Tabela de Eventos - Rubricas CTE

Data: 2026-05-29

## Arquivo analisado

Arquivo original localizado em Downloads:

- `Tabela de Eventos - Rubricas.xlsx`

Arquivo salvo no pacote de pesquisa:

- `tabela_eventos_rubricas_cte_2026-05-29.xlsx`

Hash SHA256 da versao copiada:

- `C11C46E1129D85D22BCB862ED27B53A5E1623C8D461A156EC8B2A10128659DA8`

## Leitura geral

A planilha e uma tabela de eventos/rubricas da CTE, extraida em formato de relatorio paginado.

Ela e muito mais rica do que uma lista simples de rubricas. Contem codigos de eventos, descricoes, caracteristicas, regras, tipo de evento, natureza, rubrica HomologNet e indicadores de incidencia para remuneracao, FGTS, INSS e IRRF.

Essa tabela muda o peso do eixo futuro de **Recuperacao de Credito** no TributaLab: em vez de modelar apenas teses soltas, o sistema vai precisar acomodar um catalogo real de eventos/rubricas do cliente, com incidencias e possiveis divergencias por tributo.

## Estrutura do arquivo

Workbook:

- Abas: 1
- Aba: `Plan1`
- Dimensao: `A1:U600`
- Linhas preenchidas: 592
- Formulas: 0
- Comentarios: 0
- Abas ocultas: 0
- Linhas ocultas: 0
- Colunas ocultas: 0

A planilha tem cabecalho repetido por pagina nas linhas:

- 4
- 75
- 146
- 217
- 288
- 359
- 430
- 501
- 572

## Colunas identificadas

Cabecalho principal:

| Coluna | Nome | Significado pela legenda |
| --- | --- | --- |
| A | Tab. | Tabela |
| B | Codigo | Codigo do evento |
| C | Descricao | Descricao do evento/rubrica |
| E | Car. | Caracteristica |
| F | Reg. | Regra |
| G | Tp. | Tipo Evento |
| H | Nt. | Natureza |
| I | Sl. | Sinal Selecao |
| J | Rub. | Rubrica HomologNet |
| K | BR | Incidencias - Remuneracao |
| L | FN | Incidencias - FGTS Mensal |
| M | FD | Incidencias - FGTS 13o |
| N | FNI | Incidencias - FGTS Mensal Indenizado |
| O | FDI | Incidencias - FGTS 13o Indenizado |
| P | InM | Incidencias - INSS Mensal |
| Q | InD | Incidencias - INSS 13o |
| R | IrM | Incidencias - IRRF Mensal |
| S | IrF | Incidencias - IRRF Ferias |
| T | IrD | Incidencias - IRRF 13o |
| U | IR | Incidencias - IRRF Participacao nos Lucros |

## Legenda literal no rodape

A legenda aparece nas linhas 591 a 600:

```text
Car. - Caracteristica
Reg. - Regra
Tp.  - Tipo Evento
Nt.  - Natureza
Sl.  - Sinal Selecao
Rub - Rubrica HomologNet
BR   - Incidencias - Remuneracao
FN   - Incidencias - FGTS Mensal
FD   - Incidencias - FGTS 13o
FNI  - Incidencias - FGTS Mensal Indenizado
FDI  - Incidencias - FGTS 13o Indenizado
InM  - Incidencias - INSS Mensal
InD  - Incidencias - INSS 13o
IrM  - Incidencias - IRRF Mensal
IrF  - Incidencias - IRRF Ferias
IrD  - Incidencias - IRRF 13o
IR   - Incidencias - IRRF Participacao nos Lucros
```

O cabecalho indica que os valores de incidencia usam:

```text
+  -  N
```

Interpretacao operacional inicial:

- `+`: incidencia positiva / soma / compoe base.
- `-`: incidencia negativa / desconto / reduz base.
- `N`: nao incide / neutro.

Essa interpretacao precisa ser validada com CTE/Denis antes de virar regra definitiva.

## Volume de dados

A extracao identificou:

- 464 eventos com codigo e descricao;
- 78 eventos com linhas complementares de incidencia;
- 82 linhas complementares associadas a eventos anteriores;
- 546 linhas evento+incidencia ao considerar continuacoes;
- 9 paginas/cabecalhos repetidos;
- 1 bloco de legenda no rodape.

Ponto critico: **nao tratar a planilha como uma linha igual a uma rubrica simples**.

Alguns eventos possuem uma ou mais linhas complementares sem codigo/descricao, mas com indicadores preenchidos. Essas linhas provavelmente representam continuacoes de incidencia e precisam ser preservadas ou associadas ao evento anterior.

Exemplos com multiplas linhas:

| Codigo | Descricao | Quantidade de linhas |
| --- | --- | --- |
| 0950 | Aviso Previo Indenizado | 3 |
| 0958 | Dias Aviso Previo Indeniz | 3 |
| 1963 | Premio | 3 |
| 3004 | Ajuda de custo | 3 |
| 0259 | Horas Extras c/ 100% | 2 |
| 0265 | DSR Reflexo H.Extras/Bh | 2 |
| 0558 | 1/3 Ferias | 2 |
| 0600 | Abono Pecuniario Ferias | 2 |
| 0650 | Ferias Vencidas Rescisao | 2 |
| 0651 | Ferias Proporc.Rescisao | 2 |

## Distribuicao de tipos e indicadores

### Tipo de evento (`Tp.`)

| Tipo | Quantidade |
| --- | ---: |
| 1 | 276 |
| 3 | 119 |
| 4 | 63 |
| 2 | 5 |
| 6 | 1 |

O significado de cada tipo precisa ser validado com a CTE ou com a documentacao do sistema de folha.

### Rubrica HomologNet (`Rub.`)

Principais codigos encontrados entre eventos com codigo/descricao:

| Rub. | Quantidade |
| --- | ---: |
| 000 | 390 |
| 004 | 19 |
| 104 | 11 |
| 005 | 10 |
| 002 | 8 |
| 110 | 7 |
| 035 | 5 |
| 014 | 2 |
| 007 | 2 |
| 114 | 2 |
| 101 | 2 |

Considerando linhas complementares, `000` aparece 464 vezes e `004` aparece 24 vezes.

### Incidencias principais entre eventos com codigo/descricao

| Indicador | Distribuicao observada |
| --- | --- |
| BR | N=448, +=15, -=1 |
| FN | N=314, +=145, -=5 |
| FD | N=419, +=43, -=2 |
| FNI | N=464 |
| FDI | N=464 |
| InM | N=330, +=129, -=5 |
| InD | N=437, +=24, -=3 |
| IrM | N=330, +=116, -=18 |
| IrF | N=395, +=58, -=11 |
| IrD | N=428, +=28, -=8 |
| IR | N=462, +=1, -=1 |

Isso indica que a tabela permite cruzar rubrica/evento contra bases de:

- remuneracao;
- FGTS mensal;
- FGTS 13o;
- FGTS indenizado;
- INSS mensal;
- INSS 13o;
- IRRF mensal;
- IRRF ferias;
- IRRF 13o;
- IRRF PLR.

## Rubricas relevantes para as pesquisas ja feitas

A tabela conversa diretamente com os arquivos de pesquisa de verbas/rubricas ja criados no pacote.

### Ferias e terco constitucional

Eventos encontrados:

- `0204` - Ferias
- `0558` - 1/3 Ferias
- `0600` - Abono Pecuniario Ferias
- `0609` - 1/3 Abono Pecuniario Fer
- `0650` - Ferias Vencidas Rescisao
- `0651` - Ferias Proporc.Rescisao
- `0659` - 1/3 Ferias Rescisao
- `1400` - Ferias Indenizad.Rescisao
- `1408` - 1/3 Ferias Ind.Rescisao
- `3017` - DIFERENCA 1/3 DE FERIAS
- `3021` - DIFERENCA 1/3 ABONO

### Aviso previo

Eventos encontrados:

- `0016` - Aviso Previo Trabalhado
- `0115` - Aviso Previo Trab.Noturn
- `0950` - Aviso Previo Indenizado
- `0958` - Dias Aviso Previo Indeniz
- `1000` - Aviso Previo Reavido
- `1007` - Dias Aviso Previo Reavido
- `1008` - Dias Aviso Previo Reavido
- `5998` - Aviso Indenizado

### Indenizacoes e rescisao

Eventos encontrados:

- `0900` - 13o Indenizado Rescisao
- `1150` - Indenizacao Lei 6708/79
- `1151` - Dias Indeniz.Lei 6708/79
- `1200` - Estabilidade Rescisao
- `1400` - Ferias Indenizad.Rescisao
- `1551` - FGTS Pago Rescisao
- `1552` - FGTS 40% Pago Rescisao
- `1560` - Dsr Indenizado

### Multas

Eventos encontrados:

- `0560` - Multa Dobro Ferias
- `0611` - Multa Dobro Abono Pec.
- `0660` - Multa Dobro Ferias Resc.
- `1409` - Multa Dobro Fer.Ind Resc.
- `0614` - Desconto Multa Transito

### Vale transporte / transporte

Eventos encontrados:

- `1651` - Pgto Vale Transporte
- `2453` - Vale Transporte (Descto)
- `2469` - Vale Transporte desc retr
- `3003` - Reembolso Vale Transporte

### Auxilios

Eventos encontrados:

- `0006` - Horas Aux.Maternidade
- `0007` - Horas Auxilio Doenca
- `0017` - Auxilio Maternidade INSS
- `0218` - Desc adto Auxilio doenca
- `1500` - Aux.Natalidade
- `3302` - Complement Auxilio Doenca
- `3605` - Complement Auxilio Doenca

### Ajuda de custo

Eventos encontrados:

- `0270` - Ajuda Compensatoria MP936
- `2458` - Desconto Ajuda de Custo
- `3004` - Ajuda de custo

### PLR / lucros

Eventos encontrados:

- `1601` - Dist.Lucros Lei 8541/95
- `1602` - Lucro Arbitrado
- `1955` - Participacao Lucros/Resul
- `2012` - IR Participacao Lucros

### Premios e gratificacoes

Eventos encontrados:

- `1960` - Premio em Horas
- `1963` - Premio
- `1100` - Gratificacao Rescisao
- `1965` - Gratificacao

### Adicionais trabalhistas

Eventos encontrados:

- `1950` - Adicional Noturno
- `1951` - Insalubridade
- `1952` - Periculosidade
- `3609` - DSR Adicional Noturno

## Impacto no TributaLab

Essa tabela nao deve entrar na Etapa 003 da Reforma Tributaria Imobiliaria como calculo de IBS/CBS. Ela pertence ao eixo futuro de **Recuperacao de Credito / Folha / Rubricas**.

Mas ela muda a arquitetura futura. O TributaLab vai precisar, em etapa propria, de entidades como:

- `RubricCatalog` ou `PayrollEventCatalog`;
- `PayrollEvent`;
- `PayrollEventIncidenceLine`;
- `IncidenceFlag`;
- `HomologNetRubricCode`;
- `PayrollThesis`;
- `RubricThesisMapping`;
- `IncidenceComparison`;
- `CreditOpportunity`.

Pontos importantes para arquitetura:

1. Um evento pode ter multiplas linhas de incidencia.
2. A tabela separa FGTS mensal, FGTS 13o, FGTS indenizado, INSS mensal, INSS 13o, IRRF mensal, IRRF ferias, IRRF 13o e IRRF PLR.
3. A classificacao de recuperacao nao pode depender so da descricao da rubrica.
4. E necessario comparar a incidencia configurada na folha contra a tese juridica aplicavel.
5. Rubricas com `+`, `-` e `N` precisam de interpretacao validada antes de calcular credito.
6. Codigos `Car.`, `Reg.`, `Tp.`, `Nt.`, `Sl.` e `Rub.` precisam virar dicionarios ou tabelas auxiliares quando o eixo de recuperacao for implementado.

## Recomendacao operacional

Nao alterar o escopo da Etapa 003 por causa dessa tabela, se a Etapa 003 estiver focada em Reforma Tributaria Imobiliaria.

Criar apenas um MD complementar para o agente Rails avisando que:

- chegou uma nova fonte importante;
- ela deve ser copiada para `docs/04_referencias/pesquisa_original/`, se ainda nao estiver no repo do TributaLab;
- ela nao deve virar modulo agora;
- ela deve ser considerada no desenho futuro de Recuperacao de Credito;
- nao deve implementar parsing/importacao de rubricas na Etapa 003.

## Perguntas para CTE / Denis

1. Confirmar significado operacional de `+`, `-` e `N` em cada incidencia.
2. Confirmar significado dos tipos de evento `Tp.`: 1, 2, 3, 4 e 6.
3. Confirmar se linhas sem codigo/descricao sao continuacoes do evento imediatamente anterior.
4. Confirmar se `Rub.` corresponde exatamente a Rubrica HomologNet.
5. Confirmar se `Reg.` e `Car.` possuem dicionario externo.
6. Confirmar se essa tabela e a versao atual vigente da folha da CTE.
7. Confirmar data de extracao/competencia da tabela.
8. Confirmar se ha outra tabela com valores pagos por periodo, alem da tabela de eventos.
9. Confirmar se existe de/para entre esses eventos e rubricas do eSocial.
10. Confirmar se a CTE tem historico de alteracao de incidencias por periodo.

## Conclusao

A tabela e uma fonte central para o futuro modulo de Recuperacao de Credito por rubricas. Ela nao substitui as pesquisas juridicas ja feitas; ela fornece o mapa operacional real da folha da CTE.

A partir dela, o TributaLab podera cruzar:

```text
rubrica/evento da folha -> incidencia configurada -> tese juridica -> periodo -> potencial de recuperacao
```

Esse cruzamento deve ser tratado em etapa propria. Para agora, a prioridade e preservar a fonte, documentar a leitura e avisar o agente da Etapa 003 para nao ignorar essa nova informacao.
