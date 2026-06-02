# FRONTEND 007 - Pesquisa anti cara de IA

Data: 2026-05-29

## Objetivo

Registrar uma pesquisa para tirar o TributaLab do visual com cara de interface gerada por IA e orientar uma proxima rodada de design mais autoral, operacional e disruptiva.

O feedback do usuario foi direto: a interface esta bonita, mas ainda parece IA. A resposta correta nao e adicionar mais brilho. E trocar a logica visual: menos template generico, mais produto fiscal real.

## Diagnostico do problema atual

A interface atual tem pontos bons: paleta escolhida, consistencia, responsividade, rotas funcionando e uma base visual unificada. O problema e que alguns sinais lembram demais dashboards gerados automaticamente:

- Excesso de glass, glow e gradientes como solucao principal de estetica.
- Muitos cards parecidos, todos com peso visual semelhante.
- Hero/dashboard com composicao muito centralizada e "bonita demais" para uma ferramenta fiscal.
- Pouca presenca de artefatos reais do dominio: calculo, memoria fiscal, versao de regra, trilha de auditoria, parametro legal, demonstrativo.
- Visual ainda mais decorativo do que operacional.
- Falta de atrito bom: linhas duras, tabelas densas, comparacao, detalhe tecnico e hierarquia de trabalho.

A direcao deve ser: TributaLab nao e uma landing page. E uma mesa de simulacao fiscal.

## Pesquisa web

### Awwwards - Experimental

Fonte: `https://www.awwwards.com/websites/experimental/`

A curadoria de sites experimentais destaca layouts nao convencionais, interacoes que desafiam padroes tradicionais, data visualization, UX preditiva e experiencias com tecnologias como WebGL, gestos, voz, VR/AR/MR e AI.

Aplicacao para TributaLab:

- Usar visualizacao fiscal como interface de trabalho, nao como decoracao.
- Criar uma tela em que o usuario veja fluxo de base de calculo, redutores, credito e imposto como objetos manipulaveis.
- Experimentar composicao assimetrica e paineis com comportamento proprio.
- Evitar hero generico; transformar o dashboard em instrumento.

### Awwwards - Brutalism

Fonte: `https://www.awwwards.com/websites/brutalism/`

Brutalismo aparece como fuga do polimento previsivel: bordas duras, grids aparentes, contraste, tipografia forte, elementos menos "fofos" e mais memoraveis.

Aplicacao para TributaLab:

- Manter Raisin e Caramel, mas reduzir o aspecto neon.
- Usar divisorias fortes, linhas tecnicas, numeros grandes e tabelas com presenca.
- Aceitar uma interface mais seca e proprietaria, sem parecer template SaaS.
- Usar brutalismo com controle, porque o dominio fiscal exige confianca.

### Framer Gallery - Grid e Large Type

Fontes:

- `https://www.framer.com/gallery/styles/grid`
- `https://www.framer.com/gallery/styles/large-type`

A galeria mostra que grids nao precisam ser apenas organizacao invisivel: eles viram parte da identidade. Large type tambem e usado para criar identidade, nao so chamar atencao.

Aplicacao para TributaLab:

- Criar um grid fiscal visivel, quase como planilha de auditoria.
- Usar tipografia grande apenas para valores decisivos: carga total, delta, risco, versao da regra.
- Evitar H1 hero enorme em telas de trabalho.
- Fazer o grid parecer instrumento de calculo, nao mosaico de cards.

### Framer State of Sites 2026

Fonte: `https://www.framer.com/state-of-sites-2026/`

O relatorio aponta que criar site ficou facil, mas operar e manter ficou mais dificil. Destaca que grande parte do trabalho vira edicao, manutencao, conversao e iteracao; velocidade de iteracao e vantagem.

Aplicacao para TributaLab:

- O design precisa ser facil de evoluir em Rails/ERB/Tailwind.
- Nao adianta uma tela linda se cada nova operacao tributaria exigir refazer layout.
- Construir sistema visual com componentes e padroes reaproveitaveis.
- Priorizar telas que aceitam novas regras, parametros e operacoes sem quebrar.

### Linear

Fontes:

- `https://linear.app`
- `https://linear.app/method`
- `https://linear.app/quality`

Linear foge da cara generica porque mostra produto real: listas densas, issues, diffs, pulse, roadmaps, agentes, atividade. A qualidade vem da especificidade do fluxo, nao de decoracao. O Method fala de foco, direcao, momentum e qualidade percebida.

Aplicacao para TributaLab:

- Mostrar operacoes reais e estados reais, nao cards abstratos.
- Transformar simulacao em fluxo de trabalho com etapas visiveis.
- Criar uma tela de auditoria que pareca revisavel por humano.
- Fazer a interface parecer rapida e precisa.

### Resend

Fonte: `https://www.resend.com`

Resend usa screenshots reais, logs, eventos, SDKs e exemplos de API para dar credibilidade. A beleza vem do produto funcionando, nao de um fundo bonito.

Aplicacao para TributaLab:

- Mostrar memoria de calculo real.
- Mostrar parametros, versao normativa e snapshots usados.
- Mostrar outputs como artefatos: demonstrativo, JSON, alerta, trilha.
- Usar codigos, logs e eventos fiscais como materia visual.

## Pesquisa GitHub

### Maybe Finance

Repo: `https://github.com/maybe-finance/maybe`

Pontos observados:

- Rails com Hotwire, Stimulus, ViewComponents e Tailwind.
- Design system com tokens funcionais, por exemplo `text-primary`, `bg-container`, `shadow-border-xs`.
- Dashboard financeiro baseado em balance sheet, cashflow sankey, grupos expansivos e reconciliacao.
- Menos dependencia de brilho; mais dependencia de dado, tabela, disclosure, grafico e money formatting.
- Componentes de reconciliacao exibem linha de raciocinio: saldo inicial, fluxo, ajustes, saldo final.

Licoes para TributaLab:

- Criar tokens semanticos, nao classes decorativas demais.
- Tratar simulacao tributaria como reconciliacao: base inicial, deducoes, reducoes, creditos, imposto final.
- Usar detalhes expansivos com tooltips para explicar regra e fonte.
- Usar grafico apenas quando ele explica dinheiro, nao como ornamento.

### Actual Budget

Repo: `https://github.com/actualbudget/actual`

Pontos observados:

- A interface principal e uma tabela de orcamento, quase planilha.
- Separacao real entre wide e narrow layouts.
- Uso forte de transaction list, budget table, reports, sankey, calendar e formulas.
- O produto aceita densidade; nao tenta converter tudo em cards.
- Tem controles para colapsar grupos, mostrar colunas e navegar meses.

Licoes para TributaLab:

- A tela mais importante pode ser uma tabela/calculadora, nao um dashboard.
- Criar visual de planilha fiscal premium.
- Desktop deve ser denso; mobile deve virar fluxo guiado.
- Permitir comparacao de cenarios lado a lado.

### DocuSeal

Repo: `https://github.com/docusealco/docuseal`

Pontos observados:

- Rails com telas de documentos, templates, upload, dropzone, assinatura e audit trail.
- Dashboard usa alternancia entre templates e submissions.
- Template builder tem lista de documentos, preview central, campos e controles.
- Fluxo e altamente especifico do dominio: documento, assinatura, campos, envio, auditoria.

Licoes para TributaLab:

- Criar uma tela tipo "dossie fiscal" para cada simulacao.
- Usar preview de demonstrativo/auditoria como artefato central.
- Incluir trilha de auditoria visual: regra usada, parametro, input, output, alerta.
- Pensar em cada simulacao como um documento revisavel.

### Chatwoot

Repo: `https://github.com/chatwoot/chatwoot`

Pontos observados:

- Interface operacional com lista, detalhe, filtros, estados, conversa e painel lateral.
- Filtros sao ricos: status, assignee, inbox, team, labels, datas e atributos customizados.
- Layout pode alternar entre modos condensado e expandido.
- Produto e reconhecivel porque o fluxo de trabalho e especifico.

Licoes para TributaLab:

- Criar filtros fiscais reais: operacao, status, regra, periodo, alerta, caso interno.
- Usar layout de 3 regioes: lista/casos, area de calculo, painel de contexto.
- Permitir modo compacto e modo expandido.
- Dar peso a estados operacionais, nao so metricas soltas.

### Outros repos relevantes

Repos consultados por metadados e posicionamento:

- `https://github.com/twentyhq/twenty` - CRM open source com produto denso e modelagem de objetos.
- `https://github.com/dubinc/dub` - plataforma de atribuicao com foco em produto real, tracking e analytics.
- `https://github.com/makeplane/plane` - alternativa open source a Jira/Linear, boa referencia de workflows.
- `https://github.com/triggerdotdev/trigger.dev` - workflows e jobs, bom para pensar em execucoes e logs.

Licao geral: produtos fortes ficam menos genericos quando a tela nasce do modelo mental do dominio.

## Como fugir da cara de IA

### O que cortar

- Gradientes como protagonista.
- Cards iguais em todo lugar.
- Brilho decorativo sem funcao.
- Hero text grande demais dentro de ferramenta operacional.
- Icones e textos genericos tipo "performance", "insights", "controle total" sem artefato real.
- Paletas muito previsiveis de SaaS futurista.

### O que adicionar

- Artefatos fiscais reais: memoria de calculo, demonstrativo, regra, parametro, versao, alerta, snapshot.
- Layout assimetrico com prioridade clara.
- Densidade controlada: tabelas, linhas, divisorias, paineis de contexto.
- Tipografia numerica forte para dinheiro, aliquota e delta.
- Interacoes de trabalho: expandir formula, comparar cenarios, fixar parametro, abrir justificativa.
- Linguagem visual de calculadora fiscal, livro razao, cartorio, documento tecnico e terminal premium.

## Direcoes visuais possiveis para TributaLab

### 1. Fiscal Workbench

Mesa de trabalho fiscal, com tres regioes:

- Esquerda: operacoes e casos internos.
- Centro: simulacao ativa com memoria de calculo em blocos sequenciais.
- Direita: regra, parametros, alertas e snapshot.

Por que funciona:

- Parece ferramenta profissional.
- Usa a arquitetura atual do Rails sem exigir novo framework.
- Tira o foco de card decorativo e coloca em fluxo de trabalho.

### 2. Dossie Fiscal

Cada simulacao vira um dossie revisavel:

- Capa com operacao, periodo e status.
- Secao de inputs.
- Secao de calculo.
- Secao de alertas.
- Secao de evidencias e snapshots.

Por que funciona:

- Combina com tributario.
- Gera confianca.
- Facilita futura exportacao PDF.

### 3. Calculation Tape

Interface inspirada em fita de calculadora e livro razao:

- Valores descem em uma linha do tempo vertical.
- Cada deducao/reducao/credito aparece como operacao.
- O resultado final fecha como total de caixa.

Por que funciona:

- E visualmente diferente.
- Faz sentido para memoria de calculo.
- Evita dashboard generico.

### 4. Brutalismo Fiscal Controlado

Visual mais seco e marcante:

- Raisin como massa escura solida.
- Caramel como marcador de acao e estado.
- Bordas retas, grid aparente, pouco blur.
- Tipografia mono para valores e codigos.

Por que funciona:

- Foge da estetica "AI glass dashboard".
- Continua serio.
- Pode ser implementado com CSS atual.

### 5. Mapa de Regras

Tela que mostra relacao entre:

- Produto imobiliario.
- Setor.
- Modulo fiscal.
- Operacao.
- Versao de regra.
- Parametros.
- Resultado.

Por que funciona:

- Transforma a arquitetura do sistema em interface.
- E especifico do TributaLab.
- Ajuda usuario a entender de onde veio o calculo.

## Recomendacao para a proxima rodada

Escolher uma combinacao:

- Base: Fiscal Workbench.
- Detalhe de simulacao: Dossie Fiscal.
- Memoria de calculo: Calculation Tape.
- Estetica: Brutalismo Fiscal Controlado.

Essa combinacao deve tirar o visual da zona "dashboard IA" sem virar bagunca experimental.

## Plano de implementacao sugerido

### Fase 1 - Remover o brilho generico

- Reduzir glass e glow global.
- Trocar cards repetidos por paineis, linhas e secoes.
- Usar Raisin mais solido e Caramel mais pontual.
- Diminuir decoracao de fundo.

### Fase 2 - Redesenhar dashboard como mesa de trabalho

- Dashboard deve abrir com simulacoes/casos/operacoes reais.
- Mostrar modulo fiscal como mapa operacional.
- Priorizar a acao "nova simulacao" e casos recentes.
- Menos hero, mais cockpit.

### Fase 3 - Redesenhar nova simulacao

- Formulario vira calculadora guiada.
- Inputs aparecem junto da regra aplicavel.
- Preview de resultado atualiza em estrutura de memoria fiscal.
- Layout desktop em 2 ou 3 colunas; mobile em etapas.

### Fase 4 - Redesenhar resultado como dossie

- Cabecalho com status e total.
- Calculation tape vertical.
- Tabela de parametros usados.
- Alertas com severidade real.
- Snapshots e JSON ficam em area tecnica colapsavel.

### Fase 5 - Validacao visual

- Rodar `ruby bin/rails test`.
- Rodar `ruby bin/rails zeitwerk:check`.
- Checar rotas principais.
- Fazer revisao visual manual em desktop e mobile.

## Restricoes para manter

- Sem Docker.
- Sem emojis.
- Sem React, Vue, Next ou framework novo no TributaLab.
- Manter Rails ERB, Hotwire/Stimulus e Tailwind Rails.
- Nao copiar assets privados de nenhum projeto.
- Usar referencias como aprendizado, nao como copia.

## Decisao recomendada

A proxima interface do TributaLab deve parar de tentar ser "futurista bonita" e passar a ser "ferramenta fiscal inevitavel".

A pergunta de design deve mudar de:

> Como deixo esse dashboard bonito?

Para:

> Como um tributarista confiaria nessa memoria de calculo em 10 segundos?

Essa pergunta deve guiar a proxima rodada de front-end.
