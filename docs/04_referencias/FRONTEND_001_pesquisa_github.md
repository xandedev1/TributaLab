# FRONTEND 001 - Pesquisa GitHub para interface do TributaLab

Data: 2026-05-29

## Objetivo

Registrar referencias praticas encontradas em repositorios do GitHub antes de redesenhar a interface basica do TributaLab.

O foco da pesquisa foi: dashboards operacionais, formularios, tabelas, navegacao, acessibilidade, sistemas de design e instrucoes para agentes de front-end.

## Repositorios consultados

| Repositorio | Uso na pesquisa | O que aproveitar |
|---|---|---|
| `shadcn-ui/ui` | Componentes, dashboards, formularios e regras de composicao | Estrutura de Card completa, dashboards com cards + tabelas + areas de detalhe, composicao em vez de inventar componentes isolados |
| `microsoft/skills` | Instrucoes para agentes, criterios de aceite, skill de frontend e validacao visual | Trabalhar com criterios claros, validar acessibilidade, manter documentos acionaveis e separar referencias extensas |
| `tailwindlabs/headlessui` | Comportamento acessivel de Dialog, Tabs, Menu e foco por teclado | Garantir foco visivel, navegacao por teclado e estrutura semantica em interacoes futuras |
| `tremorlabs/tremor` | Dashboard, tabelas, badges, cards, callouts e metricas | Tabelas densas com rolagem horizontal, badges semanticos, cards de metricas e layouts voltados a dados |
| `primer/primer.style` | Design system do GitHub, acessibilidade e ViewComponents/Rails | Consistencia, acessibilidade como parte do sistema e componentes reusableis para Rails |

## Principais achados

1. A interface deve parecer ferramenta operacional, nao landing page.
2. Dashboards bons combinam resumo, acao primaria, lista/tabela e contexto de validacao.
3. Cards devem ter cabecalho, descricao, conteudo e acao quando necessario; jogar tudo em um bloco unico enfraquece a hierarquia.
4. Tabelas precisam de rolagem horizontal em telas pequenas, cabecalhos claros e status visual legivel.
5. Formularios grandes devem ser divididos por contexto: identificacao, operacao, entradas, parametros e alertas.
6. Acessibilidade deve ser tratada no layout inicial: labels, foco visivel, contraste, ordem de tab e textos de acao claros.
7. Paleta deve ser sobria e variada, sem depender de um unico tom. Para o TributaLab, verde/teal pode ser acento, mas a base deve ser neutra, com amarelo para pendencias e vermelho apenas para erro.
8. O app precisa de um shell consistente: topo ou sidebar, navegacao global, area principal e acao primaria fixa por pagina.
9. Agentes bons produzem melhor quando o objetivo, os limites e a checklist ficam salvos antes de implementar.
10. Nao usar emojis como elemento visual. Para status, usar texto, cor, borda e icones simples quando houver biblioteca disponivel.

## Decisoes para o TributaLab

- Manter Rails + ERB + Tailwind, sem adicionar framework front-end grande agora.
- Criar um visual de produto SaaS operacional: denso, claro, elegante, com foco em revisao tributaria.
- Priorizar primeiro: layout global, dashboard, lista de simulacoes, tela nova simulacao e detalhe da simulacao.
- Usar componentes locais via classes/helper, nao instalar biblioteca nova sem necessidade.
- Evitar hero marketing. A primeira tela deve ser o painel real do sistema.

## Fontes internas dos repositorios

- `shadcn-ui/ui`: `skills/shadcn/SKILL.md`, `skills/shadcn/rules/composition.md`, exemplos `dashboard-01`, `card`, `form`, `tabs`.
- `microsoft/skills`: `Agents.md`, `tests/scenarios/frontend-ui-dark-ts/acceptance-criteria.md`, testes de acessibilidade do docs-site.
- `tailwindlabs/headlessui`: testes de `dialog`, `menu` e `tabs` para foco, teclado e ARIA.
- `tremorlabs/tremor`: componentes `Card`, `Table`, `Badge`, `Tabs`, `Callout`, `ProgressBar`, `SparkChart`.
- `primer/primer.style`: paginas de status de componentes, referencias a ViewComponents/Rails e principios de design system/acessibilidade.