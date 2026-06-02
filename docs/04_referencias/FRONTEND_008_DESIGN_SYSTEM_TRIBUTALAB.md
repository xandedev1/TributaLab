# FRONTEND 008 - Design System TributaLab

Data: 2026-06-01
Projeto: TributaLab

## Proposito do produto

TributaLab e uma mesa operacional fiscal para consultores revisarem casos, simulacoes, regras, rubricas e adequacao eSocial. A interface deve favorecer decisao, rastreabilidade e leitura densa, sem virar landing page.

## Design read

B2B fiscal operations workbench for consultants reviewing tax rules, simulations and eSocial rubrics, with a quiet technical audit-room language, leaning toward dense product UI, Rails ERB/Tailwind components, restrained motion and high readability.

## Referencias

Impeccable foi usado como referencia primaria para documentacao de sistema visual, polish, audit, hardening, responsividade, contraste e anti-patterns como cards demais, monocromia e movimento gratuito.

Taste Skill foi usado como checklist de redesign de projeto existente: auditar antes, ajustar hierarquia, ritmo, tipografia, densidade e evitar UI generica de IA.

Langfuse inspira a ideia de trace auditavel: entrada, sinais, score, decisao e historico.

Dub inspira console operacional: metricas acionaveis, lista filtravel, detalhe e proximas acoes.

## Dials

- DESIGN_VARIANCE: 3/10.
- MOTION_INTENSITY: 1/10.
- VISUAL_DENSITY: 8/10.

## Paleta

Tokens funcionais:

- `--tl-success`: revisado, selecionado, incidencia OK, score forte.
- `--tl-danger`: divergencia, penalidade, erro, bloqueio.
- `--tl-warning`: ambiguidade, revisao pendente, score medio.
- `--tl-info`: fonte, evidencia, detalhe tecnico, link de drill-down.
- `--tl-surface`: superficies neutras e tabelas.
- `--tl-ghost`: acento cobre de marca.

O cobre e acento. Ele nao deve ser a cor dominante de todos os estados.

## Tipografia

Usar a pilha atual do sistema para compatibilidade Windows/Rails. Texto de dado e codigo usa monospace. Tabelas devem ter labels compactas e numeros tabulares.

## Componentes base

- `tl-page-header` ou `tl-command-bar`: cabecalho operacional da tela.
- `tl-filter-bar`: filtros densos, previsiveis e sempre proximos da lista.
- `tl-metric-strip`: metricas pequenas e conectadas a acao.
- `tl-table`: comparacao densa em desktop.
- `tl-score-bar`: score 0-10 com cor por faixa.
- `tl-evidence-panel`: fonte, hash, data e confianca.
- `tl-decision-panel`: area de decisao humana.
- `tl-history-rail`: historico compacto.
- `tl-empty`: estado vazio com proxima acao real.

## Tabelas e formularios

Desktop favorece tabela densa. Mobile/tablet deve permitir scroll horizontal ou blocos compactos sem comprimir formulario dentro de celula estreita.

Formulario dentro de tabela deve ser usado com parcimonia. Quando existir, precisa separar leitura, justificativa e acao.

## Estados

- Verde: selecionado, revisado, validado, forte.
- Ambar: pendente, revisar, ambiguo, medio.
- Vermelho: divergente, rejeitado, erro, penalidade forte.
- Azul/ciano: informacao, evidencia, fonte.
- Cinza: neutro, arquivado, sem natureza.

## Anti-patterns proibidos

- Hero marketing como tela principal operacional.
- Cards dentro de cards sem necessidade.
- Paleta inteira cobre/marrom.
- Chips iguais para sinais positivos e penalidades.
- Movimento perpetuo em tela de leitura tecnica.
- Texto explicativo longo substituindo hierarquia visual.
- Stack React/Next/JS nova sem aprovacao.

## Checklist de entrega visual

- Estados reconheciveis em 2 segundos.
- Score com barra e cor funcional.
- Filtros proximos da lista que controlam.
- Acoes primarias claras.
- Justificativa obrigatoria visualmente obvia quando editar incidencia.
- `prefers-reduced-motion` respeitado.
- Rotas existentes preservadas.