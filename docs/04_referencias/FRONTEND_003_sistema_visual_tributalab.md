# FRONTEND 003 - Sistema visual inicial do TributaLab

Data: 2026-05-29

## Direcao visual

O TributaLab deve parecer uma plataforma profissional de simulacao e revisao tributaria. A experiencia precisa transmitir precisao, auditoria, rastreabilidade e velocidade operacional.

Nao deve parecer site institucional, landing page, app generico de cards coloridos ou dashboard financeiro aleatorio.

## Personalidade visual

- Densa, mas organizada.
- Serena, mas nao apagada.
- Tecnica, mas legivel para usuario de negocio.
- Moderna, mas sem excesso decorativo.
- Forte em tabelas, estados, comparacao e revisao.

## Paleta inicial

| Uso | Classe base sugerida | Observacao |
|---|---|---|
| Fundo geral | `bg-slate-950` ou `bg-zinc-950` em shell escuro, `bg-zinc-50` em areas claras | Usar contraste para dar presenca ao app |
| Superficie principal | `bg-white` | Conteudo operacional limpo |
| Superficie secundaria | `bg-zinc-50`, `bg-slate-50` | Blocos internos e headers |
| Texto principal | `text-zinc-950` | Alta legibilidade |
| Texto secundario | `text-zinc-500`, `text-zinc-600` | Metadados e descricoes |
| Acento | `teal`, `emerald` | Marca e links principais |
| Pendencia | `amber` | Assumptions e validacao pendente |
| Erro | `red` | Apenas erro real |
| Sucesso | `emerald` | Validado, ativo, concluido |

## Tipografia

- Titulo de pagina: `text-2xl` ou `text-3xl`, peso `font-semibold`.
- Titulo de card: `text-sm` ou `text-base`, peso `font-semibold`.
- Numeros importantes: `text-2xl`, `font-semibold`, `tabular-nums` quando fizer sentido.
- Texto auxiliar: `text-sm`, `leading-6`.
- Evitar letter spacing negativo.
- Usar uppercase apenas em labels pequenas e badges.

## Layout base

### Shell

- Sidebar escura no desktop com navegacao principal.
- Topbar no mobile ou layout que empilhe sem quebrar.
- Conteudo em `max-w-7xl` ou area fluida controlada.
- Acoes primarias no cabecalho de pagina.

### Dashboard

- Primeiro bloco: resumo do modulo e acao de nova simulacao.
- Segundo bloco: metricas principais.
- Terceiro bloco: operacoes, alertas e casos recentes.
- Quarto bloco: parametros e categorias.

### Nova simulacao

- Layout em duas colunas no desktop.
- Coluna principal: formulario.
- Coluna lateral: parametros, assumptions e alertas da operacao selecionada.
- Mobile: tudo empilhado na ordem de decisao.

### Listagem

- Filtros em painel compacto.
- Tabela com bordas leves, header destacado e valores numericos bem formatados.
- Estado vazio com CTA direto para nova simulacao.

## Componentes locais sugeridos

Mesmo sem criar uma biblioteca formal agora, as classes devem convergir para estes padroes:

- `app-shell`: estrutura global da aplicacao.
- `page-header`: titulo, subtitulo, metadados e acoes.
- `metric-card`: indicador numerico com label e nota.
- `status-badge`: estado textual com cor semantica.
- `data-panel`: painel de dados com header e conteudo.
- `action-link`: link/botao consistente para navegacao.
- `form-section`: bloco de campos com titulo e descricao curta.
- `table-shell`: wrapper de tabela com rolagem horizontal.

## Detalhes visuais importantes

- Borda maxima recomendada: `rounded-lg`; usar `rounded-md` em botoes e inputs.
- Evitar sombras grandes; preferir borda + sombra sutil.
- Usar `ring-1 ring-zinc-200` ou `border border-zinc-200` para superficies.
- Dar respiro com `gap-4`, `gap-5`, `gap-6`, sem exagerar.
- Usar `tabular-nums` em contadores e dinheiro.
- Separar alerta de erro: pendencia de regra nao e erro de sistema.

## Nao fazer

- Nao usar emojis.
- Nao usar landing page.
- Nao criar mascote, ilustracao decorativa ou orb/blur ornamental.
- Nao transformar tudo em cards soltos.
- Nao esconder operacoes importantes em menu secundario.
- Nao usar texto explicando a propria interface dentro da interface.