# Indice de Fontes

Data da etapa: 2026-05-28

## Fonte principal encontrada

Pacote localizado em:

```text
c:/Users/xandao/Documents/GitHub/xAI/comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/
```

## Fontes consultadas

| Fonte | Status | Uso na Etapa 001 |
| --- | --- | --- |
| `00_CONTEXTO_PROJETO/call_denis_transcricao_2026-05-28.md` | Consultada e copiada | Confirmar separacao entre recuperacao de credito e reforma tributaria; operacoes e contexto do modulo imobiliario. |
| `00_CONTEXTO_PROJETO/arquitetura_inicial_sistema.md` | Consultada e copiada | Confirmar arquitetura em camadas: tipo de trabalho e recorte/setor. |
| `00_CONTEXTO_PROJETO/leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md` | Consultada e copiada | Confirmar abas, operacoes, parametros, creditos, formulas iniciais e divergencias. |
| `00_CONTEXTO_PROJETO/TRIBUTALAB_README_INICIAL_RAILS.md` | Consultada e copiada | Validar briefing de setup e protocolo por etapas. |
| `00_CONTEXTO_PROJETO/tabela_reforma_tributaria_segmento_imobiliario_lc227_2026.xlsx` | Referenciada e copiada | Fonte original da planilha-base; nao foi transformada em regra definitiva nesta etapa. |
| `01_VERBAS_RUBRICAS_COM_POSSIVEL_RECUPERACAO/` | Referenciada e copiada | Preservada para arquitetura futura de recuperacao de credito. |
| `02_MARCO_LEGAL_E_PERIODO_DE_CADA_VERBA/` | Referenciada e copiada | Preservada para arquitetura futura de base legal, risco, periodo e status de tese. |

## Fontes nao acessiveis

Nenhuma das fontes esperadas ficou inacessivel apos localizar o pacote no repositorio `xAI`.

## Copia local

O acervo foi copiado para:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/
```

Total copiado na Etapa 001: 22 arquivos.

## Atualizacao MD 004 - Rubricas/eSocial

Data da atualizacao: 2026-05-29

Objetivo: ressincronizar o agente de implementacao Rails/frontend com a realidade das fontes de rubricas e eSocial antes de iniciar qualquer tela ou fluxo de recuperacao de credito.

Mensagem de controle: as fontes abaixo nao formam uma tabela unica limpa nem comprovam credito tributario liquido. O uso correto neste momento e construir um radar/dossie de oportunidades e evidencias pendentes.

Fonte original consultada:

```text
c:/Users/xandao/Documents/GitHub/xAI/comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/
```

Copia local no repo Rails:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/
```

### Fontes copiadas na ressincronizacao

| Arquivo | Papel no produto | Tamanho | SHA256 |
| --- | --- | ---: | --- |
| `achados_fontes_rubricas_cte_s1010_eb_2026-05-29.md` | Sintese das quatro fontes reais: Tabela CTE, S-1010, Tabela EB e arquivo enquadrado. | 14.895 bytes | `C7A2F7807FACF73A0A1754BAF451D4B0FD70982DD79BEB396D172C65F3211819` |
| `pesquisa_s1010_recuperacao_credito_retroativa_2026-05-29.md` | Pesquisa oficial sobre uso do S-1010 como historico cadastral e caminho posterior para folha, DCTFWeb/DARF/FGTS e recuperacao. | 16.276 bytes | `CF23FFDBC8038E5C6248AA8FF8CF409C0D1B12A6D0EBE0D7DA88CE7FC472D713` |
| `leitura_tabela_eventos_rubricas_cte_2026-05-29.md` | Leitura da tabela operacional CTE com 464 eventos e alertas de interpretacao. | 11.312 bytes | `E561D8F766F62758BEEA75F987B59155F7331D8AFC07CB90E0588C3636DD2466` |
| `arquivo_enquadrado_2026-05-29.xlsx` | Ponte criada pelo Marco entre eventos CTE e Tabela 03/eSocial, com score, confianca e validacoes CP/IRRF/FGTS. | 49.901 bytes | `AC18F3C2E78D9F990207E8FE817D56416E7FFF85834B0D3A0D5D86F2AA866341` |
| `s1010_todos_os_anos_cte_2026-05-29.zip` | Pacote de XMLs oficiais/historicos S-1010 CTE, base cadastral por vigencia. | 9.753.614 bytes | `2780DCF583DA164216414B0B21AC83E3B8B16CF6D415781DADCECCDAE12DF467` |
| `tabela_eb_2026-05-29.xlsx` | Camada legal/analitica com rubricas, bases legais e inconsistencias. | 653.519 bytes | `F1F581571B47F05DA66A91772F2D5712927C0B2CA93B34525644D445658197AB` |

### Regras de uso para implementacao

- Nao mapear rubricas por codigo numerico isolado.
- Nao tratar `Nt.` da CTE como equivalente automatico de `natRubr` do eSocial.
- Nao apresentar credito confirmado, valor a restituir, economia garantida ou protocolo pronto enquanto faltarem folha, eventos financeiros, recolhimentos e validacao juridica.
- Para a primeira tela, usar linguagem de radar: `Radar de Recuperacao de Rubricas`, `Diagnostico de Incidencias`, `Oportunidade Potencial`, `Divergencia Declarado x Esperado`, `Evidencias Pendentes` e `Dossie de Recuperacao`.

Total copiado na ressincronizacao MD 004: 6 arquivos.

## Atualizacao MD 006 - Pontuacao de naturezas S-1010

Data da atualizacao: 2026-06-01

Objetivo: registrar a nova planilha enviada pelo Marco para orientar a tela principal de adequacao de rubricas por pontuacao entre eventos CTE e naturezas da Tabela 03/eSocial.

Fonte original local:

```text
C:/Users/xandao/Downloads/Tabela de Eventos - Rubricas (1).xlsx
```

Copia local no repo Rails:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/tabela_eventos_rubricas_marcos_tab03_2026-06-01.xlsx
```

| Arquivo | Papel no produto | Tamanho | SHA256 |
| --- | --- | ---: | --- |
| `tabela_eventos_rubricas_marcos_tab03_2026-06-01.xlsx` | Fonte principal da etapa de pontuacao de naturezas: aba `Plan1` com eventos/rubricas CTE e aba `tab03` com naturezas e incidencias eSocial. | 77.611 bytes | `867D8E7B38D0968C94F9721D4202CBD089A3543D31594AE1817A541D71886BA4` |

### Regras de uso para a etapa MD 006

- Pausar o parser historico S-1010 por vigencia.
- Usar esta planilha para listar os 464 eventos CTE e sugerir top 10 naturezas da Tabela 03 por pontuacao deterministica.
- Nao cruzar por codigo numerico isolado.
- Preservar duplicidades de natureza por vigencia, especialmente `1016` e `1017`.
- Nao consultar eSocial, nao baixar eventos e nao calcular credito financeiro.

## Atualizacao Base Legal - Relatorio de recuperacao de credito

Data da atualizacao: 2026-06-01

Objetivo: registrar a planilha `relatorio_recuperacao_credito.xlsx` usada na tela `Base Legal`, onde cada aba do arquivo e visualizada como uma tabela consultavel.

Fonte original local:

```text
C:/Users/xandao/Downloads/relatorio_recuperacao_credito (2).xlsx
```

Copia local no repo Rails:

```text
docs/04_referencias/pesquisa_original/base_legal/relatorio_recuperacao_credito.xlsx
```

| Arquivo | Papel no produto | SHA256 |
| --- | --- | --- |
| `relatorio_recuperacao_credito.xlsx` | Fonte da aba `Base Legal`, com tabelas das abas `Resumo`, `Rubricas`, `INSS - FGTS`, `IRPF` e `FGTS`. | `75064F89D788D4E23778E5AB560331E7E33205A83B68A69D5B859E6B8355C2E4` |

### Regras de uso para Base Legal

- Usar como visualizacao e apoio de sustentacao legal.
- Nao apresentar credito financeiro confirmado a partir desta fonte isolada.
- Nao consultar eSocial para carregar esta tela.
- Manter as abas da planilha visiveis como tabelas separadas.