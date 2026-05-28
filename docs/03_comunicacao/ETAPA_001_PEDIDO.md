# ETAPA 001 - Pedido

## Objetivo

Criar o esqueleto tecnico do TributaLab em Ruby on Rails com PostgreSQL, documentacao de coordenacao, modelagem conceitual inicial e seeds do modulo Reforma Tributaria Imobiliaria.

## Contexto

O TributaLab nasce como plataforma de inteligencia tributaria operacional. O primeiro recorte pratico e Reforma Tributaria > Imobiliario / Construcao Civil, com base na call com Denis e na planilha-base recebida em 2026-05-28.

## Escopo

- Criar app Rails full-stack com PostgreSQL.
- Configurar estrutura `docs/`.
- Preservar o briefing em `docs/00_brief/README_INICIAL_TRIBUTALAB.md`.
- Criar modelagem minima para areas, setores, modulos, operacoes, parametros, simulacoes e assumptions.
- Criar seeds iniciais do modulo Reforma Tributaria Imobiliaria.
- Criar tela inicial operacional.
- Criar testes basicos de models/services.

## Fora de escopo

- UI completa.
- Services finais de calculo tributario.
- Login, multi-tenant ou fluxo completo de simulacao.
- Transformar divergencias da planilha em regra juridica definitiva.

## Criterios de aceite

- App Rails inicia sem erro quando o banco esta disponivel.
- PostgreSQL esta configurado.
- `ruby bin/rails db:create db:migrate db:seed` funciona no ambiente com PostgreSQL.
- Seeds criam modulo, operacoes e parametros iniciais.
- Tela inicial mostra operacoes, parametros e alertas pendentes.
- Docs obrigatorios da etapa existem.
- Testes basicos passam ou falha ambiental fica documentada.

## Restricoes

- Stack obrigatoria: Ruby on Rails + PostgreSQL.
- Usar `decimal` para dinheiro, aliquotas e percentuais.
- Regras pendentes devem ficar em `Assumption` ou parametros com status pendente/divergente.
- Codigo em ingles; interface e documentacao de negocio em portugues.

## Arquivos de referencia

- `docs/00_brief/README_INICIAL_TRIBUTALAB.md`
- `comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquitetura_inicial_sistema.md`
- `comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md`
- `comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/call_denis_transcricao_2026-05-28.md`

## Duvidas conhecidas

As duvidas de negocio estao consolidadas em `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`.