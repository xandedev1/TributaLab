# FRONTEND 003 - Paleta Raisin e Caramel

Data: 2026-05-29

## Resumo

A paleta base do TributaLab foi atualizada conforme a escolha do usuario a partir da imagem enviada:

- Raisin `#2E1F26` como base escura principal do sistema.
- Caramel `#C87740` como cor de acento, foco, brilho operacional e destaque.

A estrutura visual Liquid Ledger foi mantida. A mudanca foi aplicada como troca de paleta, sem alterar arquitetura, rotas, modelos ou fluxo de simulacao.

## Arquivos alterados

- `app/assets/tailwind/application.css`
- `app/assets/stylesheets/application.css`
- `app/views/pwa/manifest.json.erb`
- `docs/04_referencias/FRONTEND_006_easy_social_v2_inspiracao.md`
- `docs/03_comunicacao/FRONTEND_002_RESPOSTA.md`
- `docs/03_comunicacao/FRONTEND_003_RESPOSTA.md`

## Decisao visual

- Fundo e paineis usam Raisin e derivados escuros.
- Botoes principais, foco, selecao, linhas de energia e estados ativos usam Caramel.
- Highlights secundarios usam tons quentes derivados de Caramel para manter contraste sem voltar ao verde anterior.
- Os nomes internos de algumas classes e variaveis antigas foram preservados por compatibilidade, mas seus valores agora apontam para a nova paleta.

## Restricoes mantidas

- Sem Docker.
- Sem emojis.
- Sem framework front-end novo.
- Mantido Rails ERB, Hotwire/Stimulus e Tailwind Rails.
- Nenhum asset privado do Easy Social V2 foi copiado.

## Validacao executada

- `ruby bin/rails test`
	- `35 runs, 175 assertions, 0 failures, 0 errors, 0 skips`
- `ruby bin/rails zeitwerk:check`
	- `All is good!`
- HTTP local em `127.0.0.1:3000`
	- `/` status 200
	- `/simulations` status 200
	- `/simulations/new` status 200
	- `/case_files` status 200
	- `/case_files/new` status 200
	- `/tax_parameters` status 200
	- `/assumptions` status 200
- `get_errors`
	- Sem problemas encontrados.
