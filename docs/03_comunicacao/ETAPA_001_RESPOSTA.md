# ETAPA 001 - Resposta

## Resumo do que foi feito

Foi criado o esqueleto tecnico do TributaLab em Ruby on Rails 8.1.3 com PostgreSQL e Tailwind. A modelagem inicial cobre areas do produto, setores, modulos tributarios, operacoes, parametros, assumptions, bases legais, categorias de credito, simulacoes e resultados.

O modulo inicial **Reforma Tributaria Imobiliaria** foi carregado por seeds com 8 operacoes, parametros iniciais, categorias de credito e 9 pendencias de validacao registradas como `Assumption`.

As fontes de pesquisa estavam acessiveis em:

```text
c:/Users/xandao/Documents/GitHub/xAI/comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/
```

O pacote foi copiado para:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/
```

Total copiado: 22 arquivos.

## Arquivos criados ou alterados

- `README.md`: instrucoes locais do projeto e exemplo com PostgreSQL em Docker.
- `Gemfile`: gerado pelo Rails com PostgreSQL, Hotwire, Tailwind e ferramentas padrao do Rails 8.
- `config/database.yml`: PostgreSQL configurado com suporte a `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER` e `POSTGRES_PASSWORD`.
- `config/routes.rb`: rota raiz para o dashboard inicial.
- `app/controllers/dashboard_controller.rb`: controller fino para a tela inicial.
- `app/views/dashboard/index.html.erb`: tela operacional inicial com operacoes, parametros, creditos e alertas.
- `app/services/tax_rules/validation_alerts.rb`: service inicial para consolidar parametros/assumptions pendentes.
- `app/models/*.rb`: associacoes, validacoes e escopos do dominio inicial.
- `db/migrate/*.rb`: migrations iniciais com `decimal` para dinheiro, aliquotas e percentuais.
- `db/seeds.rb`: seeds idempotentes do modulo Reforma Tributaria Imobiliaria.
- `test/models/*.rb` e `test/services/tax_rules/validation_alerts_test.rb`: testes basicos de models e service.
- `docs/00_brief/README_INICIAL_TRIBUTALAB.md`: briefing inicial preservado antes do scaffold Rails.
- `docs/02_decisoes/DECISAO_001_setup_inicial.md`: decisoes tecnicas da etapa.
- `docs/03_comunicacao/ETAPA_001_PEDIDO.md`: pedido/contexto formal da etapa.
- `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`: perguntas de negocio pendentes.
- `docs/04_referencias/INDICE_FONTES.md`: indice das fontes consultadas, copiadas e referenciadas.
- `docs/04_referencias/pesquisa_original/`: copia do pacote original de pesquisa.

## Como rodar

Com PostgreSQL ja disponivel e credenciais configuradas:

```powershell
bundle install
ruby bin/rails db:create db:migrate db:seed
ruby bin/rails test
ruby bin/rails server
```

Com PostgreSQL em Docker, como usado na validacao da etapa:

```powershell
docker run -d --name tributalab-postgres-dev -e POSTGRES_USER=tributalab -e POSTGRES_PASSWORD=tributalab -e POSTGRES_DB=postgres -p 55432:5432 postgres:16
$env:POSTGRES_HOST="localhost"
$env:POSTGRES_PORT="55432"
$env:POSTGRES_USER="tributalab"
$env:POSTGRES_PASSWORD="tributalab"
ruby bin/rails db:create db:migrate db:seed
ruby bin/rails db:test:prepare
ruby bin/rails test
ruby bin/rails server -p 3000
```

URL validada:

```text
http://127.0.0.1:3000
```

## Testes executados

- `ruby -c` em arquivos Ruby de `app`, `config`, `db` e `test`: passou.
- `ruby bin/rails runner "puts Rails.application.class.module_parent_name"`: passou, retornando `TributaLab`.
- `ruby bin/rails db:create db:migrate db:seed` usando PostgreSQL local padrao: falhou porque o PostgreSQL em `localhost:5432` exige senha e nenhuma senha estava no ambiente.
- PostgreSQL Docker `postgres:16` em `localhost:55432`: iniciado e usado para validacao.
- `ruby bin/rails db:create db:migrate db:seed` com Docker PostgreSQL: passou.
- Conferencia dos seeds via runner: `areas=2`, `sectors=1`, `modules=1`, `operations=8`, `parameters=8`, `assumptions=9`, `credit_categories=7`, `legal_bases=5`.
- `ruby bin/rails test`: primeira execucao indicou schema pendente no banco de teste.
- `ruby bin/rails db:test:prepare; ruby bin/rails test`: passou com `8 runs, 25 assertions, 0 failures, 0 errors, 0 skips`.
- `ruby bin/rails server -p 3000`: subiu sem erro.
- `Invoke-WebRequest http://127.0.0.1:3000`: retornou `Status=200` e confirmou textos `TributaLab` e `Reforma Tributaria Imobiliaria`.
- `ruby bin/rails db:seed` executado novamente: manteve `operations=8`, `parameters=8`, `assumptions=9`, confirmando idempotencia basica.

## Decisoes tomadas

- Usar `TaxModule` no codigo em vez de `Module`, para evitar conflito com a constante nativa `Module` do Ruby.
- Manter Minitest nesta etapa para reduzir dependencias iniciais.
- Criar `Assumption` ja na Etapa 001 para registrar divergencias e impedir regra juridica definitiva sem validacao.
- Criar `LegalBasis` e `CreditCategory` desde o inicio, pois os documentos de pesquisa ja apontam necessidade de base legal, status e creditos.
- Usar Docker apenas para validacao local, porque o PostgreSQL existente em `localhost:5432` exigia senha nao disponivel no ambiente.

## Pendencias

- Validar base legal correta: LC 227/2026, LC 214/2025 ou consolidacao posterior.
- Validar se locacao exclui IPTU e condominio da base.
- Validar se cessao de direitos aplica reducao de 70% ou aliquota cheia.
- Validar tratamento de creditos maiores que debito.
- Validar condicoes documentais para aproveitamento de creditos.
- Implementar services reais de calculo na Etapa 002.
- Implementar fluxo de criacao e persistencia de simulacoes pelo usuario.

## Perguntas para o dono do projeto

As perguntas estao consolidadas em:

```text
docs/03_comunicacao/PERGUNTAS_ABERTAS.md
```

## Proxima etapa sugerida

Etapa 002: implementar os services de calculo e testes para:

1. Venda de imovel / incorporacao.
2. Venda de lote residencial.
3. Locacao de imoveis, mantendo alerta de divergencia.
4. Permuta com torna.

Tambem e recomendado criar formularios simples para registrar `Simulation` e `SimulationResult`, salvando inputs, outputs, parametros usados e alertas de validacao.