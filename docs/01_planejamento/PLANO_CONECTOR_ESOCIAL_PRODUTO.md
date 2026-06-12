# Plano do conector eSocial como produto

## Parecer curto

O produto nao deve depender de print nem de coleta manual. O caminho certo e um conector oficial, com certificado/procuracao do cliente, fila de sincronizacao, controle de cota e armazenamento do XML bruto antes de qualquer interpretacao.

Hoje o projeto tem extratores locais para XML/ZIP de S-1005 e S-1020, mas ainda nao tem cliente SOAP oficial do eSocial implementado. Portanto, antes de gastar consulta em producao, precisamos criar o modulo de conexao eSocial e um livro-caixa de consultas para nao estourar limite.

## Limite operacional

O Download Cirurgico tem limite baixo e compartilhado entre servicos de consulta/download. A regra operacional do produto deve ser:

- Nunca executar coleta sem registrar CNPJ, ambiente, evento, periodo e motivo.
- Nunca disparar lote sem estimar chamadas antes.
- Parar automaticamente antes do limite diario.
- Cachear identificadores, recibos e XML por hash para nao consultar duas vezes a mesma coisa.
- Tratar erro 500 ServiceActivationException como limite diario atingido, nao como servico fora.

## Quantas consultas usar

Estimativa inicial, assumindo fluxo com consulta de identificadores e download dos XMLs retornados. O numero real pode variar por tipo de evento, paginacao e disponibilidade do endpoint.

| Objetivo | Eventos | Consultas minimas provaveis | Risco |
| --- | --- | ---: | --- |
| Validar so lotacoes | S-1020 | 2 | baixo |
| Tabelas cadastrais basicas | S-1000, S-1005, S-1010, S-1020 | 6 a 10 | medio |
| Tabelas cadastrais completas | S-1000, S-1005, S-1010, S-1020, S-1070 | 8 a 10+ | medio/alto |
| Uma competencia de folha, poucos CPFs | S-1200, S-1210, S-2299/S-2399, S-5001/S-5011 | depende do CPF/evento | alto |
| Historico completo de folha | varios meses + CPFs | muitos dias de cota | alto |

Para a CTE agora, a melhor primeira carga do produto e gastar no maximo um dia de cota com as tabelas cadastrais: S-1000, S-1005, S-1010 e S-1020. Isso deve caber em aproximadamente 6 a 10 consultas se o fluxo responder bem. Folha completa nao deve entrar no primeiro disparo, porque pode consumir a cota rapidamente por CPF/competencia.

## MVP do produto

1. Cadastro de conexao
   - CNPJ/CPF do outorgante.
   - Procurador quando houver.
   - Ambiente: producao ou producao restrita.
   - Certificado digital referenciado com seguranca, sem senha salva em texto.

2. Planejamento de sincronizacao
   - Usuario escolhe alvo: `tabelas cadastrais`, `folha por competencia`, `evento especifico`.
   - Sistema calcula chamadas estimadas antes de executar.
   - Sistema exige confirmacao quando o plano pode consumir cota relevante.

3. Livro-caixa de consultas
   - Registrar toda chamada oficial com data, CNPJ, endpoint, evento, periodo, status e erro.
   - Bloquear novas chamadas ao aproximar do limite diario.
   - Mostrar saldo estimado do dia no painel.

4. Armazenamento bruto
   - Salvar XML original, recibo, identificador, hash SHA-256 e data de recepcao.
   - Nunca sobrescrever evento antigo sem manter versao.
   - Depois rodar parsers normalizados para alimentar telas.

5. Parsers normalizados
   - Reaproveitar os extratores existentes de S-1005 e S-1020.
   - Criar parsers equivalentes para S-1010, S-1200, S-1210, S-5001 e S-5011.

## Primeira execucao recomendada para CTE

Plano de menor risco:

1. Consultar S-1020 para trocar o print por XML real de lotacoes.
2. Consultar S-1005 para estabelecimento/obra, RAT/FAP/GILRAT e CNAE.
3. Consultar S-1010 para rubricas e incidencias.
4. Consultar S-1000 para dados do empregador.

Se a cota aguentar, incluir S-1070 para processos administrativos/judiciais. Se nao aguentar, S-1070 fica para o proximo dia.

## Fora do MVP imediato

- Coletar folha completa de varios anos em um unico dia.
- Consultar S-1210 por CPF sem fila e controle de cota.
- Fazer scraping do portal como base principal do produto.
- Rodar scripts soltos sem ledger de consultas.

## Decisao de produto

O produto precisa ter dois modos:

- `sync oficial`: usa eSocial oficial com certificado, cota, fila e XML bruto.
- `importacao assistida`: aceita ZIP/XML baixado pelo usuario, sem gastar consulta.

O modo oficial e o diferencial do produto. O modo assistido continua util para auditoria, homologacao e quando o cliente nao quer gastar cota no dia.