# FRONTEND 002 - Segunda rodada visual inspirada no Easy Social V2

Data: 2026-05-29

## Resumo

Foi feita uma segunda rodada de front-end no TributaLab, usando o projeto local Easy Social V2 como referencia estetica. A adaptacao criou uma linguagem propria para o TributaLab chamada internamente de Liquid Ledger.

O servidor local esta disponivel em:

`http://127.0.0.1:3000`

## Referencia consultada

Projeto local:

`C:\Users\xandao\Documents\GitHub\Easy-Social-V2`

Documento de referencia criado:

- `docs/04_referencias/FRONTEND_006_easy_social_v2_inspiracao.md`

## Direcao visual aplicada

- Fundo escuro profundo.
- Vidro liquido com blur, bordas finas e highlights internos.
- Na entrega original, a referencia usava uma paleta experimental como ponto de partida visual.
- Na decisao final de paleta, essas cores foram substituidas por Raisin `#2E1F26` e Caramel `#C87740`.
- Cards principais com efeito glass.
- Tiles internos leves para evitar cards dentro de cards.
- Tabelas densas, escuras e mais operacionais.
- Inputs, botoes, badges e nav no mesmo sistema visual.

## Telas refinadas

- Layout global com sidebar e header mobile.
- Dashboard principal com palco Liquid Ledger em SVG.
- Listagem de simulacoes.
- Formulario de nova simulacao.
- Detalhe de resultado de simulacao.
- Casos internos: lista, detalhe e novo caso.
- Parametros.
- Assumptions.

## Arquivos principais alterados nesta rodada

- `app/assets/tailwind/application.css`
- `app/assets/builds/tailwind.css`
- `app/helpers/application_helper.rb`
- `app/views/layouts/application.html.erb`
- `app/views/dashboard/index.html.erb`
- `app/views/simulations/index.html.erb`
- `app/views/simulations/new.html.erb`
- `app/views/simulations/show.html.erb`
- `app/views/case_files/index.html.erb`
- `app/views/case_files/show.html.erb`
- `app/views/case_files/new.html.erb`
- `app/views/tax_parameters/index.html.erb`
- `app/views/assumptions/index.html.erb`

## Validacao executada

- `ruby bin/rails test`
  - `35 runs, 175 assertions, 0 failures, 0 errors, 0 skips`
- `ruby bin/rails zeitwerk:check`
  - `All is good!`
- `get_errors`
  - Sem problemas encontrados.
- HTTP local em `127.0.0.1:3000`
  - `/` status 200
  - `/simulations` status 200
  - `/simulations/new` status 200
  - `/case_files` status 200
  - `/case_files/new` status 200
  - `/tax_parameters` status 200
  - `/assumptions` status 200

## Restricoes mantidas

- Nao foi usado Docker.
- Nao foram usados emojis.
- Nao foi copiado asset privado do Easy Social V2.
- Nao foi adicionado React, Vue, Next ou biblioteca front-end pesada ao TributaLab.
- Mantido Rails ERB, Hotwire/Stimulus e Tailwind Rails.

## Observacao de workspace

O arquivo `log/development.log` pode aparecer modificado no `git status` enquanto o servidor Rails estiver ativo no Windows, porque o processo mantem o arquivo aberto. O cache do Bootsnap foi limpo.