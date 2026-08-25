# Real Audit Tech

Real Audit Tech é uma plataforma Rails de **auditoria fiscal multiempresa**. O produto cruza faturamento, contas a receber, folha e obrigações fiscais de cada empresa — nota a nota — sobre PostgreSQL, Hotwire e Tailwind.

> Observação: o diretório do repositório e o módulo Rails interno ainda usam o nome legado `TributaLab`/`tributa_lab` (não alterar — é infraestrutura). A marca do produto é **Real Audit Tech**.

## Setup local

Requisitos iniciais:

- Ruby 3.3+
- Rails 8.1+
- PostgreSQL local em execucao

Este projeto deve usar PostgreSQL local no desenvolvimento. Configure as credenciais locais por variaveis de ambiente quando o servidor exigir usuario/senha.

Comandos:

```bash
bundle install
ruby bin/rails db:create db:migrate db:seed
ruby bin/rails test
ruby bin/rails server
```

Exemplo com PostgreSQL local no PowerShell:

```powershell
$env:POSTGRES_HOST="127.0.0.1"
$env:POSTGRES_PORT="5432"
$env:POSTGRES_USER="seu_usuario_local"
$env:POSTGRES_PASSWORD="sua_senha_local"
ruby bin/rails db:create db:migrate db:seed
ruby bin/rails db:test:prepare
ruby bin/rails test
```

## Escopo atual

Ate a Etapa 003, o app possui dashboard operacional, oito simuladores do modulo Reforma Tributaria Imobiliaria, snapshots auditaveis, listagem de simulacoes, casos internos simples e telas de consulta de parametros e assumptions. Ainda nao deve ser usado com empresas reais ou clientes externos.
