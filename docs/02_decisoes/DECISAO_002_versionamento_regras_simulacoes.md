# DECISAO 002 - Versionamento de regras e simulacoes

## Contexto

A Etapa 002 precisava transformar a base da Etapa 001 em um fluxo minimo de simulacao auditavel para quatro operacoes da Reforma Tributaria Imobiliaria.

As regras ainda tem pendencias juridicas importantes. Por isso, a arquitetura nao pode depender apenas do estado atual de `TaxParameter` ou das assumptions vigentes no banco, porque uma simulacao antiga precisa continuar reproduzivel mesmo depois de alteracoes futuras.

## Decisoes

- Criar `TaxRuleVersion` como versao leve de regras por `TaxModule`.
- Associar `Simulation` a `TaxRuleVersion`, mantendo tambem o campo textual `rule_version` por compatibilidade e leitura rapida.
- Salvar snapshots em `Simulation` para inputs, parametros, assumptions, alertas, bases legais e versao de regra.
- Manter `Simulation` e `SimulationResult` separados.
- Guardar os principais resultados numericos em colunas `decimal` consultaveis em `SimulationResult`.
- Guardar detalhes auxiliares do calculo em `SimulationResult.calculation_details` como JSONB.
- Organizar calculos em calculators por operacao dentro de `TaxRules::RealEstate`, sem criar motor tributario generico nesta etapa.
- Persistir simulacoes pelo service `Simulations::RunSimulation`, que centraliza calculator, snapshots e criacao de `SimulationResult`.

## Como os snapshots funcionam

Cada simulacao salva:

- `input_data`: valores usados como entrada.
- `parameters_snapshot`: parametros tributarios consultados, com valor, unidade, status e referencia.
- `assumptions_snapshot`: assumptions pendentes ou divergentes consideradas no calculo.
- `alerts_snapshot`: alertas exibidos ao usuario no momento da simulacao.
- `legal_bases_snapshot`: bases legais disponiveis no momento da simulacao.
- `rule_version_snapshot`: codigo, nome, status e origem da versao de regra.
- `output_data`: resultado calculado e detalhes auxiliares.

Valores `BigDecimal` sao convertidos para strings no snapshot JSON para evitar perda de precisao.

## Por que Simulation e SimulationResult ficaram separados

`Simulation` representa o evento auditavel de calculo: modulo, operacao, versao, inputs e snapshots.

`SimulationResult` representa o resultado estruturado e consultavel: base bruta, deducao, base liquida, aliquotas, debito, creditos e imposto liquido.

Essa separacao permite consultar resultados numericos sem abrir JSON e, ao mesmo tempo, preservar memoria completa da simulacao.

## Organizacao dos calculators

Foram criados calculators especificos:

- `TaxRules::RealEstate::SalePropertyCalculator`
- `TaxRules::RealEstate::SaleResidentialLotCalculator`
- `TaxRules::RealEstate::LeasePropertyCalculator`
- `TaxRules::RealEstate::ExchangeWithBootCalculator`

Todos herdam de uma base simples, `TaxRules::RealEstate::BaseCalculator`, apenas para compartilhar carga de parametros, assumptions, alertas, bases legais e normalizacao decimal.

## Simplificacoes deixadas para depois

- Nao foi criado motor generico de regras.
- Nao foi criada gestao visual de versoes de regra.
- `LegalBasis` ainda nao tem relacionamento por FK com parametros, operacoes ou assumptions.
- `Assumption` ainda nao altera dinamicamente o comportamento por configuracao de usuario; a escolha usada no calculo fica documentada em `calculation_details`.
- Nao ha clientes, contas, casos ou multi-tenant.
- Nao ha relatorio final ou exportacao.

## Consequencias

A Etapa 002 passa a permitir simulacoes internas auditaveis das quatro primeiras operacoes, com regra marcada como pendente de validacao. O sistema continua improprio para uso real com clientes sem validacao humana das pendencias juridicas.