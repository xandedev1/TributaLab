# TributaLab

TributaLab e uma plataforma Rails para inteligencia tributaria operacional. O primeiro modulo e **Reforma Tributaria Imobiliaria**, com PostgreSQL, Hotwire e Tailwind.

O briefing completo da criacao do projeto esta preservado em `docs/00_brief/README_INICIAL_TRIBUTALAB.md`. A coordenacao por etapas fica em `docs/03_comunicacao/`.

## Setup local

Requisitos iniciais:

- Ruby 3.3+
- Rails 8.1+
- PostgreSQL acessivel localmente

Comandos:

```bash
bundle install
ruby bin/rails db:create db:migrate db:seed
ruby bin/rails test
ruby bin/rails server
```

Se o PostgreSQL local usar host, porta, usuario ou senha especificos, configure as variaveis `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD` ou `DATABASE_URL` conforme o ambiente.

Exemplo com PostgreSQL em Docker para desenvolvimento no PowerShell:

```powershell
docker run -d --name tributalab-postgres-dev -e POSTGRES_USER=tributalab -e POSTGRES_PASSWORD=tributalab -e POSTGRES_DB=postgres -p 55432:5432 postgres:16
$env:POSTGRES_HOST="localhost"
$env:POSTGRES_PORT="55432"
$env:POSTGRES_USER="tributalab"
$env:POSTGRES_PASSWORD="tributalab"
ruby bin/rails db:create db:migrate db:seed
```

## Escopo atual

A Etapa 001 cria o esqueleto tecnico, a modelagem inicial, seeds do modulo imobiliario, tela operacional inicial e documentacao de handoff. Calculos completos entram a partir da Etapa 002.
