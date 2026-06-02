# Resposta pronta - Alinhamento antes da Etapa 004

Use o bloco abaixo como resposta ao agente de implementacao.

```text
Li o MD 004 e entendi a mudanca de premissa.

Nao devemos mais partir da ideia de que existe uma base unica, limpa e organizada de rubricas. A realidade atual e que existem quatro camadas diferentes, cada uma com uma funcao propria:

1. S-1010 CTE: fonte oficial e historica do cadastro de rubricas no eSocial, com vigencias e incidencias declaradas pela empresa.
2. Tabela CTE: fonte operacional, util para conversa com cliente/consultoria, mas nao equivalente direta ao eSocial.
3. Tabela EB: camada analitica/legal, com bases legais e inconsistencias, mas nao cadastro oficial enviado ao eSocial.
4. arquivo_enquadrado: ponte inicial criada pelo Marco entre os eventos CTE e a Tabela 03/eSocial, com score, confianca e validacoes CP/IRRF/FGTS.

Portanto, eu nao vou criar tela de credito em reais, credito recuperavel, valor a restituir, economia garantida ou protocolo pronto. O proximo passo correto e uma etapa separada:

Etapa 004 - Radar de Recuperacao de Rubricas eSocial

Complemento tecnico do MD 005: a primeira entrega da Etapa 004 deve usar os numeros reais do arquivo_enquadrado. Nao usar dados mockados se isso significar inventar numeros. Pode ser snapshot, seed ou fixture, mas baseado nos numeros reais ja apurados.

Arquivos encontrados no repo:

- docs/03_comunicacao/MD_004_PARA_AGENTE_IMPLEMENTACAO_RAILS.md
- docs/03_comunicacao/MD_005_CRUZAMENTOS_APRESENTACAO_RECUPERACAO_S1010.md
- docs/04_referencias/INDICE_FONTES.md
- docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/achados_fontes_rubricas_cte_s1010_eb_2026-05-29.md
- docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/pesquisa_s1010_recuperacao_credito_retroativa_2026-05-29.md
- docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/leitura_tabela_eventos_rubricas_cte_2026-05-29.md
- docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquivo_enquadrado_2026-05-29.xlsx
- docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/s1010_todos_os_anos_cte_2026-05-29.zip
- docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/tabela_eb_2026-05-29.xlsx

Arquivo faltante no caminho exato solicitado:

- docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/MD_004_RESSINCRONIZACAO_RUBRICAS_RECUPERACAO.md

O conteudo equivalente esta em:

- docs/03_comunicacao/MD_004_PARA_AGENTE_IMPLEMENTACAO_RAILS.md

Antes de implementar, o primeiro ajuste documental recomendado e copiar/criar o MD 004 tambem no caminho exato esperado, para evitar desalinhamento entre agentes.

Plano minimo para a Etapa 004:

1. Garantir que todas as fontes estejam registradas no INDICE_FONTES.md com hashes e papel de uso.
2. Criar uma tela somente leitura chamada Radar de Recuperacao - Rubricas eSocial.
3. Comecar pelo cruzamento CTE x Tabela 03/eSocial via arquivo_enquadrado.
4. Mostrar totais e diagnosticos com numeros reais do arquivo_enquadrado.
5. Mostrar divergencias CP/INSS, IRRF e FGTS a partir do arquivo_enquadrado.
6. Exibir confianca, score, grupo de evento, tipo de divergencia e evidencias pendentes.
7. Deixar adequacao S-1010, EB/base legal, folha, recolhimento e parecer como camadas/estados de evidencia.
8. Documentar claramente que ainda faltam folha, eventos periodicos, recolhimentos e parecer juridico.
9. Nao calcular dinheiro nesta primeira versao.

Numeros reais obrigatorios no radar inicial:

- 464 eventos analisados.
- 247 com pelo menos uma divergencia.
- 224 registros/eventos divergentes com confianca alta/media.
- 140 divergencias CP/INSS.
- 245 divergencias IRRF.
- 126 divergencias FGTS.
- 217 sem divergencia CP/IRRF/FGTS.

Distribuicao de confianca:

- ALTA: 297.
- MEDIA: 106.
- BAIXA: 37.
- MUITO_BAIXA: 24.

Padroes de conflito:

- CP + IRRF + FGTS: 120.
- Apenas IRRF: 101.
- CP + IRRF: 20.
- IRRF + FGTS: 4.
- Apenas FGTS: 2.
- Apenas CP: 0.

Leitura tecnica: IRRF tem o maior volume numerico de divergencia, mas nao deve ser tratado como credito automatico da empresa. Para MVP de recuperacao, INSS/CP continua sendo a frente mais segura juridica e operacionalmente.

Telas/modelos pretendidos para a primeira versao:

- Rota/tela: /rubric_recovery ou /rubric_recovery/radar
- Controller: RubricRecoveryController ou RubricRecovery::RadarController
- View: painel somente leitura com metricas, filtros e tabela de divergencias
- Service/view-model inicial: RubricRecovery::RadarSnapshot, para evitar modelagem pesada cedo demais
- Primeiro cruzamento implementado: CTE x Tabela 03/eSocial via arquivo_enquadrado
- Camada S-1010: pendente/encontrada, sem tentar resolver todo o historico na primeira entrega

Se for necessario persistir dados ja nesta etapa, os modelos candidatos sao:

- RubricSource: origem, arquivo, hash, data de carga e papel da fonte
- RubricMapping: ponte CTE/S-1010/EB/Tabela 03, score, confianca e divergencias CP/IRRF/FGTS
- EvidenceItem: status de evidencias pendentes por oportunidade ou divergencia

Eu nao pretendo criar agora um modelo de credito final nem uma tela de credito liquido. A linguagem correta sera: Radar de Recuperacao de Rubricas, Diagnostico de Incidencias, Oportunidade Potencial, Divergencia Declarado x Esperado, Evidencias Pendentes e Dossie de Recuperacao.

Regras de apresentacao da tela:

- Separar divergencia encontrada, adequacao S-1010 pendente/encontrada, base legal EB pendente/encontrada, folha pendente, recolhimento pendente e parecer pendente.
- Nunca cruzar por codigo numerico isolado.
- Para S-1010, quando essa camada for implementada, comparar ideTabRubr + codRubr + descricao + natRubr + codIncCP/codIncIRRF/codIncFGTS + vigencia contra o enquadramento esperado.
- Sem folha e recolhimento, nao exibir credito em reais.

Resumo: o produto neste momento deve ajudar Alessandro/Denis a enxergar onde pode haver recuperacao e o que ainda precisa ser provado, sem afirmar que o dinheiro ja esta recuperavel.
```