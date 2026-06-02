# FRONTEND 005 - Checklist de QA visual

Data: 2026-05-29

## Checklist geral

- Sem emojis.
- Sem landing page.
- Navegacao principal visivel.
- Acao primaria clara por pagina.
- Texto nao sobrepoe outro texto.
- Texto cabe em botoes e badges.
- Cores de status tem texto junto.
- Foco por teclado visivel.
- Contraste suficiente em texto e botoes.
- Mobile nao quebra layout.
- Tabelas tem rolagem horizontal quando necessario.
- Formularios possuem labels visiveis.
- Estados vazios orientam a proxima acao.

## Dashboard

- Mostra modulo/setor/versao de regra.
- Mostra numero de operacoes.
- Mostra simulacoes/casos/pendencias.
- Tem link direto para nova simulacao.
- Alertas aparecem como pendencias, nao como erro fatal.

## Simulacoes

- Filtros continuam funcionando.
- Tabela mostra data, nome, operacao, regra, valor principal, imposto e alertas.
- Link de abrir esta claro.
- Estado vazio tem CTA para nova simulacao.

## Nova simulacao

- Selecionar operacao troca campos corretos.
- Campos ocultos nao atrapalham submissao.
- Parametros e alertas da operacao ficam visiveis.
- Botao principal diz que calcula e salva.

## Detalhe

- Resultado estimado aparece acima dos detalhes tecnicos.
- Entradas, parametros, assumptions, alertas e bases legais ficam separados.
- Snapshots continuam legiveis.

## Validacao tecnica

- `ruby bin/rails test`
- `ruby bin/rails zeitwerk:check`
- HTTP 200 em `/`, `/simulations`, `/simulations/new`, `/case_files`, `/tax_parameters`, `/assumptions`