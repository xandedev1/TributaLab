# REBUILD 006 - Handoff para Outro Agente

Data: 2026-06-02
Projeto: Prev Lab
Objetivo: explicar o plano completo para outro agente ler, avaliar e continuar a implementacao do novo modulo de rubricas CTE.

## Mensagem direta para o proximo agente

Voce esta entrando em um projeto Rails chamado Prev Lab. O usuario recebeu uma fonte nova muito importante e perguntou se deveria apagar tudo e recomecar do zero. A resposta tecnica foi: sim, a arquitetura do modulo de rubricas deve recomecar como uma v2 limpa, mas nao se deve apagar literalmente o sistema atual agora.

O sistema atual tem trabalho util ja feito: parsers, telas, docs, Base Legal, radar/score e conhecimento de divergencias. Mas a nova fonte `Natureza E-Social por Rubrica CTE.xlsx` muda o centro do produto. A partir de agora, o modulo de rubricas nao deve nascer em torno de score/top 10. Ele deve nascer em torno de catalogo CTE, natureza eSocial esperada, S-1010 historico declarado, divergencia real e base legal.

Nao consulte eSocial. Use apenas os arquivos locais ja copiados para o repo.

## Leia estes 5 documentos primeiro

Leia nesta ordem:

1. `docs/03_comunicacao/REBUILD_005_PLANO_SISTEMA_NOVO_RUBRICAS_CTE.md`
   - Documento principal.
   - Explica a decisao: criar v2, nao apagar o sistema atual.
   - Traz modelo de dados recomendado, ordem de importacao, telas e criterios.

2. `docs/03_comunicacao/REBUILD_002_FONTE_NATUREZA_ESOCIAL_RUBRICA_CTE.md`
   - Fonte primaria de mapeamento esperado.
   - A coluna `eSoc` e a chave principal para rubrica CTE -> natureza eSocial.
   - O score antigo vira fallback/QA, nao decisor principal.

3. `docs/03_comunicacao/REBUILD_001_FONTE_S1010_CHAIN_WALK.md`
   - Fonte historica real declarada no eSocial.
   - O ZIP tem ZIPs mensais aninhados e precisa ser parseado recursivamente.
   - Serve para montar linha do tempo por rubrica e descobrir quando a declaracao ficou divergente.

4. `docs/03_comunicacao/REBUILD_004_FONTE_RELATORIO_RECUPERACAO_CREDITO.md`
   - Fonte de base legal/tese.
   - Nao e catalogo completo de rubricas.
   - Deve alimentar biblioteca juridica e texto de dossie.

5. `docs/03_comunicacao/REBUILD_003_FONTE_ARQUIVO_ENQUADRADO.md`
   - Diagnostico legado e QA.
   - Use para comparar a v2 contra divergencias ja conhecidas.
   - Nao use como fonte primaria.

## Arquivos locais importantes

Fontes copiadas para dentro do repo:

```text
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/natureza_esocial_por_rubrica_cte.xlsx
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/s1010_todos_os_anos_cte_2026_06_02.zip
docs/04_referencias/pesquisa_original/base_legal/relatorio_recuperacao_credito.xlsx
```

Indice de fontes:

```text
docs/04_referencias/INDICE_FONTES.md
```

Handoff geral anterior:

```text
docs/03_comunicacao/MD_009_HANDOFF_UNICO_PARA_OUTRA_IA.md
```

## Decisao de arquitetura

Crie uma v2 isolada do modulo de rubricas CTE.

Nao delete agora:

- tabelas antigas;
- telas antigas;
- docs existentes;
- score/top 10;
- Base Legal atual;
- parsers ja implementados.

Rebaixe o que existe para referencia, prototipo, QA e fallback. A v2 deve ter nomes e tabelas proprios para evitar misturar conceito antigo com conceito novo.

Fluxo mental correto:

```text
catalogo CTE
-> natureza eSocial esperada pela coluna eSoc
-> incidencias esperadas CP/IRRF/FGTS
-> S-1010 real declarado por vigencia
-> divergencia historica
-> tese/base legal
-> dossie
-> credito potencial somente depois, com folha/recolhimento
```

Fluxo antigo que nao deve mandar mais:

```text
score -> top 10 -> sugestao principal de natureza
```

O score continua util, mas so como:

- fallback quando `eSoc = 0` ou fonte ambigua;
- QA contra divergencias conhecidas;
- explicacao auxiliar;
- fila de revisao humana.

## Plano de implementacao recomendado

### Fase 1 - Nucleo de dados v2

Criar migrations/models para separar completamente a v2. Nomes podem ser ajustados ao padrao Rails do repo, mas o desenho recomendado e:

```text
RubricasCte::SourceFile
RubricasCte::ImportRun
RubricasCte::CatalogRubric
RubricasCte::ExpectedMapping
RubricasCte::ExpectedIncidence
RubricasCte::S1010Event
RubricasCte::S1010TimelineSegment
RubricasCte::RubricIdentityLink
RubricasCte::LegalThesis
RubricasCte::Finding
```

Campos essenciais:

- fonte, caminho local, hash e data de importacao;
- codigo CTE, descricao, tabela, tipo e vigencia;
- natureza eSocial esperada vinda da coluna `eSoc`;
- incidencias esperadas CP/IRRF/FGTS quando disponiveis;
- XML S-1010 original, recibo, acao, `ideTabRubr`, `codRubr`, `natRubr`, `codIncCP`, `codIncIRRF`, `codIncFGTS`, `iniValid`, `fimValid`;
- vinculo entre rubrica CTE e rubrica S-1010, com metodo de match;
- achados/finding com severidade, confianca, periodo e base legal.

### Fase 2 - Importador da planilha Natureza E-Social

Implementar servico para ler:

```text
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/natureza_esocial_por_rubrica_cte.xlsx
```

Regras:

- usar leitor XLSX ja compativel com o projeto: RubyZip + REXML, seguindo padroes de `BaseLegal::RecoveryCreditWorkbook` e `RubricRecovery::MarcosTab03Workbook`;
- nao adicionar gem externa de Excel sem necessidade;
- header real esta documentado no `REBUILD_002`;
- coluna `eSoc` e fonte primaria;
- `eSoc = 0` nao significa necessariamente que nao ha oportunidade; significa que aquela linha nao tem mapeamento direto;
- preservar numero da linha original para auditoria.

Saida esperada:

- catalogo CTE populado;
- mapeamentos esperados populados;
- rubricas sem `eSoc` marcadas para revisao/fallback.

### Fase 3 - Importador recursivo do S-1010

Implementar servico para ler:

```text
docs/04_referencias/pesquisa_original/reconstrucao_2026_06_02/s1010_todos_os_anos_cte_2026_06_02.zip
```

Regras:

- o ZIP raiz contem ZIPs mensais aninhados;
- abrir recursivamente;
- parsear XMLs locais, sem consultar eSocial;
- guardar caminho do ZIP interno e caminho do XML;
- calcular hash do XML;
- preservar recibo quando existir;
- preservar vigencia e retificacoes;
- nao assumir que codigo numerico CTE bate diretamente com `codRubr`, pois existem prefixos como `ENORMAL_5610`, `EFERIAS_5710`, `ERESCIS_4917`.

Saida esperada:

- eventos S-1010 carregados;
- linha do tempo por chave `ideTabRubr + codRubr`;
- marcacao de mudancas de natureza/incidencia ao longo do tempo.

### Fase 4 - Vinculo CTE x S-1010

Criar servico de matching deterministico.

Ordem recomendada:

1. match exato por codigo quando existir;
2. match por sufixo numerico do `codRubr` quando houver prefixo operacional;
3. match por descricao normalizada;
4. fila de revisao manual quando ambiguo.

Nunca force match silencioso quando houver varias possibilidades.

### Fase 5 - Motor de auditoria

Criar servico, por exemplo:

```text
RubricasCte::AuditEngine
```

Ele deve comparar:

```text
esperado pela planilha eSoc
x
declarado no S-1010 historico
x
incidencias CP/IRRF/FGTS
x
vigencia
x
base legal disponivel
```

Finding minimo:

```text
rubrica_cte
s1010_key
period_start
period_end
expected_nature
declared_nature
expected_cp
declared_cp
expected_irrf
declared_irrf
expected_fgts
declared_fgts
divergence_kind
confidence
legal_thesis_id
evidence_json
review_status
```

Exemplo de pergunta que a engine precisa responder:

```text
Para a rubrica 5610, qual natureza era esperada, qual natureza foi declarada no S-1010 em cada vigencia, quando mudou, e desde quando ha divergencia?
```

### Fase 6 - Interface v2

Nao comece por dashboard bonito. Comece por tela operacional.

Telas recomendadas:

1. Painel Rubricas CTE v2
   - total de rubricas;
   - com `eSoc`;
   - sem `eSoc`;
   - vinculadas ao S-1010;
   - divergentes;
   - com base legal.

2. Catalogo de Rubricas
   - codigo;
   - descricao;
   - natureza esperada;
   - status de match S-1010;
   - status de divergencia;
   - tese legal.

3. Detalhe da Rubrica
   - esperado x declarado;
   - timeline S-1010;
   - eventos XML;
   - mudancas de natureza/incidencia;
   - base legal vinculada;
   - status de revisao.

4. Divergencias
   - filtros por CP/IRRF/FGTS;
   - periodo;
   - confianca;
   - com/sem base legal;
   - exportacao futura para dossie.

5. Revisao Manual
   - casos ambiguos;
   - rubricas com `eSoc = 0`;
   - matches por descricao;
   - justificativa/historico.

### Fase 7 - Base Legal integrada

Usar `relatorio_recuperacao_credito.xlsx` como biblioteca juridica.

Nao transformar essa fonte em catalogo principal. Ela serve para fundamentar achados, separar tese por INSS/FGTS/IRRF e alimentar dossie.

### Fase 8 - QA contra arquivo_enquadrado

Depois da v2 importar e auditar, comparar resultados contra `arquivo_enquadrado`.

O objetivo nao e copiar o resultado antigo. O objetivo e responder:

- a v2 explica os 224 registros/eventos divergentes de alta/media confianca?
- quais divergencias antigas eram falso positivo?
- quais divergencias novas aparecem porque agora existe S-1010 historico?
- onde o score antigo ajuda como fallback?

## O que nao fazer

- Nao consultar eSocial sem permissao explicita do usuario.
- Nao rodar scripts de Download Cirurgico.
- Nao usar `explorador_eventos` como fonte de recibo.
- Nao apagar dados/telas antigas agora.
- Nao trocar a fonte primaria de volta para score.
- Nao calcular credito financeiro sem folha e recolhimentos.
- Nao adicionar dependencia frontend; o projeto usa Rails/ERB/Hotwire/Stimulus/Importmap/Tailwind Rails.
- Nao adicionar gem Excel sem avaliar primeiro os parsers existentes.

## Criterios de pronto para a primeira entrega

A primeira entrega tecnica boa deve provar:

- importou a planilha Natureza E-Social local;
- importou o ZIP S-1010 local de forma recursiva;
- criou catalogo CTE;
- criou timeline S-1010;
- vinculou parte relevante das rubricas CTE ao S-1010;
- gerou findings simples esperado x declarado;
- mostrou isso em uma tela Rails v2;
- tem testes de servico/importacao;
- nao alterou logica antiga de calculo, eSocial ou score sem necessidade.

## Validacao minima esperada

Rodar testes focados primeiro:

```text
ruby bin/rails test test/services
ruby bin/rails test test/controllers
```

Se a mudanca for ampla e a suite estiver estavel:

```text
ruby bin/rails test
```

Tambem validar:

- importador nao consulta rede;
- contagens batem com os documentos REBUILD;
- hashes das fontes locais batem com `INDICE_FONTES.md`;
- tela nao mistura v2 com modelo antigo sem indicar claramente.

## Resumo executivo para avaliar o plano

O plano esta correto se o novo modulo responder, com evidencia local:

```text
Qual rubrica CTE existe?
Qual natureza eSocial ela deveria ter pela fonte CTE?
O que foi declarado no S-1010 ao longo do tempo?
Desde quando esta divergente?
Qual incidencia CP/IRRF/FGTS foi afetada?
Existe tese/base legal para sustentar?
O caso precisa revisao humana ou ja e deterministico?
```

Se a implementacao estiver indo nessa direcao, continue. Se ela voltar a depender do score como decisor principal, pare e recoloque a arquitetura na fonte primaria `eSoc` + S-1010 historico.