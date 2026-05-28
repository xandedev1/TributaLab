# DECISAO 001 - Setup inicial

## Contexto

A Etapa 001 precisava criar um projeto Rails funcional com PostgreSQL, preservar o briefing e preparar a base para o modulo Reforma Tributaria Imobiliaria.

## Decisoes

- Usar Rails 8.1.3, Ruby 3.3.11, PostgreSQL, Hotwire e Tailwind gerados pelo setup Rails.
- Manter Minitest, que ja vem no Rails, para evitar dependencias adicionais na primeira etapa.
- Usar `TaxModule` no codigo em vez de `Module`, porque `Module` e uma constante nativa do Ruby.
- Modelar `Assumption` desde o inicio para impedir que divergencias da planilha virem regra definitiva sem validacao humana.
- Usar `decimal` para valores monetarios, aliquotas e percentuais.
- Configurar `POSTGRES_HOST` e `POSTGRES_PORT` com defaults locais para facilitar execucao no Windows.

## Consequencias

- O dominio fica preparado para novos modulos sem conflitar com classes centrais do Ruby.
- A primeira tela ja mostra alertas pendentes, mesmo antes dos simuladores completos.
- A Etapa 002 pode focar nos services de calculo sem refazer a base de dados.