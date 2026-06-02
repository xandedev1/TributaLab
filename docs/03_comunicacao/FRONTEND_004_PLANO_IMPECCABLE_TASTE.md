# FRONTEND 004 - Plano Impeccable + Taste

Data: 2026-06-01
Projeto: TributaLab
Escopo: frontend, navegacao e UX operacional

## Direcao

Reading this as: B2B fiscal operations workbench for consultants reviewing tax rules, simulations and eSocial rubrics, with a quiet technical audit-room language, leaning toward dense product UI, Rails ERB/Tailwind components, restrained motion and high readability.

Dials:

- DESIGN_VARIANCE: 3/10
- MOTION_INTENSITY: 1/10
- VISUAL_DENSITY: 8/10

## Referencias usadas

- `pbakaus/impeccable`: referencia primaria para documentar design system, extrair padroes, reduzir anti-patterns, polir e endurecer estados.
- `Leonxlnx/taste-skill`: referencia seletiva para redesign de projeto existente e checklist anti-slop.
- `langfuse/langfuse`: referencia de observabilidade, detalhe auditavel, traces, scores, datasets e confianca tecnica.
- `dubinc/dub`: referencia de console operacional, metricas acionaveis, rastreabilidade, self-host/trust cues e densidade limpa.

As skills nao serao instaladas nesta etapa. O projeto continuara Rails 8, ERB, Hotwire/Turbo/Stimulus, Tailwind Rails e importmap, sem `package.json` e sem dependencias frontend novas.

## Telas que serao alteradas

Prioridade desta passada:

- `app/views/layouts/application.html.erb`
- `app/helpers/application_helper.rb`
- `app/assets/tailwind/application.css`
- `app/views/dashboard/index.html.erb`
- `app/views/rubric_recovery/adequacy/index.html.erb`
- `app/views/rubric_recovery/adequacy/show.html.erb`
- `app/views/rubric_recovery/rubrics_natures/index.html.erb`
- `app/views/rubric_recovery/radar/show.html.erb`

As demais telas serao harmonizadas por componentes globais `tl-*`, sem reescrever fluxos.

## Classes e padroes a manter/refatorar

Manter nomes `tl-*` e evoluir incrementalmente:

- `tl-nav-link`, com suporte a grupos e subitens;
- `tl-command-bar` como header operacional;
- `tl-panel`, `tl-card`, `tl-tile`, com menos monocromia;
- `tl-table` como tabela densa de trabalho;
- `tl-badge`, `tl-chip`, `tl-button` com cores funcionais.

Criar ou consolidar:

- `tl-nav-group`, `tl-nav-section`, `tl-nav-subgroup`, `tl-nav-sublink`;
- `tl-section-tabs` para `Eventos > S-1010`;
- `tl-metric-strip` e `tl-work-queue`;
- `tl-score-bar` com faixas 0-10;
- `tl-signal-chip`, `tl-penalty-chip`, `tl-incidence-pill`;
- `tl-row-selected`, `tl-row-reviewed`, `tl-row-warning`;
- `tl-history-rail`, `tl-evidence-panel`, `tl-decision-panel`.

## Paleta funcional

- Verde: selecionado, OK, revisado, score forte.
- Vermelho: divergencia, penalidade, erro, bloqueio.
- Ambar: ambiguidade, revisao pendente, score medio.
- Azul/ciano: fonte, evidencia, informacao tecnica e drill-down.
- Neutro/slate: superficies, tabelas e texto secundario.
- Cobre: acento de marca, nao cor dominante.

## Navegacao

Menu lateral alvo:

```text
Painel

Laboratorio
  Casos
  Simulacoes
  Radar de Rubricas

Eventos
  S-1010
    Pontuacao S-1010
    Rubricas + Natureza

Configuracoes
  Parametros
  Premissas
```

Rotas existentes serao preservadas.

## Validacoes planejadas

- `ruby bin/rails test`
- `ruby bin/rails tailwindcss:build`
- `ruby bin/rails zeitwerk:check`
- verificacao HTTP local das rotas principais se houver servidor ativo.

## Limites

- Nao consultar eSocial.
- Nao baixar eventos.
- Nao alterar scoring, calculadoras, importacao ou regras fiscais.
- Nao calcular credito financeiro.
- Nao migrar para React/Next nem adicionar dependencias frontend.