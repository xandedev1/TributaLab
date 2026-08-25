# Banco de Dados — Auditor Fiscal (Real Audit Tech)

> Proposta de arquitetura para migrar o Auditor Fiscal do modelo atual (arquivos em pasta por empresa) para um **banco PostgreSQL relacional, multiempresa e auditável**, dentro do VPS que já roda o produto.

---

## 1. Situação de hoje (ponto de partida)

- Os dados financeiros do Auditor Fiscal **não estão em banco**. Ficam em **arquivos** (`xlsx`/`xlsb`/`pdf`) em `storage/private/fiscal_auditor/<empresa>/`, parseados em memória e cacheados em `*.marshal.gz`.
- A **separação por empresa é por PASTA**; a empresa vem da sessão (`session[:fiscal_auditor_company]`).
- A ligação do cruzamento (`[código do cliente + número da NF]`) é **calculada em memória**, sem chave de banco.
- A única tabela do Auditor Fiscal no Postgres hoje é `fiscal_auditor_users` (logins).
- O restante do TributaLab (eSocial, rubricas CTE, INSS, simulações) **já usa** o Postgres `tributa_lab_production` com modelo relacional.

**Conclusão:** o Postgres já existe e está em produção no VPS. A migração é **adicionar tabelas bem modeladas** ao banco primário — não criar um banco novo.

---

## 2. Princípios de projeto (as regras que não se quebram)

1. **Multiempresa de verdade (multi-tenant).** Toda tabela de dado carrega `company_id` (FK). Nada é lido sem escopo de empresa. O produto nasce pronto para **N empresas**, não só APPA e Soluções.
2. **Integridade referencial.** Chaves estrangeiras (`FK`) com `ON DELETE` explícito; clientes, notas e recebimentos ligados por chave real, não por string solta.
3. **Tempo é chave de busca sempre.** Todo dado com data guarda **ano e mês em colunas próprias e indexadas** (além da data original). Isso é obrigatório — é o filtro mais usado.
4. **Rastreabilidade total.** Todo registro sabe de **qual arquivo e qual linha** veio (`source_file_id`, `source_row`) e de **qual importação** (`import_run_id`). Isso alimenta a tela "Fonte Original" e a auditoria.
5. **Idempotência na importação.** Reimportar o mesmo arquivo não duplica dados (controle por `sha256` do arquivo + `import_run`).
6. **Migração sem quebrar.** O banco entra em paralelo ao arquivo. Só desligamos o modo-arquivo depois de **conferir paridade** (contagens e somas batem).
7. **Dinheiro é `numeric(15,2)`** — nunca `float`. Datas são `date`. Textos normalizados.
8. **Nomenclatura consistente.** Prefixo `fiscal_` em todas as tabelas do produto (segue o padrão `esocial_*`, `rubricas_cte_*` já usado no app).

---

## 3. Onde o banco vive (VPS)

- **Mesma instância PostgreSQL** já usada em produção.
- **Mesmo banco primário:** `tributa_lab_production` (onde já vivem as 36 tabelas atuais). As novas tabelas convivem com prefixo `fiscal_`.
- Bancos auxiliares (`_cache`, `_queue`, `_cable`) continuam intocados — são do Solid Cache/Queue/Cable.
- Criação e evolução **exclusivamente via migrations do Rails** (`bin/rails g migration ...`), com `db/schema.rb` versionado. Nada de DDL manual solto.
- Deploy no VPS roda `bin/rails db:migrate` no release (já é o fluxo do Kamal do projeto).

> **Opcional avançado:** isolar as tabelas num *schema* PostgreSQL dedicado (`audit`) em vez de prefixo. Recomendação: **começar com prefixo `fiscal_`** (mais simples no Rails) e só migrar para schema dedicado se o número de tabelas explodir.

---

## 4. Modelo de dados (o coração)

### 4.1 Núcleo multiempresa

**`fiscal_companies`** — a raiz de tudo (cada tenant)
| Coluna | Tipo | Notas |
|---|---|---|
| `id` | bigint PK | |
| `slug` | string, **unique** | "appa", "solucoes", … (usado na URL/sessão) |
| `legal_name` | string | Razão social |
| `trade_name` | string | Nome fantasia |
| `cnpj` | string(14), **unique** | Chave natural da empresa |
| `status` | string | `active` / `inactive` |
| `settings` | jsonb | Flags por empresa (quais módulos tem) |
| `created_at/updated_at` | timestamp | |

**`fiscal_clients`** — os tomadores/clientes de **cada** empresa
| Coluna | Tipo | Notas |
|---|---|---|
| `id` | bigint PK | |
| `company_id` | bigint FK → fiscal_companies | |
| `code` | string | Código do cliente (o "código" do cruzamento) |
| `cnpj` | string(14), nullable | |
| `name` | string | |
| — | | **unique (`company_id`, `code`)** |
| — | | index (`company_id`, `name`) |

> Clientes viram **entidade de primeira classe**: faturamento e contas a receber apontam para o mesmo `client_id`. É isso que torna o cruzamento confiável.

### 4.2 Rastreabilidade / importação

**`fiscal_source_files`** — cada arquivo original que entrou
| `id` PK · `company_id` FK · `module` (billing/receivables/…) · `filename` · `sha256` **unique(company_id, sha256)** · `byte_size` · `imported_at` |

**`fiscal_import_runs`** — cada rodada de importação (lote)
| `id` PK · `company_id` FK · `module` · `source_file_id` FK · `status` (running/completed/failed) · `rows_imported` · `started_at` · `finished_at` · `error_message` |

### 4.3 Dimensão de tempo (padrão obrigatório em TODA tabela com data)

Para cada data relevante (emissão, competência, pagamento), o padrão é:

```
issued_on        date               -- a data canônica
issued_year      smallint  GENERATED ALWAYS AS (extract(year  from issued_on)) STORED
issued_month     smallint  GENERATED ALWAYS AS (extract(month from issued_on)) STORED
```

- A data é a fonte da verdade; **ano e mês são colunas geradas e armazenadas** (`GENERATED ... STORED`) → **não podem divergir** e são **indexáveis**.
- `competencia` é sempre o **1º dia do mês** (`date`), com `competencia_year`/`competencia_month` gerados.
- Índice padrão: `(company_id, <campo>_year, <campo>_month)`.

> Assim, "faturamento de 07/2026" ou "recebimentos de 2025" viram consulta direta e rápida por coluna indexada — exatamente a chave de busca principal do produto.

### 4.4 Tabelas de módulo

**`fiscal_billings`** — Faturamento (NFs emitidas)
| `id` PK · `company_id` FK · `client_id` FK (nullable até resolver) · `client_code` · `client_name` · `client_cnpj` · `invoice_number` (Nº NF-e) · `rps` · `status` · `issued_on` (+year/month) · `competencia` (+year/month) · `gross_amount` · `inss` · `irrf` · `pis` · `cofins` · `csll` · `iss` · `net_amount` · `filial` · `source_file_id` · `source_row` · `import_run_id` |
- **Chave de cruzamento:** index `(company_id, client_code, invoice_number)`.
- Index de tempo: `(company_id, competencia_year, competencia_month)` e `(company_id, issued_year, issued_month)`.

**`fiscal_receivables`** — Contas a receber
| `id` PK · `company_id` FK · `client_id` FK · `client_code` · `invoice_number` · `issued_on` (+y/m) · `competencia` (+y/m) · `gross_amount` · `contingency` · `paid_amount` · `payment_date` (+paid_year/paid_month) · `situation` · `source_file_id` · `source_row` · `import_run_id` |
- Mesma **chave de cruzamento** `(company_id, client_code, invoice_number)` → é o que casa com `fiscal_billings`.

**`fiscal_payables`** — Contas a pagar (despesas)
| `id` PK · `company_id` FK · `identification` · `source_sheet` · `amount` · `payment_date` (+y/m) · `competencia` (+y/m) · `competence_expense` (bool) · `source_file_id` · `source_row` · `import_run_id` |

**`fiscal_payroll_entries`** — Folha (evento a evento)
| `id` PK · `company_id` FK · `client_id`/`client_code` · `employee_name` · `competencia` (+y/m) · `event_code` · `event_type` (Vencimento/Desconto) · `event_description` · `amount` · `status` · `source_file_id` · `source_row` · `import_run_id` |
- Index `(company_id, client_code, competencia_year, competencia_month)`.

**`fiscal_payroll_charges`** — Encargos INSS/FGTS
| `id` PK · `company_id` FK · `kind` (inss / fgts_monthly / fgts_thirteenth) · `competencia` (+y/m) · `amount` · `code` · `description` · `source_column` · `source_file_id` · `source_row` · `import_run_id` |

**`fiscal_linked_accounts`** — Extrato conta vinculada (contrato)
| `id` PK · `company_id` FK · `client_id`/`code` · `uf` · `contrato` · `banco` · `conta` · `status` |

**`fiscal_linked_account_balances`** — saldos mês a mês (tabela filha)
| `id` PK · `linked_account_id` FK · `company_id` FK · `reference` (date dia=01, +year/month) · `balance` |
- Um saldo por (conta, mês) → **unique (`linked_account_id`, `reference`)**. É aqui que "mês/ano viram coluna" para a conta vinculada.

**`fiscal_efd_records`** — EFD (A100/C100) — Soluções
| `id` PK · `company_id` FK · `doc_type` (a100/c100) · `codigo` · `num_nf` · `issued_on` (+y/m) · `amount` · `source_file` · `page` |

**`fiscal_razao_records`** — Razão (PDF) — Soluções
| `id` PK · `company_id` FK · `num_nf` · `issued_on` (+y/m) · `credit` · `source_file` · `page` |

**`fiscal_devolucoes`** — Devoluções — Soluções
| `id` PK · `company_id` FK · `num_nf` · `issued_on` (+y/m) · `amount` · `source_file` · `page` |

> Lotações tributárias e o Comparativo EFD × ECF são **referência/derivado**; podem entrar depois (lotações como `fiscal_tax_lotations`, comparativo como *view*/consulta agregada sobre `fiscal_efd_records`/`fiscal_razao_records`).

---

## 5. Como o cruzamento funciona no banco

O cruzamento Faturamento × Contas a receber deixa de ser cálculo em memória e vira **JOIN indexado**:

```sql
SELECT b.*, r.*
FROM fiscal_billings b
LEFT JOIN fiscal_receivables r
  ON  r.company_id     = b.company_id
  AND r.client_code    = b.client_code
  AND r.invoice_number = b.invoice_number
WHERE b.company_id = :company_id
  AND b.competencia_year = :ano;
```

- Casadas = match nos dois lados; divergentes = valores diferentes; faturado sem recebimento = `r.id IS NULL`; recebido sem faturamento = o LEFT JOIN espelhado.
- O índice `(company_id, client_code, invoice_number)` nas duas tabelas torna isso instantâneo.

---

## 6. Índices e performance (resumo)

- `(company_id)` em toda tabela (escopo multiempresa).
- **Chave de cruzamento:** `(company_id, client_code, invoice_number)` em `fiscal_billings` e `fiscal_receivables`.
- **Tempo:** `(company_id, <data>_year, <data>_month)` em toda tabela com data.
- `(company_id, client_id)` para navegação por cliente.
- `unique` onde faz sentido (empresa por CNPJ, cliente por código, saldo por conta+mês, arquivo por sha256).

---

## 7. Estratégia de migração (sem quebrar nada)

**Fase 0 — Fundação**
- Criar `fiscal_companies` e semear APPA + Soluções (com os CNPJs reais).
- Passar o escopo da sessão a usar `company_id` (mantendo o `slug` atual como espelho).

**Fase 1 — Schema**
- Migrations de todas as tabelas acima (sem tocar no fluxo atual).

**Fase 2 — Importadores**
- Reaproveitar os parsers que já existem (`RetentionWorkbook`, `ReceivableSnapshot`, etc.) para **ler o arquivo e gravar no banco** dentro de um `fiscal_import_run` (idempotente por `sha256`).
- Rodar para APPA e Soluções.

**Fase 3 — Conferência de paridade (trava de segurança)**
- Comparar **contagens e somas** banco × arquivo:
  - Faturamento: 16.800 notas; Contas a receber: 25.664; Despesas: 37.590; Folha: 48.771; Conta vinculada: 61; Encargos: 12 competências.
- Só avança se bater 100%.

**Fase 4 — Leitura pelo banco**
- Trocar os dashboards para ler via ActiveRecord (escopo `where(company_id:)`), mantendo o mesmo comportamento visual.
- Manter o modo-arquivo como *fallback* até estabilizar.

**Fase 5 — Desligar o modo-arquivo**
- Arquivos originais **continuam guardados** como evidência (não some nada), mas deixam de ser a fonte de leitura.

---

## 8. Multiempresa e segurança

- Todo acesso passa por `company_id` derivado da sessão — nunca confiar em parâmetro do usuário.
- Padrão de código: `scope :for_company, ->(id) { where(company_id: id) }` em todos os models; controllers sempre aplicam.
- (Opcional forte) **RLS (Row Level Security)** do PostgreSQL como cinto de segurança extra, garantindo no próprio banco que uma empresa nunca leia linha de outra.
- Onboarding de nova empresa = 1 `INSERT` em `fiscal_companies` + importar seus arquivos. Zero código novo.

---

## 9. Convenções

- Tabelas: `snake_case`, prefixo `fiscal_`, plural.
- Dinheiro: `numeric(15,2)`. Percentuais: `numeric(7,4)`.
- Datas: `date`; carimbos: `timestamp` (`created_at`/`updated_at`).
- Ano/mês: `smallint` **gerados** da data (`GENERATED ALWAYS AS ... STORED`).
- Toda FK com índice e `ON DELETE` explícito (`restrict` para dados, `cascade` para filhas como saldos).

---

## 10. Próximos passos sugeridos

1. Aprovar este modelo (ajustar nomes/colunas se necessário).
2. Migration da **Fase 0 + 1** (companies + schema completo).
3. Importadores (Fase 2) reaproveitando os parsers atuais.
4. Script de **paridade** (Fase 3) antes de virar a chave de leitura.

> Nada é removido antes da paridade. O produto continua funcionando o tempo todo; o banco entra por baixo, empresa por empresa, com os dados íntegros e prontos para cruzamento.
