# ETAPA 003 - Resposta

## Resumo do que foi feito

A Etapa 003 transformou o TributaLab em uma ferramenta mais operacional para validacao interna do modulo Reforma Tributaria Imobiliaria.

Foram implementados:

1. UI de simulacao com campos condicionais por operacao.
2. Listagem de simulacoes salvas em `/simulations`.
3. Tela de resultado mais revisavel em `/simulations/:id`.
4. Calculators para as quatro operacoes restantes do modulo inicial.
5. `CaseFile` para agrupar simulacoes em casos internos simples.
6. Telas de consulta de parametros e assumptions.
7. Testes para calculators, controllers, casos internos, snapshots e alertas.

O sistema continua limitado a validacao interna. Ainda nao deve ser usado com empresas reais, clientes externos ou decisoes tributarias finais.

## Estado atual do produto

```text
Pronto para validacao interna guiada com casos de teste e simulacoes revisaveis.
Ainda nao pronto para uso comercial com empresas reais.
```

O TributaLab agora calcula as oito operacoes iniciais do modulo imobiliario:

1. Venda de imovel / incorporacao.
2. Venda de lote residencial.
3. Locacao de imoveis.
4. Construcao civil.
5. Administracao / corretagem.
6. Cessao de direitos.
7. Permuta sem torna.
8. Permuta com torna.

As regras pendentes continuam aparecendo como alertas e assumptions, inclusive nos snapshots das simulacoes.

## Arquivos criados ou alterados

- `README.md`: setup local com PostgreSQL local e escopo atualizado da Etapa 003.
- `config/database.yml`: defaults locais para `127.0.0.1`, usuario `postgres` e senha `123321`, ainda com override por variaveis de ambiente.
- `config/routes.rb`: rotas de casos internos, simulacoes, parametros e assumptions.
- `db/migrate/20260529100000_create_case_files_and_link_simulations.rb`: cria `case_files` e associa simulacoes opcionalmente.
- `db/schema.rb`: schema atualizado da Etapa 003.
- `db/seeds.rb`: seed idempotente de caso interno de validacao.
- `app/models/case_file.rb`: model de caso interno.
- `app/models/simulation.rb`: associacao opcional com `CaseFile` e helpers de listagem.
- `app/services/tax_rules/real_estate/construction_contract_calculator.rb`: calculator de construcao civil.
- `app/services/tax_rules/real_estate/brokerage_administration_calculator.rb`: calculator de administracao/corretagem.
- `app/services/tax_rules/real_estate/assignment_rights_calculator.rb`: calculator de cessao de direitos.
- `app/services/tax_rules/real_estate/exchange_without_boot_calculator.rb`: calculator informativo de permuta sem torna.
- `app/services/simulations/run_simulation.rb`: mapeamento das oito operacoes e associacao opcional com caso interno.
- `app/controllers/simulations_controller.rb`: listagem, filtros simples, nova simulacao e detalhe.
- `app/controllers/case_files_controller.rb`: listagem, criacao e detalhe de casos internos.
- `app/controllers/tax_parameters_controller.rb`: consulta de parametros.
- `app/controllers/assumptions_controller.rb`: consulta de assumptions.
- `app/views/simulations/index.html.erb`: listagem operacional de simulacoes.
- `app/views/simulations/new.html.erb`: UI com campos condicionais, parametros e alertas por operacao.
- `app/views/simulations/show.html.erb`: resultado revisavel com secoes de resumo, calculo, alertas, assumptions e snapshots.
- `app/views/case_files/*.html.erb`: telas de casos internos.
- `app/views/tax_parameters/index.html.erb`: consulta de parametros.
- `app/views/assumptions/index.html.erb`: consulta de assumptions.
- `app/views/dashboard/index.html.erb`: links operacionais e resumo de casos/simulacoes.
- `app/controllers/dashboard_controller.rb`: dados de casos e contagem de simulacoes.
- `app/helpers/application_helper.rb`: classes visuais para badges de status.
- `app/javascript/controllers/simulation_form_controller.js`: comportamento Stimulus para campos condicionais.
- `test/fixtures/*.yml`: fixtures expandidas para Etapa 003.
- `test/models/case_file_test.rb`: testes de caso interno.
- `test/models/simulation_test.rb`: testes de associacao opcional e helpers de listagem.
- `test/services/tax_rules/real_estate/calculators_test.rb`: testes dos oito calculators.
- `test/services/simulations/run_simulation_test.rb`: testes de snapshots e associacao com caso.
- `test/controllers/simulations_controller_test.rb`: testes de formulario, listagem, detalhe e criacao.
- `test/controllers/case_files_controller_test.rb`: testes de casos internos.
- `test/controllers/tax_parameters_controller_test.rb`: teste da consulta de parametros.
- `test/controllers/assumptions_controller_test.rb`: teste da consulta de assumptions.
- `docs/03_comunicacao/MD_003_PARA_AGENTE_IMPLEMENTACAO_RAILS.md`: MD recebido do arquiteto preservado.
- `docs/02_decisoes/DECISAO_003_casos_internos_simulacoes.md`: decisao tecnica sobre casos internos.
- `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`: adicionadas perguntas sobre campos minimos de caso e formato de validacao com Denis.

## Migrations e modelos

Foi criado `CaseFile` com:

- `name`
- `description`
- `status`
- `reference_code`
- `notes`

Relacionamentos:

```text
CaseFile has_many Simulations
Simulation belongs_to CaseFile optional
```

`Simulation` ganhou helpers para listagem:

- `primary_amount`
- `alert_count`

`CaseFile` nao e cadastro de cliente. Ele serve apenas para agrupar estudos internos sem dados sensiveis obrigatorios.

## Services de calculo

Foram mantidos os calculators da Etapa 002:

- `TaxRules::RealEstate::SalePropertyCalculator`
- `TaxRules::RealEstate::SaleResidentialLotCalculator`
- `TaxRules::RealEstate::LeasePropertyCalculator`
- `TaxRules::RealEstate::ExchangeWithBootCalculator`

Foram adicionados os calculators da Etapa 003:

- `TaxRules::RealEstate::ConstructionContractCalculator`
- `TaxRules::RealEstate::BrokerageAdministrationCalculator`
- `TaxRules::RealEstate::AssignmentRightsCalculator`
- `TaxRules::RealEstate::ExchangeWithoutBootCalculator`

Construcao civil:

```text
base_calculo = valor_contrato
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

Administracao / corretagem:

```text
base_calculo = valor_servico
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

Cessao de direitos:

```text
base_calculo = valor_cessao
aliquota_aplicavel = aliquota_cheia * (1 - reducao_cessao)
debito = base_calculo * aliquota_aplicavel
imposto_liquido = max(0, debito - creditos)
```

A reducao de cessao de direitos permanece parametrizada como 70% e marcada como divergente. O resultado grava alerta obrigatorio informando que a aba de calculo da planilha usa aliquota cheia.

Permuta sem torna:

```text
base_calculo = 0
imposto_estimado = 0
```

Essa operacao foi tratada como informativa no modelo inicial e mantem alerta pendente.

## Fluxo de simulacao

URLs principais:

```text
/simulations/new
/simulations
/simulations/:id
```

Em `/simulations/new`, a tela permite:

- escolher caso interno opcional;
- escolher operacao;
- preencher apenas os campos relevantes da operacao selecionada;
- consultar parametros usados antes do calculo;
- consultar alertas conhecidos da operacao antes do calculo.

Em `/simulations`, a tela mostra:

- data;
- operacao;
- modulo;
- versao de regra;
- valor principal;
- imposto estimado;
- quantidade de alertas;
- link para detalhe.

Filtros implementados:

- operacao;
- data inicial;
- data final;
- com ou sem alertas.

Em `/simulations/:id`, o resultado foi separado em:

- resumo;
- calculo passo a passo;
- assumptions;
- alertas;
- inputs;
- parametros usados;
- versao de regra;
- base legal;
- snapshot tecnico.

## Casos internos

URLs principais:

```text
/case_files
/case_files/new
/case_files/:id
```

Foi criado um seed:

```text
Caso interno de validacao - Reforma Tributaria Imobiliaria
```

Esse caso serve para validacao guiada e organizacao de simulacoes internas, sem cadastrar empresa real.

## Parametros e assumptions

Foram criadas telas somente de consulta:

```text
/tax_parameters
/assumptions
```

As telas exibem codigo, nome/titulo, valor/status, modulo/operacao, vigencia quando existir, observacoes, impacto e fonte.

Nao foi implementada edicao de parametros nesta etapa, para nao criar risco de quebra de auditoria sem governanca de versoes.

## Como rodar

O ambiente local foi ajustado para PostgreSQL local, sem Docker.

Credencial local configurada durante a etapa:

```text
usuario: postgres
senha: 123321
host: 127.0.0.1
porta: 5432
```

Comandos:

```powershell
ruby bin/rails db:migrate db:seed
ruby bin/rails db:test:prepare
ruby bin/rails test
ruby bin/rails server -p 3000
```

URLs principais:

```text
http://127.0.0.1:3000
http://127.0.0.1:3000/simulations
http://127.0.0.1:3000/simulations/new
http://127.0.0.1:3000/case_files
http://127.0.0.1:3000/tax_parameters
http://127.0.0.1:3000/assumptions
```

## Testes executados

- Sintaxe Ruby em arquivos de `app`, `config`, `db` e `test`.
- `ruby bin/rails zeitwerk:check`.
- `ruby bin/rails routes` com as novas rotas.
- Recriacao dos bancos locais `tributa_lab_development` e `tributa_lab_test`.
- `ruby bin/rails db:migrate db:seed`.
- `ruby bin/rails db:test:prepare`.
- `ruby bin/rails test`.
- Conferencia de seeds por runner.

## Resultado dos testes

- Sintaxe Ruby: passou.
- Zeitwerk/autoload: passou.
- Rotas: passaram.
- Migrations e seeds: passaram.
- Conferencia de seeds: `case_files=1`, `simulations=0`, `operations=8`, `parameters=8`, `assumptions=9`, `versions=1`.
- Suite Minitest: `35 runs, 175 assertions, 0 failures, 0 errors, 0 skips`.

## Decisoes tomadas

- Mantive calculators por operacao e nao criei motor generico.
- Mantive `TaxRuleVersion`, snapshots e `SimulationResult` separado.
- Implementei `CaseFile` como caso interno simples, nao como cliente/empresa.
- Mantive simulacao sem caso como fluxo valido.
- Para cessao de direitos, apliquei a reducao parametrizada de 70% e mantive alerta divergente obrigatorio.
- Para permuta sem torna, criei calculator informativo com imposto estimado zero e alerta pendente.
- Criei telas de parametros e assumptions somente para consulta.
- Ajustei o setup local para PostgreSQL local com `postgres/123321`, sem Docker.

## Pendencias

- Validar base legal correta: LC 227/2026, LC 214/2025 ou outro texto consolidado.
- Validar artigos 252, 254, 255, 259, 260 e 261.
- Confirmar formula final de locacao.
- Confirmar se cessao de direitos aplica reducao de 70% ou aliquota cheia.
- Confirmar se construcao civil tem alguma reducao especifica ou apenas creditos.
- Confirmar administracao/corretagem com aliquota cheia sem redutor.
- Confirmar tratamento de credito excedente.
- Confirmar se permuta sem torna sera apenas informativa.
- Definir governanca para edicao de parametros.
- Definir formato de validacao com Denis.
- Ainda nao usar com empresas/clientes reais.

## Perguntas para o dono do projeto ou Denis

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
11. Quais campos minimos podem identificar um caso interno sem expor dados sensiveis de empresa real?
12. Qual formato Denis precisa para validar os resultados: tela, tabela, CSV, PDF ou Markdown?

## Proxima etapa sugerida

Etapa 004: validacao guiada e preparacao de governanca.

Sugestao de escopo:

1. Criar roteiro/tabela de validacao com exemplos por operacao.
2. Criar comparacao simples entre simulacoes de um mesmo caso interno.
3. Melhorar visualizacao dos snapshots para revisao com Denis.
4. Definir governanca de edicao de parametros e versoes de regra.
5. Decidir se o proximo passo e CSV/Markdown de validacao ou relatorio exportavel simples.
6. Manter bloqueado o uso com empresas reais ate validar regras juridicas e acesso.