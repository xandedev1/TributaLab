# FRONTEND 004 - Plano da primeira interface bonita

Data: 2026-05-29

## Objetivo

Montar uma primeira interface bonita e navegavel do TributaLab para visualizar o produto funcionando, sem mudar a arquitetura tributaria e sem criar dependencias grandes.

## Escopo da primeira rodada

1. Criar shell global no layout da aplicacao.
2. Redesenhar dashboard inicial.
3. Melhorar listagem de simulacoes.
4. Melhorar formulario de nova simulacao.
5. Melhorar detalhe de simulacao se couber no mesmo ciclo.
6. Preservar telas de casos, parametros e assumptions com o novo shell.

## Fora de escopo agora

- Login/autenticacao.
- Cadastro real de clientes/empresas.
- Graficos com biblioteca externa.
- React/Next/Vue.
- Docker.
- Redesenho da modelagem tributaria.

## Sequencia de implementacao

1. Ajustar `app/views/layouts/application.html.erb` para app shell.
2. Criar helpers de navegacao/status se reduzirem repeticao.
3. Atualizar `app/views/dashboard/index.html.erb` com cards de metricas, operacoes, alertas e casos.
4. Atualizar `app/views/simulations/index.html.erb` com filtros e tabela mais forte.
5. Atualizar `app/views/simulations/new.html.erb` mantendo Stimulus atual.
6. Atualizar CSS global se necessario para foco, scrollbar e padroes pequenos.
7. Rodar testes e validar HTTP.

## Criterios de aceite

- `/` abre com visual de produto real.
- `/simulations`, `/simulations/new`, `/case_files`, `/tax_parameters`, `/assumptions` mantem navegacao global.
- Botoes, links, inputs e selects tem foco visivel.
- Tabelas nao estouram no mobile.
- Sem emojis.
- Sem Docker.
- Testes Rails passam.
- Servidor local fica disponivel para visualizacao.

## Riscos

| Risco | Mitigacao |
|---|---|
| Views ERB ficarem repetitivas | Criar helpers pequenos apenas se necessario |
| Tailwind build nao atualizar | Rodar o comando de build/teste que ja atualiza `app/assets/builds/tailwind.css` |
| Mudanca visual quebrar testes de texto | Preservar textos essenciais que testes esperam |
| Excesso de ornamentacao | Manter direcao operacional e revisar mobile |

## Observacao

Esta rodada e para visualizacao do produto. A prioridade e dar forma boa ao que ja existe, nao ampliar escopo funcional.