# FRONTEND 002 - Guia para agentes que mexerem na interface

Data: 2026-05-29

## Objetivo

Este guia define como agentes devem trabalhar na interface do TributaLab. Ele foi baseado na pesquisa em repositorios de agentes e sistemas de front-end no GitHub.

## Regras de trabalho

1. Ler o contexto atual antes de editar views.
2. Preservar Rails, ERB, Hotwire/Stimulus e Tailwind existentes.
3. Nao introduzir Docker para front-end.
4. Nao adicionar React, Next, Vue ou biblioteca pesada sem pedido explicito.
5. Nao usar emojis na interface nem nos documentos de entrega visual.
6. Criar telas reais do produto, nao landing page.
7. Manter o foco em Reforma Tributaria Imobiliaria e simulacoes auditaveis.
8. Validar a interface em desktop e mobile.
9. Rodar testes depois de editar controllers/views/helpers/JS.
10. Se criar padrao visual, reaproveitar em varias telas.

## Checklist antes de implementar

- O objetivo da tela esta claro?
- Existe acao primaria evidente?
- A navegacao global continua previsivel?
- O usuario consegue escanear valores, alertas e status rapidamente?
- Campos possuem label visivel?
- Botoes dizem exatamente o que fazem?
- Tabelas funcionam em mobile com rolagem horizontal?
- O foco por teclado aparece?
- Cores de status nao dependem apenas da cor?
- O texto cabe em botoes, cards e tabelas?

## Padroes recomendados

### App shell

- Layout com faixa lateral ou topo persistente.
- Marca TributaLab sempre visivel.
- Navegacao para: Painel, Simulacoes, Casos, Parametros, Assumptions.
- Acao primaria: Nova simulacao.

### Pagina de dashboard

- Cabecalho com contexto do modulo e versao de regra.
- Cards de metricas no topo.
- Atalhos operacionais bem visiveis.
- Area de alertas separada de area de operacoes.
- Listas recentes com links diretos.

### Formularios

- Dividir em blocos de decisao: identificacao, operacao, entradas, contexto.
- Usar labels sempre visiveis.
- Deixar campos condicionais sem deslocar a pagina de forma confusa.
- Mostrar parametros e alertas ao lado quando a tela permitir.

### Tabelas

- Cabecalho com filtros antes da tabela.
- Status como badge textual.
- Numeros com alinhamento consistente.
- Link de detalhe claro.
- Estado vazio bem escrito e sem excesso de explicacao.

### Acessibilidade

- Contraste AA como meta minima.
- Foco visivel em links, botoes, inputs e selects.
- Ordem de tab coerente.
- Campos com label e `id` consistente.
- Nao esconder informacao critica apenas em hover.

## Anti-padroes

- Hero grande com texto promocional.
- Cards dentro de cards.
- Gradientes decorativos dominando a tela.
- Interface toda em uma cor so.
- Texto gigante em painel compacto.
- Icone sem label acessivel quando o significado nao for obvio.
- Botao com texto quebrando de forma feia.
- Status apenas por cor.
- Copiar exemplos React literalmente para ERB.

## Criterios de aceite para a primeira versao bonita

1. O app abre em `/` com cara de sistema operacional real.
2. A navegacao entre telas principais fica clara.
3. Dashboard, listagem e formulario compartilham a mesma linguagem visual.
4. As telas continuam carregando dados reais do Rails.
5. A interface funciona em largura mobile e desktop.
6. Testes Rails continuam passando.
7. Sem emojis.