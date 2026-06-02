# TributaLab

TributaLab e uma plataforma Rails para inteligencia tributaria operacional. O primeiro modulo e **Reforma Tributaria Imobiliaria**, com PostgreSQL, Hotwire e Tailwind.

O briefing completo da criacao do projeto esta preservado em `docs/00_brief/README_INICIAL_TRIBUTALAB.md`. A coordenacao por etapas fica em `docs/03_comunicacao/`.

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
