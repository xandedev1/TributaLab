# MD 001 - Para Arquiteto do Sistema

Data: 2026-05-28
Projeto: TributaLab
Origem: agente de implementacao Rails
Destino: arquiteto do sistema
Formato esperado de resposta: um unico arquivo Markdown de volta

## Objetivo deste MD

Este documento consolida o conteudo dos quatro documentos principais criados na Etapa 001:

1. `docs/03_comunicacao/ETAPA_001_RESPOSTA.md`
2. `docs/04_referencias/INDICE_FONTES.md`
3. `docs/02_decisoes/DECISAO_001_setup_inicial.md`
4. `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`

A ideia e permitir a conversa um-para-um por Markdown: este MD vai para o arquiteto, e o arquiteto responde com outro MD contendo revisao, decisoes, ajustes ou perguntas.

## Pedido ao arquiteto

Por favor, revise a arquitetura inicial do TributaLab apos a Etapa 001 e responda em um unico Markdown com:

1. Validacao ou critica da modelagem atual.
2. Ajustes recomendados antes da Etapa 002.
3. Confirmacao se a separacao `ProductArea -> Sector -> TaxModule -> Operation` esta adequada.
4. Confirmacao se `TaxModule` e o melhor nome tecnico para evitar conflito com `Module` do Ruby.
5. Recomendacao sobre como versionar regras tributarias e parametros usados em simulacoes.
6. Recomendacao sobre persistencia de `Simulation` e `SimulationResult` para auditoria futura.
7. Recomendacao sobre como tratar `Assumption`, `TaxParameter`, `LegalBasis` e alertas de validacao.
8. Definicao sugerida para a Etapa 002.
9. Riscos arquiteturais que voce enxerga agora.
10. Perguntas que precisam voltar para o dono do projeto ou para Denis.

## Contexto do produto

O produto se chama TributaLab.

TributaLab e uma plataforma de inteligencia tributaria operacional para transformar regras fiscais, teses, parametros legais e cenarios de negocio em simulacoes, oportunidades, relatorios e decisoes praticas.

Stack obrigatoria:

- Ruby on Rails
- PostgreSQL
- Rails full-stack com Hotwire/Turbo/Stimulus
- Tailwind no setup inicial
- Testes automatizados desde o inicio

O primeiro modulo real e:

```text
Reforma Tributaria > Imobiliario / Construcao Civil
```

Este modulo nasce pequeno, mas a arquitetura precisa comportar crescimento para outros recortes e para o eixo futuro de Recuperacao de Credito.

## Arquitetura conceitual esperada

A arquitetura conceitual tem duas camadas principais.

### Camada 1: tipo de trabalho tributario

1. Recuperacao de credito
   - Olha para o passado.
   - Trabalha com verbas, rubricas, periodos, documentos, jurisprudencia, risco e potencial de recuperacao.

2. Reforma tributaria
   - Olha para o futuro.
   - Simula impacto de IBS/CBS e novas regras.
   - Trabalha com operacoes, aliquotas, redutores, creditos, regimes, cenarios e comparativos.

### Camada 2: recorte ou setor

O primeiro recorte e:

```text
Imobiliario / Construcao Civil
```

Importante: imobiliario nao e o produto inteiro. E apenas o primeiro recorte dentro do produto.

## O que foi implementado na Etapa 001

Foi criado um app Rails 8.1.3 com PostgreSQL e Tailwind.

A modelagem inicial cobre:

- `ProductArea`
- `Sector`
- `TaxModule`
- `Operation`
- `TaxParameter`
- `Assumption`
- `LegalBasis`
- `CreditCategory`
- `Simulation`
- `SimulationResult`

O modulo inicial foi carregado por seeds:

- Areas: 2
- Setores: 1
- Modulos: 1
- Operacoes: 8
- Parametros: 8
- Assumptions: 9
- Categorias de credito: 7
- Bases legais: 5

## Operacoes iniciais cadastradas

1. Venda de imovel / incorporacao
2. Venda de lote residencial
3. Locacao de imoveis
4. Construcao civil
5. Administracao / corretagem
6. Cessao de direitos
7. Permuta sem torna
8. Permuta com torna

## Parametros iniciais cadastrados

1. Aliquota cheia IBS/CBS: 26,5%
2. Redutor venda imovel residencial: R$ 100.000
3. Redutor venda lote residencial: R$ 30.000
4. Redutor locacao residencial: R$ 600
5. Reducao venda/incorporacao: 50%
6. Reducao venda de lote residencial: 50%
7. Reducao locacao: 70%
8. Reducao cessao de direitos: 70%, marcada como divergente

Todos os parametros foram modelados como registros editaveis em banco, nao como regra fixa espalhada no codigo.

## Assumptions cadastradas

Foram cadastradas 9 pendencias de regra como `Assumption`:

1. Confirmar LC 227/2026 vs LC 214/2025.
2. Confirmar deducao de IPTU e condominio na locacao.
3. Confirmar aliquota de cessao de direitos.
4. Confirmar construcao civil com aliquota cheia.
5. Confirmar administracao/corretagem sem redutor.
6. Confirmar condicoes documentais para creditos.
7. Confirmar se base negativa apos redutor vira zero.
8. Confirmar tratamento de credito maior que debito.
9. Confirmar tela de permuta sem torna.

Essas regras nao foram tratadas como definitivas.

## Decisoes tecnicas tomadas

1. Usar Rails 8.1.3, Ruby 3.3.11, PostgreSQL, Hotwire e Tailwind.
2. Manter Minitest na Etapa 001 para evitar dependencia extra.
3. Usar `TaxModule` em vez de `Module`, porque `Module` e constante nativa do Ruby.
4. Criar `Assumption` desde o inicio para registrar divergencias e impedir regra definitiva sem validacao humana.
5. Criar `LegalBasis` e `CreditCategory` desde o inicio, porque a pesquisa ja aponta necessidade de base legal, status e creditos.
6. Usar `decimal` para dinheiro, aliquotas e percentuais.
7. Configurar PostgreSQL com suporte a `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER` e `POSTGRES_PASSWORD`.
8. Usar Docker apenas como forma de validacao local, porque o PostgreSQL local em `localhost:5432` exigia senha nao disponivel no ambiente.

## Arquivos principais criados ou alterados

- `README.md`: setup local e exemplo com PostgreSQL em Docker.
- `config/database.yml`: configuracao PostgreSQL com variaveis de ambiente.
- `config/routes.rb`: rota raiz para dashboard.
- `app/controllers/dashboard_controller.rb`: controller inicial.
- `app/views/dashboard/index.html.erb`: tela inicial operacional.
- `app/services/tax_rules/validation_alerts.rb`: service para consolidar alertas pendentes.
- `app/models/*.rb`: associacoes, validacoes e escopos iniciais.
- `db/migrate/*.rb`: migrations com `decimal` e relacionamentos.
- `db/seeds.rb`: seeds idempotentes do modulo inicial.
- `test/models/*.rb`: testes basicos de models.
- `test/services/tax_rules/validation_alerts_test.rb`: teste do service de alertas.
- `docs/00_brief/README_INICIAL_TRIBUTALAB.md`: briefing inicial preservado.
- `docs/02_decisoes/DECISAO_001_setup_inicial.md`: decisoes da etapa.
- `docs/03_comunicacao/ETAPA_001_PEDIDO.md`: pedido formal da etapa.
- `docs/03_comunicacao/ETAPA_001_RESPOSTA.md`: resposta formal da etapa.
- `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`: perguntas de negocio pendentes.
- `docs/04_referencias/INDICE_FONTES.md`: indice das fontes.
- `docs/04_referencias/pesquisa_original/`: copia do pacote original de pesquisa.

## Fontes de pesquisa

O pacote de pesquisa estava acessivel em:

```text
c:/Users/xandao/Documents/GitHub/xAI/comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/
```

Foi copiado para:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/
```

Total copiado: 22 arquivos.

Fontes consultadas e copiadas:

- `00_CONTEXTO_PROJETO/call_denis_transcricao_2026-05-28.md`
- `00_CONTEXTO_PROJETO/arquitetura_inicial_sistema.md`
- `00_CONTEXTO_PROJETO/leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md`
- `00_CONTEXTO_PROJETO/TRIBUTALAB_README_INICIAL_RAILS.md`
- `00_CONTEXTO_PROJETO/tabela_reforma_tributaria_segmento_imobiliario_lc227_2026.xlsx`
- `01_VERBAS_RUBRICAS_COM_POSSIVEL_RECUPERACAO/`
- `02_MARCO_LEGAL_E_PERIODO_DE_CADA_VERBA/`

Nenhuma fonte esperada ficou inacessivel apos localizar o pacote no repositorio `xAI`.

## Validacao executada

Ambiente usado para validacao:

- Ruby 3.3.11
- Rails 8.1.3
- PostgreSQL Docker `postgres:16` em `localhost:55432`

Comandos/resultados:

1. Sintaxe Ruby em arquivos de `app`, `config`, `db` e `test`: passou.
2. `ruby bin/rails runner "puts Rails.application.class.module_parent_name"`: passou, retornando `TributaLab`.
3. `ruby bin/rails db:create db:migrate db:seed` com PostgreSQL Docker: passou.
4. Conferencia dos seeds: `areas=2`, `sectors=1`, `modules=1`, `operations=8`, `parameters=8`, `assumptions=9`, `credit_categories=7`, `legal_bases=5`.
5. `ruby bin/rails db:test:prepare; ruby bin/rails test`: passou com `8 runs, 25 assertions, 0 failures, 0 errors, 0 skips`.
6. `ruby bin/rails server -p 3000`: subiu sem erro.
7. `Invoke-WebRequest http://127.0.0.1:3000`: retornou `Status=200` e confirmou textos `TributaLab` e `Reforma Tributaria Imobiliaria`.
8. `ruby bin/rails db:seed` executado novamente: manteve `operations=8`, `parameters=8`, `assumptions=9`, confirmando idempotencia basica.

Observacao: o PostgreSQL local padrao em `localhost:5432` exigia senha e por isso a validacao usou Docker na porta `55432`.

## Tela inicial atual

A tela inicial em `/` mostra:

- Nome do produto: TributaLab.
- Area atual: Reforma Tributaria.
- Setor/modulo: Imobiliario / Construcao Civil.
- Lista das operacoes iniciais.
- Parametros atuais.
- Categorias de credito.
- Alertas de regras pendentes.
- Botao de nova simulacao desabilitado enquanto os services completos nao existem.

A tela nao e uma landing page de marketing; e uma tela operacional inicial.

## Pendencias de negocio

1. Confirmar se a base legal correta e LC 227/2026, LC 214/2025 ou outra consolidacao, pois a planilha mistura referencias.
2. Confirmar os artigos 252, 254, 255, 259, 260 e 261 usados na planilha.
3. Confirmar se a locacao deve excluir IPTU e condominio da base ou seguir o exemplo que usa o aluguel integral.
4. Confirmar se cessao de direitos aplica reducao de 70% ou aliquota cheia.
5. Confirmar se construcao civil usa aliquota cheia com creditos, sem reducao especifica.
6. Confirmar se administracao/corretagem usa aliquota cheia sem redutor ou reducao.
7. Confirmar condicoes documentais para aproveitamento de creditos.
8. Confirmar se a base negativa apos redutor deve virar zero.
9. Confirmar tratamento quando os creditos forem maiores que o debito.
10. Confirmar se permuta sem torna sera apenas informativa ou tera tela propria.

## Proxima etapa sugerida pelo agente de implementacao

Etapa 002: implementar services de calculo e testes para:

1. Venda de imovel / incorporacao.
2. Venda de lote residencial.
3. Locacao de imoveis, mantendo alerta de divergencia.
4. Permuta com torna.

Tambem sugeri criar formularios simples para registrar `Simulation` e `SimulationResult`, salvando:

- inputs;
- outputs;
- parametros usados;
- versao das regras;
- assumptions aplicadas;
- alertas de validacao.

## Pontos especificos para revisao arquitetural

### 1. Modelagem de camadas

A modelagem atual e:

```text
ProductArea -> Sector -> TaxModule -> Operation
```

Exemplo:

```text
ProductArea: tax_reform
Sector: real_estate_construction
TaxModule: real_estate_tax_reform
Operation: sale_property, lease_property, etc.
```

Pergunta: essa hierarquia esta correta para crescer com outros setores e tipos de trabalho, ou precisamos separar melhor `Sector`, `WorkType`, `Module`, `Submodule` ou outro conceito?

### 2. Nome `TaxModule`

Usei `TaxModule` porque `Module` conflita com Ruby.

Pergunta: voce manteria `TaxModule`, ou prefere outro nome de dominio como `ProductModule`, `AnalysisModule`, `WorkModule` ou `TaxWorkflow`?

### 3. Parametros e versionamento

Hoje `TaxParameter` guarda:

- codigo;
- nome;
- tipo;
- valor decimal;
- unidade;
- status de validacao;
- vigencia;
- referencia legal;
- modulo;
- operacao opcional.

Pergunta: para auditoria, devemos criar uma tabela de versoes de parametro ou basta snapshot JSON em `Simulation.parameters_snapshot` na primeira fase?

### 4. Regras de calculo

A Etapa 002 deve criar services em `app/services/tax_rules/` ou `app/services/simulations/`.

Pergunta: voce recomenda uma arquitetura por operacao, por estrategia de calculo, ou um motor generico parametrizado?

Sugestao inicial simples:

```text
TaxRules::RealEstate::SalePropertyCalculator
TaxRules::RealEstate::SaleResidentialLotCalculator
TaxRules::RealEstate::LeasePropertyCalculator
TaxRules::RealEstate::ExchangeWithBootCalculator
```

Mas preciso da sua avaliacao antes de crescer.

### 5. Assumptions

Hoje `Assumption` guarda divergencias e pontos pendentes.

Pergunta: `Assumption` deve ser somente registro de negocio/documentacao, ou deve participar diretamente do calculo com flags configuraveis?

Exemplo: locacao deduz IPTU/condominio ou nao.

### 6. Simulation e SimulationResult

Hoje existem tabelas para `Simulation` e `SimulationResult`, ainda sem fluxo de UI completo.

Pergunta: voce recomenda manter `SimulationResult` separado ou consolidar outputs estruturados em JSON dentro de `Simulation` ate a regra estabilizar?

Minha inclinacao atual: manter separado porque o briefing pede outputs minimos estruturados e auditoria.

### 7. LegalBasis

Hoje `LegalBasis` existe, mas ainda nao esta ligada diretamente a `TaxParameter`, `Operation` ou `Assumption` por FK.

Pergunta: ja devemos criar tabelas de relacionamento ou manter referencia textual nesta primeira fase?

### 8. CreditCategory

Hoje `CreditCategory` e catalogo simples por modulo.

Pergunta: na arquitetura futura, creditos devem virar itens parametrizaveis por operacao, com NCM/servico, condicoes documentais e regra de elegibilidade?

### 9. Recuperacao de credito futura

A estrutura atual cria `ProductArea` para Recuperacao de Credito, mas nao implementa fluxo.

Pergunta: ha algo que devemos ajustar agora para acomodar rubricas, verbas, periodos, risco, jurisprudencia e bases legais sem refatoracao grande depois?

### 10. Resposta esperada

Por favor, responda em um unico Markdown com este formato sugerido:

```md
# MD 001 - Resposta do Arquiteto

## Avaliacao geral

## Pontos aprovados

## Ajustes recomendados antes da Etapa 002

## Decisoes arquiteturais propostas

## Riscos

## Perguntas para o dono do projeto ou Denis

## Escopo recomendado da Etapa 002

## Observacoes finais
```

Se alguma decisao for critica, indicar se ela deve virar `docs/02_decisoes/DECISAO_002_*.md`.
