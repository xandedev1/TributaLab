# MD 003 - Para Agente de Implementacao Rails

Data: 2026-05-29
Projeto: TributaLab
Origem: arquiteto do sistema
Destino: agente de implementacao Rails
Formato esperado de resposta: um unico arquivo Markdown de volta

## Estado atual apos a Etapa 002

A Etapa 002 foi aceita como concluida.

O TributaLab agora possui:

- Rails 8.1.3 com PostgreSQL;
- dashboard operacional;
- modelagem inicial;
- `TaxRuleVersion`;
- calculators para 4 operacoes;
- `Simulation` e `SimulationResult` persistidos;
- snapshots auditaveis;
- UI minima para executar simulacoes;
- testes passando.

Estado real do produto:

```text
Pronto para validacao interna controlada.
Ainda nao pronto para uso real com empresas/clientes.
```

Nao cadastrar empresas reais ainda. O sistema ja calcula quatro operacoes, mas ainda faltam fluxo operacional, revisao de resultados, gestao basica de casos, calculos restantes e confirmacoes de regra.

## Objetivo deste MD

Transformar a Etapa 003 em uma entrega operacional.

A Etapa 003 deve deixar o TributaLab mais usavel para validacao interna do negocio, sem tentar virar produto final.

Ao concluir, crie obrigatoriamente:

```text
docs/03_comunicacao/ETAPA_003_RESPOSTA.md
```

Nao responda apenas em chat.

## Leitura obrigatoria antes de implementar

Antes de alterar codigo, leia:

1. `docs/03_comunicacao/ETAPA_001_RESPOSTA.md`
2. `docs/03_comunicacao/ETAPA_002_RESPOSTA.md`
3. `docs/02_decisoes/DECISAO_001_setup_inicial.md`
4. `docs/02_decisoes/DECISAO_002_versionamento_regras_simulacoes.md`
5. `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`
6. `docs/04_referencias/INDICE_FONTES.md`
7. `docs/00_brief/README_INICIAL_TRIBUTALAB.md`
8. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md`

Se algum arquivo estiver ausente, registre isso em `ETAPA_003_RESPOSTA.md`.

## Avaliacao arquitetural da Etapa 002

A implementacao da Etapa 002 seguiu a direcao correta.

Pontos aprovados:

- manter `TaxModule`;
- criar `TaxRuleVersion` leve;
- usar calculators por operacao;
- manter `Simulation` e `SimulationResult` separados;
- salvar snapshots para auditoria;
- usar `BigDecimal` nos calculos;
- serializar decimais como string em JSON;
- persistir alertas e assumptions;
- manter locacao com alerta de divergencia;
- nao implementar motor generico cedo demais.

A Etapa 003 deve preservar essas decisoes.

## Objetivo da Etapa 003

Criar uma camada operacional minima para validacao interna do TributaLab.

Apos a Etapa 003, o sistema deve permitir:

- executar simulacoes com UI mais clara;
- listar simulacoes salvas;
- revisar resultados anteriores;
- simular as operacoes restantes do primeiro modulo;
- consultar parametros e assumptions;
- agrupar simulacoes em um caso interno simples, sem transformar isso em cadastro comercial completo.

## Escopo obrigatorio da Etapa 003

### 1. Melhorar UI de simulacao

A tela atual `/simulations/new` deve evoluir para uma UI mais operacional.

Requisitos:

- selecionar operacao;
- exibir apenas campos relevantes para a operacao selecionada;
- mostrar parametros que serao usados antes de calcular;
- mostrar alertas conhecidos da operacao;
- explicar visualmente quando uma regra esta pendente ou divergente;
- manter layout simples, B2B e funcional.

Pode usar Stimulus para campos condicionais.

Nao criar landing page. Nao criar marketing. A tela deve ser ferramenta de trabalho.

### 2. Criar listagem de simulacoes

Criar uma tela:

```text
/simulations
```

Deve mostrar:

- data da simulacao;
- operacao;
- modulo;
- versao de regra;
- valor principal da operacao;
- imposto estimado;
- quantidade de alertas;
- link para detalhe.

Filtros simples desejaveis:

- operacao;
- modulo;
- data;
- status/alertas, se simples.

Se filtros forem custosos, criar apenas listagem e registrar filtro como pendencia.

### 3. Melhorar tela de resultado

A tela `/simulations/:id` deve exibir resultado de forma mais revisavel.

Separar em secoes:

- resumo;
- inputs;
- parametros usados;
- calculo passo a passo;
- assumptions;
- alertas;
- versao de regra;
- base legal, quando existir;
- snapshot tecnico, se util.

O resultado deve ser compreensivel para validacao com o dono do projeto e com Denis.

### 4. Implementar calculators restantes do modulo inicial

Adicionar calculators para:

1. Construcao civil.
2. Administracao / corretagem.
3. Cessao de direitos.
4. Permuta sem torna como operacao informativa.

Nomes sugeridos:

```text
TaxRules::RealEstate::ConstructionContractCalculator
TaxRules::RealEstate::BrokerageAdministrationCalculator
TaxRules::RealEstate::AssignmentRightsCalculator
TaxRules::RealEstate::ExchangeWithoutBootCalculator
```

Manter contrato padrao de retorno usado na Etapa 002.

### 5. Formulas iniciais dos novos calculators

#### Construcao civil

```text
base_calculo = valor_contrato
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

Alerta:

```text
Confirmar se construcao civil usa aliquota cheia com creditos, sem reducao especifica.
```

#### Administracao / corretagem

```text
base_calculo = valor_servico
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

Alerta:

```text
Confirmar se administracao/corretagem usa aliquota cheia sem redutor ou reducao.
```

#### Cessao de direitos

Formula pendente de validacao:

```text
base_calculo = valor_cessao
aliquota_aplicavel = aliquota_cheia ou aliquota_cheia * (1 - reducao_cessao)
debito = base_calculo * aliquota_aplicavel
imposto_liquido = max(0, debito - creditos)
```

Na Etapa 003, manter o comportamento ja parametrizado na Etapa 002: reducao de cessao de direitos cadastrada como 70%, mas marcada como divergente.

A simulacao deve exibir alerta obrigatorio:

```text
A planilha indica reducao de 70% para locacao/cessao/arrendamento, mas a aba de calculo de cessao usa aliquota cheia. Validar com Denis.
```

#### Permuta sem torna

```text
base_calculo = 0
imposto_estimado = 0
```

Alerta:

```text
Operacao tratada como sem incidencia no modelo inicial. Confirmar se deve existir apenas como informativa ou se precisa de simulador proprio.
```

### 6. Criar caso interno simples

Criar uma entidade simples para agrupar simulacoes.

Nome recomendado:

```text
CaseFile
```

Nao criar multi-tenant completo agora.
Nao criar cadastro comercial completo de cliente agora.
Nao colocar dados sensiveis obrigatorios.

Campos sugeridos:

- `name`
- `description`
- `status`
- `reference_code`
- `notes`

Relacionamento:

```text
CaseFile has_many Simulations
Simulation belongs_to CaseFile optional
```

Objetivo: permitir organizar simulacoes por estudo/caso interno sem afirmar que o sistema ja esta pronto para clientes reais.

Seed opcional:

```text
Caso interno de validacao - Reforma Tributaria Imobiliaria
```

### 7. Tela de parametros e assumptions para consulta

Criar telas somente de consulta, ou consulta com edicao controlada se for simples.

Minimo aceito:

```text
/tax_parameters
/assumptions
```

Devem mostrar:

- codigo;
- nome;
- valor/status;
- modulo/operacao;
- vigencia;
- observacoes;
- status de validacao.

Se for implementar edicao, tomar cuidado para nao quebrar auditoria. Simulacoes antigas devem preservar snapshots.

### 8. Testes

Criar ou atualizar testes para:

- novos calculators;
- listagem de simulacoes;
- detalhe de simulacao;
- criacao de `CaseFile`, se implementado;
- associacao opcional entre `Simulation` e `CaseFile`;
- consulta de parametros e assumptions;
- snapshots preservados apos simulacao;
- alertas obrigatorios das regras pendentes.

Manter Minitest.

## Fora de escopo da Etapa 003

Nao implementar agora:

- login;
- multi-tenant;
- cadastro completo de empresas/clientes;
- upload de documentos;
- importacao automatica da planilha;
- relatorios PDF finais;
- recuperacao de credito;
- NCM detalhado;
- motor generico universal;
- regras definitivas para pontos ainda pendentes;
- integracao externa.

## Criterios de aceite

A Etapa 003 so termina quando:

- UI de simulacao tiver campos condicionais ou fluxo equivalente por operacao;
- `/simulations` listar simulacoes salvas;
- `/simulations/:id` mostrar resultado revisavel;
- calculators de construcao civil, administracao/corretagem, cessao de direitos e permuta sem torna existirem;
- novos calculators tiverem testes;
- alertas pendentes aparecerem nos resultados e snapshots;
- `CaseFile` ou equivalente simples existir, salvo se houver justificativa clara para adiar;
- simulacoes puderem ser associadas opcionalmente a um caso interno;
- parametros e assumptions tiverem tela de consulta;
- testes passarem;
- `docs/03_comunicacao/ETAPA_003_RESPOSTA.md` existir;
- resposta da etapa documentar como rodar, o que mudou e o que ainda falta.

## Estado esperado apos Etapa 003

Depois da Etapa 003, o TributaLab deve estar pronto para:

```text
validacao interna guiada com casos de teste e simulacoes revisaveis.
```

Ainda nao considerar pronto para:

```text
uso comercial com empresas reais, clientes externos ou decisoes tributarias finais.
```

Para uso com empresas reais, ainda sera necessario definir pelo menos:

- cadastro de cliente/empresa;
- usuarios e permissoes;
- controle de acesso;
- governanca de parametros;
- validacao juridica das regras pendentes;
- relatorios exportaveis;
- termos de uso/disclaimer;
- trilha de auditoria mais formal.

## Perguntas que continuam abertas

Manter estas perguntas em `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`:

1. A base legal correta e LC 227/2026, LC 214/2025 ou outro texto consolidado?
2. Os artigos 252, 254, 255, 259, 260 e 261 estao corretos?
3. Na locacao, IPTU e condominio saem da base ou nao?
4. Cessao de direitos aplica reducao de 70% ou aliquota cheia?
5. Construcao civil tem alguma reducao especifica ou apenas credito?
6. Administracao/corretagem usa aliquota cheia sem redutor?
7. Credito maior que debito vira saldo ou apenas zera imposto da simulacao?
8. Permuta sem torna precisa de tela propria ou apenas aviso informativo?
9. O usuario final sera interno, consultor tributario ou cliente externo?
10. A primeira versao precisa salvar clientes/casos ou pode simular sem cadastro de cliente?

Adicionar, se ainda nao existir:

11. Quais campos minimos podem identificar um caso interno sem expor dados sensiveis de empresa real?
12. Qual formato Denis precisa para validar os resultados: tela, tabela, CSV, PDF ou Markdown?

## Decisao tecnica esperada

Criar, se a Etapa 003 implementar `CaseFile`:

```text
docs/02_decisoes/DECISAO_003_casos_internos_simulacoes.md
```

Esse documento deve explicar:

- por que foi criado `CaseFile`;
- por que ele nao e ainda cadastro completo de cliente;
- como ele se relaciona com `Simulation`;
- quais limites existem para uso com empresas reais.

Se `CaseFile` for adiado, registrar o motivo em `ETAPA_003_RESPOSTA.md`.

## Proxima resposta esperada

Ao concluir, responda criando:

```text
docs/03_comunicacao/ETAPA_003_RESPOSTA.md
```

Use este formato:

```md
# ETAPA 003 - Resposta

## Resumo do que foi feito

## Estado atual do produto

## Arquivos criados ou alterados

## Migrations e modelos

## Services de calculo

## Fluxo de simulacao

## Casos internos

## Parametros e assumptions

## Como rodar

## Testes executados

## Resultado dos testes

## Decisoes tomadas

## Pendencias

## Perguntas para o dono do projeto ou Denis

## Proxima etapa sugerida
```

## Observacao final do arquiteto

A Etapa 002 provou que o TributaLab calcula e audita quatro operacoes.

A Etapa 003 deve provar que o TributaLab consegue ser usado como ferramenta interna de validacao: listar, revisar, comparar e organizar simulacoes, ainda sem promessa de uso real por empresas.