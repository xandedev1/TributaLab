# ETAPA 002 - Resposta

## Resumo do que foi feito

A Etapa 002 implementou o fluxo minimo de simulacao auditavel da Reforma Tributaria Imobiliaria para quatro operacoes:

1. Venda de imovel / incorporacao.
2. Venda de lote residencial.
3. Locacao de imoveis.
4. Permuta com torna.

O sistema agora possui versionamento leve de regras com `TaxRuleVersion`, calculators por operacao, persistencia de `Simulation` e `SimulationResult`, snapshots auditaveis e uma UI minima para calcular e salvar simulacoes internas.

A locacao segue a formula indicada na planilha, deduzindo IPTU e condominio, mas exibe e persiste alerta de divergencia porque o exemplo da planilha usa aluguel integral.

## Arquivos criados ou alterados

- `docs/03_comunicacao/MD_002_PARA_AGENTE_IMPLEMENTACAO_RAILS.md`: pedido recebido do arquiteto preservado no repo.
- `docs/03_comunicacao/ETAPA_002_PEDIDO.md`: pedido formal da etapa.
- `docs/03_comunicacao/ETAPA_002_RESPOSTA.md`: resposta formal da etapa.
- `docs/02_decisoes/DECISAO_002_versionamento_regras_simulacoes.md`: decisao tecnica sobre versionamento, snapshots e calculators.
- `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`: adicionadas perguntas sobre usuario final e cadastro de clientes/casos.
- `db/migrate/20260528190000_create_tax_rule_versions.rb`: cria `tax_rule_versions`.
- `db/migrate/20260528190010_add_tax_rule_version_and_snapshots_to_simulations.rb`: associa simulacoes a versao de regra e adiciona snapshots.
- `db/migrate/20260528190020_add_calculation_details_to_simulation_results.rb`: adiciona detalhes estruturados do calculo.
- `app/models/tax_rule_version.rb`: model de versao de regra.
- `app/models/tax_module.rb`: relacionamento com versoes de regra.
- `app/models/simulation.rb`: relacionamento com versao e validacao de snapshots.
- `app/models/simulation_result.rb`: validacao de detalhes do calculo.
- `app/services/tax_rules/real_estate/*.rb`: calculators por operacao.
- `app/services/simulations/run_simulation.rb`: service de execucao e persistencia auditavel.
- `app/controllers/simulations_controller.rb`: fluxo minimo de simulacao.
- `app/views/simulations/new.html.erb`: formulario operacional de simulacao.
- `app/views/simulations/show.html.erb`: tela de resultado e snapshots.
- `app/controllers/dashboard_controller.rb` e `app/views/dashboard/index.html.erb`: link para nova simulacao e exibicao da versao de regra.
- `config/routes.rb`: rotas de simulacao.
- `db/seeds.rb`: seed idempotente de `TaxRuleVersion` e ajuste de percentuais para strings decimais.
- `test/fixtures/*.yml`: fixtures expandidas para Etapa 002.
- `test/models/tax_rule_version_test.rb`: testes do model de versao.
- `test/services/tax_rules/real_estate/calculators_test.rb`: testes dos quatro calculators.
- `test/services/simulations/run_simulation_test.rb`: testes de persistencia e snapshots.
- `test/controllers/simulations_controller_test.rb`: teste do fluxo basico da UI.

## Migrations e modelos

Foi criado `TaxRuleVersion` com:

- `tax_module_id`
- `code`
- `name`
- `status`
- `effective_from`
- `effective_until`
- `source_summary`
- `notes`

Foi adicionada associacao de `Simulation` com `TaxRuleVersion`.

Foram adicionados snapshots em `Simulation`:

- `assumptions_snapshot`
- `alerts_snapshot`
- `legal_bases_snapshot`
- `rule_version_snapshot`

Foi adicionado `calculation_details` em `SimulationResult`.

## Services de calculo

Calculators criados:

- `TaxRules::RealEstate::SalePropertyCalculator`
- `TaxRules::RealEstate::SaleResidentialLotCalculator`
- `TaxRules::RealEstate::LeasePropertyCalculator`
- `TaxRules::RealEstate::ExchangeWithBootCalculator`

Todos retornam estrutura padronizada com:

- `operation_code`
- `inputs`
- `parameters`
- `assumptions`
- `alerts`
- `legal_bases`
- `rule_version`
- `result`
- `calculation_details`

Os calculos usam `BigDecimal`. Na gravacao de JSON, valores decimais sao serializados como string para evitar perda de precisao.

## Fluxo de simulacao

A UI minima esta em:

```text
/simulations/new
```

O usuario escolhe uma das quatro operacoes da Etapa 002, informa os campos aplicaveis e salva a simulacao.

Apos salvar, o sistema exibe:

- resultado estruturado;
- inputs usados;
- parametros usados;
- versao de regra;
- alertas e assumptions;
- detalhes do calculo.

A tela de resultado fica em:

```text
/simulations/:id
```

## Como rodar

Com PostgreSQL em Docker, como usado na validacao:

```powershell
$env:POSTGRES_HOST="localhost"
$env:POSTGRES_PORT="55432"
$env:POSTGRES_USER="tributalab"
$env:POSTGRES_PASSWORD="tributalab"
ruby bin/rails db:migrate db:seed
ruby bin/rails db:test:prepare
ruby bin/rails test
ruby bin/rails server -p 3000
```

URLs principais:

```text
http://127.0.0.1:3000
http://127.0.0.1:3000/simulations/new
```

## Testes executados

- `ruby -c` em arquivos Ruby de `app`, `config`, `db` e `test`.
- `ruby bin/rails db:migrate db:seed`.
- `ruby bin/rails runner "puts({versions: TaxRuleVersion.count, simulations: Simulation.count, operations: Operation.count, parameters: TaxParameter.count, assumptions: Assumption.count}.inspect)"`.
- `ruby bin/rails db:test:prepare; ruby bin/rails test`.
- `Invoke-WebRequest http://127.0.0.1:3000`.
- `Invoke-WebRequest http://127.0.0.1:3000/simulations/new`.

## Resultado dos testes

- Sintaxe Ruby: passou.
- Migrations e seeds: passaram.
- Conferencia de seeds apos Etapa 002: `versions=1`, `simulations=0`, `operations=8`, `parameters=8`, `assumptions=9`.
- Suite Minitest: `18 runs, 87 assertions, 0 failures, 0 errors, 0 skips`.
- Dashboard HTTP: `Status=200`, contendo `Nova simulacao`.
- Tela `/simulations/new`: `Status=200`, contendo `Venda de imovel` e `Locacao de imoveis`.

Observacao: uma primeira verificacao HTTP falhou apenas porque o PowerShell nao permite sobrescrever a variavel reservada `$HOME`; o comando foi repetido com `$homeResponse` e passou.

## Decisoes tomadas

- Segui a decisao arquitetural de manter `TaxModule`.
- Criei `TaxRuleVersion` como versionamento leve, nao um motor completo de regras.
- Mantive `Simulation` e `SimulationResult` separados.
- Centralizei persistencia em `Simulations::RunSimulation`.
- Usei calculators por operacao, sem motor generico universal.
- Para locacao, usei a formula indicada no documento (`aluguel - iptu - condominio`) e registrei a divergencia em alertas/snapshots.
- Para credito maior que debito, a permuta com torna aplica `max(0, debito - creditos)` e registra a assumption pendente.

## Pendencias

- Validar LC 227/2026 vs LC 214/2025 e artigos associados.
- Validar formula final de locacao com Denis/dono do projeto.
- Validar se credito excedente deve gerar saldo ou apenas zerar imposto.
- Ligar `LegalBasis` a parametros, operacoes ou assumptions por relacionamento real.
- Permitir gestao visual de `TaxRuleVersion` e `TaxParameter`.
- Melhorar UI com campos condicionais por operacao.
- Definir se simulacoes precisam estar vinculadas a cliente/caso.
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

## Proxima etapa sugerida

Etapa 003: ampliar o fluxo de simulacao para revisao operacional e validacao de negocio.

Sugestao de escopo:

1. Melhorar UI com campos condicionais por operacao.
2. Criar listagem de simulacoes salvas.
3. Adicionar simuladores de construcao civil, administracao/corretagem e cessao de direitos.
4. Criar tela de parametros e assumptions para consulta/edicao controlada.
5. Definir se entra cadastro simples de cliente/caso ou se continua como simulador interno sem cliente.
6. Preparar roteiro de validacao com Denis usando os resultados das quatro operacoes.
