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

## Pendencias

### [PENDENTE] Fase 5 — App ler do banco (nao dos arquivos)

Status: **pendente — resolver assim que possivel.**

Hoje o banco relacional multiempresa (`fiscal_companies`, `fiscal_billings`, `fiscal_receivables`, `fiscal_payables`, `fiscal_payroll_entries`, `fiscal_payroll_charges`, `fiscal_linked_accounts`, `fiscal_efd_records`, `fiscal_razao_records`, `fiscal_devolucoes`) **ja esta criado e populado em dev e em producao, com paridade 100%** contra os arquivos de origem. Porem **o app ainda le dos arquivos** (planilhas xlsb/marshal em `storage/private/fiscal_auditor/<empresa>/`), nao do banco. O banco entra "por baixo", esperando.

Falta virar a chave de leitura: fazer os dashboards lerem do banco (`Fiscal::X.for_company(id)`) **com fallback para o arquivo** caso o banco nao tenha o dado — assim e impossivel quebrar o site (no pior caso volta a ler o arquivo como hoje). Fazer tela por tela, conferindo paridade antes de subir:

1. Faturamento
2. Contas a receber
3. Contas a pagar
4. Folha + Encargos
5. Conta vinculada
6. EFD / Razao / Devolucoes (Solucoes)

Referencia de implementacao: `docs/01_planejamento/banco_dados_auditor_fiscal_BIBLIA.md` (Fase 5).

Relacionado (tambem pendente):
- Subir os arquivos de **Faturamento 2026** para o VPS e reimportar (prod hoje so tem 2025).
- **Seguranca:** rotacionar a senha root do VPS e o token do GitHub que estao em texto puro em `script/*.py` e no remote do git no servidor.
