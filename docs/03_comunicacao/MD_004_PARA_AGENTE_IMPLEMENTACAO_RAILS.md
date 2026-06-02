# MD 004 - Ressincronizacao com agente de implementacao

Data: 2026-05-29
Projeto: TributaLab
Origem: pesquisa/arquiteto de dados fiscais
Destino: agente de implementacao Rails/frontend
Objetivo: alinhar a outra IA com a realidade atual das fontes de rubricas/eSocial antes de ela continuar implementando telas ou fluxos.

## Mensagem curta para a outra IA

Voce avancou bastante em frontend/operacional, mas agora precisa ressincronizar com a realidade dos dados. A premissa anterior de que existiria uma base original ja organizada de rubricas nao esta correta.

Hoje temos quatro fontes reais, cada uma com papel diferente:

1. Tabela CTE: operacional, meio baguncada, com 464 eventos.
2. S-1010 CTE: XMLs oficiais/historicos do eSocial, com 2.018 XMLs e 1.083 `codRubr` unicos entre 2018 e 2025.
3. Tabela EB: camada legal/analitica, com 1.033 rubricas e muitas inconsistencias marcadas.
4. `arquivo_enquadrado`: tabela feita pelo Marco, cruzando os 464 eventos CTE com Tabela 03/eSocial, score/confianca e validacoes CP/IRRF/FGTS.

Nao trate essas fontes como se fossem uma tabela unica limpa. Elas sao camadas diferentes que precisam ser conciliadas.

## Arquivos que precisam ser lidos agora

Antes de continuar UI ou modelagem de recuperacao de credito, leia:

1. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/achados_fontes_rubricas_cte_s1010_eb_2026-05-29.md`
2. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/pesquisa_s1010_recuperacao_credito_retroativa_2026-05-29.md`
3. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/leitura_tabela_eventos_rubricas_cte_2026-05-29.md`
4. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquivo_enquadrado_2026-05-29.xlsx`
5. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/s1010_todos_os_anos_cte_2026-05-29.zip`
6. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/tabela_eb_2026-05-29.xlsx`

Se esses arquivos ainda nao estiverem no repo Rails, copie/referencie a pasta original preservando hashes e registre em `docs/04_referencias/INDICE_FONTES.md`.

## Correcao de rumo importante

Nao construir agora uma tela que finja que ja existe credito tributario calculado.

O que existe hoje:

- historico cadastral oficial de rubricas no S-1010;
- uma tabela CTE operacional;
- uma tabela EB com leitura legal/analitica;
- uma ponte inicial do Marco no `arquivo_enquadrado`;
- pesquisa oficial mostrando o caminho S-1010 -> folha/eventos -> DCTFWeb/DARF/FGTS -> retificacao/restituicao/compensacao.

O que ainda nao existe:

- folha financeira por competencia;
- eventos S-1200/S-2299/S-2399/S-1210 com valores por trabalhador/rubrica;
- DCTFWeb/DARF/GPS/SEFIP/FGTS Digital completos por competencia;
- calculo final em reais;
- parecer juridico final por rubrica;
- credito pronto para protocolo.

Portanto, o produto certo neste momento e um radar/dossie de oportunidades, nao uma tela de credito liquido.

## Linguagem de produto correta

Use estes termos:

- Radar de Recuperacao de Rubricas
- Diagnostico de Incidencias
- Oportunidade Potencial
- Divergencia Declarado x Esperado
- Evidencias Pendentes
- Dossie de Recuperacao

Evite estes termos antes de haver folha/recolhimento/validacao juridica:

- credito confirmado
- credito recuperavel
- valor a restituir
- economia garantida
- protocolo pronto

## Modelo mental dos dados

### S-1010

Fonte oficial/historica do cadastro de rubricas.

Campos importantes:

- `ideTabRubr`
- `codRubr`
- `iniValid`
- `fimValid`
- `dscRubr`
- `natRubr`
- `tpRubr`
- `codIncCP`
- `codIncIRRF`
- `codIncFGTS`
- `nrRecibo`

Serve para saber como a empresa declarou a regra da rubrica em cada periodo.

### Tabela CTE

Fonte operacional enviada pela CTE.

Tem 464 eventos. E util para conversar com o cliente/consultoria, mas nao e eSocial puro.

Colunas importantes:

- `Tab.`
- `Codigo`
- `Descricao`
- `Car.`
- `Reg.`
- `Tp.`
- `Nt.`
- incidencias como `InM`, `IrM`, `FN` e outras.

Atencao: `Nt.` da CTE nao equivale a `natRubr` do eSocial.

### Tabela EB

Camada legal/analitica.

Tem 1.033 rubricas, bases legais e inconsistencias marcadas. Deve ser usada como fonte de tese/analise, nao como cadastro oficial enviado ao eSocial.

### Arquivo enquadrado

Ponte criada pelo Marco entre os 464 eventos CTE e a Tabela 03/eSocial.

Tem:

- codigo e descricao CTE;
- tipo/natureza tab03;
- `codIncCP`, `codIncIRRF`, `codIncFGTS` esperados;
- validacoes CP/IRRF/FGTS;
- `score_match`;
- `confianca`;
- `grupo_evento`;
- `incompativel_tipo`.

E a melhor base inicial para uma primeira tela visual de divergencias, mas cobre apenas os 464 eventos CTE.

## Regra critica de cruzamento

Nunca mapear por codigo numerico isolado.

O mesmo numero pode significar rubricas diferentes em CTE, EB e S-1010.

Chave minima de conciliacao:

- origem da fonte;
- tabela;
- codigo;
- descricao normalizada;
- natureza eSocial;
- incidencias CP/IRRF/FGTS;
- vigencia;
- contexto operacional.

## Primeira tela de recuperacao sugerida

Nome: `Radar de Recuperacao - Rubricas eSocial`.

Ela deve mostrar:

- total de rubricas S-1010 importadas;
- total de eventos CTE mapeados;
- divergencias por CP/INSS, IRRF e FGTS;
- distribuicao por confianca do `arquivo_enquadrado`;
- top rubricas com conflito;
- status da evidencia: cadastro S-1010, mapeamento Marco, base legal EB, folha, recolhimento, parecer;
- filtro por tributo, confianca, grupo de evento e tipo de divergencia.

Nao precisa calcular dinheiro na primeira versao.

## Prioridade por tributo

### INSS / Contribuicao Previdenciaria

Prioridade alta para MVP.

Motivo: S-1010 tem `codIncCP`; Lei 8.212 define salario-de-contribuicao e exclusoes; DCTFWeb nasce do eSocial; Lei 8.212 art. 89 admite restituicao/compensacao por pagamento indevido ou maior que o devido.

### IRRF

Prioridade media e com cautela.

Motivo: envolve retencao do trabalhador/beneficiario. Pode haver oportunidade, mas nao tratar como credito automatico da empresa.

### FGTS

Prioridade media para diagnostico.

Motivo: S-1010 tem `codIncFGTS`, mas o canal de recuperacao nao e PER/DCOMP/RFB comum. Precisa trilha propria por FGTS Digital/Caixa/MTE conforme periodo.

## Possivel modelagem inicial

Nao precisa implementar tudo de uma vez. Se for iniciar modelagem, comece por leitura/importacao e visualizacao.

Entidades candidatas:

- `RubricSource`: fonte, arquivo, hash, data de carga.
- `RubricVersion`: rubrica S-1010 por vigencia.
- `RubricMapping`: ligacao CTE/S-1010/EB/Tabela 03 com score e confianca.
- `LegalPosition`: tese por tributo/rubrica.
- `CreditOpportunity`: oportunidade potencial, ainda sem valor obrigatorio.
- `EvidenceItem`: documentos/evidencias por oportunidade.

Nao modelar ainda como credito final.

## Proxima tarefa recomendada para a outra IA

Se a Etapa 003 imobiliaria ja estiver em andamento, nao misture recuperacao de rubricas dentro dela sem registrar decisao. A Etapa 003 original era operacional para simulacoes imobiliarias.

Para rubricas, abrir uma etapa propria:

```text
Etapa 004 - Radar de Recuperacao de Rubricas eSocial
```

Escopo minimo da Etapa 004:

1. Registrar fontes em `INDICE_FONTES.md`.
2. Criar uma pagina somente leitura do radar.
3. Carregar dados mockados ou seedados a partir dos numeros reais ja apurados.
4. Mostrar divergencias do `arquivo_enquadrado` sem prometer credito em reais.
5. Criar status de evidencias pendentes.
6. Documentar claramente que folha/recolhimentos ainda faltam.

## Mensagem final para a outra IA

Antes de continuar implementando, pare e alinhe o produto com os dados reais. O front pode estar bonito, mas a verdade do projeto agora e: temos uma base forte para detectar divergencias de rubricas, nao ainda uma base completa para calcular credito retroativo em reais.

Construa o proximo passo como ferramenta de investigacao e validacao interna: radar, filtros, ranking, confianca e pendencias de evidencia.

O objetivo e ajudar Alessandro/Denis a enxergar onde pode haver recuperacao, nao afirmar que o dinheiro ja esta recuperavel.