# ETAPA 004E - Rubricas CTE Produto Unico

Data: 2026-06-03
Branch: `004e-rubricas-cte-produto-unico`
Projeto: Prev Lab

## Objetivo

Consolidar a experiencia de Rubricas CTE em um produto unico, sem telas soltas competindo entre si.

A entrada oficial passou a ser:

```text
/rubricas_cte
```

## Mudancas feitas

- `/rubricas_cte` agora e a tela principal operacional.
- `/rubricas_cte/dashboard` foi mantida, mas redireciona para `/rubricas_cte`.
- Navegacao principal deixou de expor Laboratorio, Radar antigo, Pontuacao S-1010 antiga e Rubricas + Natureza antiga como caminhos de produto.
- A lista lateral virou fila de trabalho priorizada.
- O filtro padrao continua focado nas rubricas divergentes.
- A rubrica selecionada virou dossie, com status, pontuacao, vinculo S-1010 e natureza CTE.
- A pontuacao aparece apenas quando ha divergencia ativa.
- O bloco `Por que esta na fila` mostra os motivos da prioridade.
- A linha do tempo ganhou eixo visual horizontal com marcos conectados.
- O Chain Walk continua existindo, mas agora como componente dentro do produto Rubricas CTE.

## Pontuacao inicial

A pontuacao operacional desta etapa e deterministica e explicavel:

```text
Natureza divergente: +40
CP divergente:       +20
IRRF divergente:     +20
FGTS divergente:     +20
Mudanca historica:   +10
Teto:                100
```

A pontuacao nao calcula credito financeiro e nao representa valor a recuperar.

## Legenda operacional

A tela agora explica diretamente:

- `Sem vinculo`: a rubrica CTE ainda nao tem um unico `codRubr` S-1010 confirmado;
- `Divergente`: a fonte CTE esperava uma natureza/incidencia e o S-1010 local declarou outra;
- `Mudou no historico`: houve alteracao entre marcos S-1010, sem ser automaticamente erro;
- `00`: nao incide;
- `11`: incide/base mensal.

## Validacao executada

Testes focados:

```text
$env:DISABLE_BOOTSNAP='1'; $env:RAILS_ENV='test'; ruby bin/rails test test/controllers/rubricas_cte/dashboard_controller_test.rb test/controllers/rubricas_cte/chain_walk_controller_test.rb
2 runs, 46 assertions, 0 failures, 0 errors, 0 skips
```

CSS:

```text
$env:DISABLE_BOOTSNAP='1'; ruby bin/rails tailwindcss:build
Done in 1s
```

HTTP:

```text
GET /rubricas_cte
MAIN_STATUS=200
HAS_PRODUCT=True
HAS_QUEUE=True
HAS_DOSSIE=True
HAS_WHY=True
HAS_RAIL=True
HAS_OLD_LAB=False
HAS_OLD_PONTUACAO=False

GET /rubricas_cte/dashboard
LEGACY_STATUS=302
LEGACY_LOCATION=http://127.0.0.1:3000/rubricas_cte

GET /rubricas_cte?q=0003
STATUS=200
HAS_0003=True
HAS_TRANSLATED_11=True
HAS_CONFLICT=True
HAS_DOSSIE=True
HAS_RAIL=True
```

Diagnostics dos arquivos alterados: sem erros.

## Fora de escopo mantido

Nao foi feito:

- consulta ao eSocial;
- Download Cirurgico;
- calculo financeiro de credito;
- exclusao fisica das telas antigas;
- revisao manual persistida com justificativa.

## Proxima etapa

A proxima etapa deve transformar `Sem vinculo` em uma fila operacional de confirmacao manual, com candidatos, escolha do vinculo e historico de justificativa.