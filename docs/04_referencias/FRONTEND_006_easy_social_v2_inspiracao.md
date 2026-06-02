# FRONTEND 006 - Inspiracao Easy Social V2

Data: 2026-05-29

## Fonte local consultada

Projeto de referencia no computador do usuario:

`C:\Users\xandao\Documents\GitHub\Easy-Social-V2`

Arquivos principais lidos:

- `README.md`
- `src/styles/tokens.css`
- `src/styles/main.css`
- `src/styles/data-table.css`
- `src/layouts/AppLayout.vue`
- `src/views/PainelView.vue`
- `src/components/base/AppBackground.vue`
- `src/components/base/BrainStage.vue`

## Conceitos aproveitados

- Fundo escuro profundo como base do produto.
- Vidro liquido com blur, borda fina e brilho interno.
- Estrutura de luz operacional, substituida no TributaLab pela cor Caramel `#C87740`.
- Contraste de bordas e highlights, substituido no TributaLab por tons derivados de Caramel.
- Painel principal com sensacao de nucleo operacional.
- Tabelas densas com cabecalho mono, hover discreto e badges de status.
- Microinteracoes leves com respeito a `prefers-reduced-motion`.

## Adaptacao para TributaLab

O TributaLab nao copiou assets do Easy Social V2. A adaptacao criou uma linguagem propria chamada internamente de Liquid Ledger:

- Palco visual fiscal em SVG no dashboard.
- Cards glass para metricas e paineis principais.
- Tiles internos leves para evitar cards dentro de cards.
- Botoes, badges, inputs e tabelas no mesmo sistema visual.
- Sidebar e mobile header escuros, com marca TL e sinal de ambiente local.
- Paleta final escolhida pelo usuario: Raisin `#2E1F26` como base escura e Caramel `#C87740` como cor principal.

## Restricoes mantidas

- Sem Docker.
- Sem emojis.
- Sem React, Vue ou Next adicionados ao TributaLab.
- Mantido Rails ERB, Hotwire/Stimulus e Tailwind Rails.
- Nenhum asset privado do Easy Social V2 foi copiado.