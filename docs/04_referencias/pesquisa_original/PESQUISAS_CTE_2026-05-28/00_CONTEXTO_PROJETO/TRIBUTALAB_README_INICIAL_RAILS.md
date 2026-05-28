# TributaLab

Documento inicial de setup, arquitetura, handoff de pesquisa e coordenacao do projeto.

Este arquivo nao e apenas um README. Ele e o **prompt inicial de trabalho** para o agente/desenvolvedor que vai criar o repositorio do TributaLab. Ele deve ser lido inteiro antes de qualquer comando de setup.

O agente que receber este documento deve entender tres coisas:

1. O produto se chama **TributaLab**.
2. O app deve ser criado em **Ruby on Rails + PostgreSQL**.
3. O repositorio atual de pesquisa e a fonte de verdade inicial para regras, contexto, planilha, call, teses e pendencias.

Data: 2026-05-28

## 1. Nome do produto

**TributaLab**

TributaLab e uma plataforma de inteligencia tributaria operacional para transformar regras fiscais, teses, parametros legais e cenarios de negocio em simulacoes, oportunidades, relatorios e decisoes praticas.

O nome do produto e **TributaLab**. Nao usar nome de cliente como nome do produto. Clientes, empresas analisadas e parceiros entram apenas como contas, casos, projetos ou ambientes dentro da plataforma.

## 2. Ideia central

O TributaLab deve funcionar como um laboratorio tributario aplicado. Ele nao e apenas um repositorio juridico e nao e apenas uma calculadora isolada. Ele precisa unir:

- conhecimento tributario estruturado;
- regras parametrizaveis;
- simulacoes;
- oportunidades;
- memoria de decisoes;
- relatorios;
- evolucao por modulos e setores.

O sistema deve nascer pequeno, mas com arquitetura preparada para crescer.

A primeira entrega nao tenta resolver todo o universo tributario. O recorte inicial e:

**Reforma Tributaria > Segmento Imobiliario / Construcao Civil**

Esse recorte inicial vem da call com Denis e da planilha-base recebida em 2026-05-28.

## 3. Stack obrigatoria

O projeto deve ser implementado com:

- **Ruby on Rails** como framework principal;
- **Ruby** como linguagem do backend e da aplicacao principal;
- **PostgreSQL** como banco de dados;
- Rails full-stack, preferencialmente com Hotwire/Turbo/Stimulus para ganhar velocidade sem criar frontend separado no inicio;
- CSS simples e produtivo, preferencialmente Tailwind se estiver adequado ao setup Rails escolhido;
- testes automatizados desde o inicio.

Nao iniciar como Next.js, Node.js, Python, planilha automatizada ou SPA separada. O produto principal sera Rails + PostgreSQL.

## 4. Principio de arquitetura do produto

A arquitetura conceitual tem duas camadas principais.

### Camada 1: tipo de trabalho

O usuario primeiro escolhe o tipo de trabalho tributario:

1. **Recuperacao de credito**
   - Olha para o passado.
   - Busca valores pagos indevidamente ou a maior.
   - Trabalha com verbas, rubricas, periodos, documentos, jurisprudencia, risco e potencial de recuperacao.

2. **Reforma tributaria**
   - Olha para o futuro.
   - Simula impacto de IBS/CBS e novas regras.
   - Trabalha com operacoes, aliquotas, redutores, creditos, regimes, cenarios e comparativos.

### Camada 2: recorte/setor

Depois do tipo de trabalho, o usuario escolhe o recorte/setor.

O primeiro recorte e:

- **Imobiliario / Construcao Civil**

Importante: imobiliario nao e o produto inteiro. E o primeiro recorte dentro do produto.

No futuro, o TributaLab pode receber outros recortes, como folha, servicos, comercio, industria, agro, importacao, regimes especiais, etc.

## 5. Primeiro modulo real

O primeiro modulo operacional do TributaLab sera:

**Reforma Tributaria Imobiliaria**

Esse modulo deve organizar as regras e simulacoes para operacoes imobiliarias e de construcao civil.

Operacoes iniciais:

1. Venda de imovel / incorporacao.
2. Venda de lote residencial.
3. Locacao de imoveis.
4. Construcao civil.
5. Administracao / corretagem.
6. Cessao de direitos.
7. Permuta sem torna.
8. Permuta com torna.

## 6. Fonte de verdade inicial

O TributaLab nasce a partir de um repositorio de pesquisa ja existente. Esse repositorio e a fonte de verdade inicial para o novo app.

Repositorio/pacote de pesquisa:

```text
comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/
```

Esse pacote nao e codigo do produto. Ele e o acervo de contexto, pesquisa, documentos norte e regras que devem alimentar o primeiro setup.

O agente/desenvolvedor deve consultar esses arquivos antes de modelar entidades, seeds, telas ou services. Se o novo repositorio TributaLab estiver em outro workspace e esses caminhos nao existirem, o agente deve pedir ao dono do projeto para anexar/copiar os documentos. Nao inventar regra para preencher lacuna.

### 6.1 Contexto do produto e modulo inicial

Pasta:

```text
comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/
```

Arquivos obrigatorios de leitura:

- `call_denis_transcricao_2026-05-28.md`
- `arquitetura_inicial_sistema.md`
- `tabela_reforma_tributaria_segmento_imobiliario_lc227_2026.xlsx`
- `leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md`
- `TRIBUTALAB_README_INICIAL_RAILS.md`

A planilha do Denis tem 15 abas e serve como documento norte para o MVP. Ela deve ser tratada como base de regras e roteiro de calculo, nao como calculadora final perfeita.

### 6.2 Pesquisa de recuperacao de credito por verbas/rubricas

Pasta:

```text
comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/01_VERBAS_RUBRICAS_COM_POSSIVEL_RECUPERACAO/
```

Arquivos existentes:

- `terco_constitucional_de_ferias.md`
- `aviso_previo_indenizado.md`
- `ferias_indenizadas.md`
- `multas_rescisorias.md`
- `indenizacao_demissao_voluntaria_pdv.md`
- `auxilio_transporte_pago_em_dinheiro.md`
- `auxilio_creche.md`
- `auxilio_educacao.md`
- `danos_morais_e_materiais.md`
- `diarias_de_viagem.md`
- `multas_por_atraso_pagamentos_indenizatorios.md`
- `seguro_desemprego_indenizacoes_correlatas.md`

Esses documentos nao entram no primeiro modulo de calculo da Reforma Tributaria Imobiliaria, mas sao importantes para a arquitetura futura de **Recuperacao de Credito**. O app deve nascer preparado para receber esse eixo depois.

### 6.3 Marco legal, incidencia e prazos

Pasta:

```text
comunicacao/RealPrev/Recebida/PESQUISAS_CTE_2026-05-28/02_MARCO_LEGAL_E_PERIODO_DE_CADA_VERBA/
```

Arquivos existentes:

- `tributos_e_incidencias_afetados.md`
- `prazo_de_recuperacao_e_excecoes.md`
- `marco_inicial_e_marco_final_de_cada_tese.md`
- `identificar_se_verba_e_tributavel_ou_nao.md`
- `decisoes_stj_stf_carf_receita_federal.md`

Esses documentos devem orientar a futura area de recuperacao e a modelagem de base legal, status de tese, periodo, risco e fonte normativa.

### 6.4 Regra de uso das fontes

O agente/desenvolvedor deve seguir esta ordem:

1. Ler este README.
2. Ler `arquitetura_inicial_sistema.md`.
3. Ler `leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md`.
4. Consultar a planilha quando precisar confirmar abas, operacoes, formulas ou parametros.
5. Usar os arquivos das pastas `01` e `02` apenas como base para arquitetura futura de recuperacao de credito, sem implementar recuperacao completa na Etapa 001.
6. Registrar toda regra pendente em `Assumption`, `TaxParameter` ou documento de pendencias.
7. Nunca transformar ponto pendente em regra definitiva sem validacao humana.

### 6.5 Entregavel de fontes no novo repositorio

Na Etapa 001, criar no novo repo:

```text
docs/04_referencias/INDICE_FONTES.md
```

Esse arquivo deve listar as fontes consultadas e indicar quais foram copiadas, quais foram apenas referenciadas e quais nao estavam acessiveis no workspace.

Se possivel, copiar os arquivos de pesquisa para:

```text
docs/04_referencias/pesquisa_original/
```

Se nao for possivel copiar, registrar isso em `docs/03_comunicacao/ETAPA_001_RESPOSTA.md`.

## 7. Pontos da planilha que precisam de validacao

Antes de transformar tudo em regra definitiva, manter estes pontos como pendencias:

1. O arquivo fala em LC 227/2026, mas varias abas citam LC 214/2025.
2. Na locacao, a formula indica excluir IPTU e condominio da base, mas o exemplo da planilha nao exclui.
3. A regra geral cita reducao de 70% para locacao/cessao/arrendamento, mas a aba de calculo da cessao usa aliquota cheia.
4. Confirmar se construcao civil usa aliquota cheia com creditos, sem reducao especifica.
5. Confirmar se administracao/corretagem usa aliquota cheia sem redutor/reducao.
6. Confirmar condicoes documentais para creditos.
7. Confirmar se base negativa apos redutor deve virar zero.
8. Confirmar tratamento de credito maior que debito.
9. Confirmar se permuta sem torna fica apenas informativa ou ganha tela propria.

Enquanto esses pontos nao forem validados, o sistema deve registrar essas regras como **hipoteses parametrizaveis** ou **assumptions**, nao como verdade fechada.

## 8. Parametros iniciais do modulo Reforma Tributaria Imobiliaria

Parametros da planilha inicial:

- aliquota cheia IBS/CBS: 26,5%;
- redutor venda de imovel residencial: R$ 100.000 por unidade;
- redutor venda de lote residencial: R$ 30.000 por lote;
- redutor locacao residencial: R$ 600 por mes por imovel;
- reducao venda/incorporacao: 50%;
- reducao locacao/cessao/arrendamento: 70%, pendente de validacao para cessao;
- permuta sem torna: sem incidencia, conforme modelo inicial;
- permuta com torna: incidencia sobre o valor da torna.

Todos esses valores devem ser parametrizaveis no banco. Nao hardcodar como regra fixa espalhada no codigo.

## 9. Entidades de dominio sugeridas

Usar nomes tecnicos em ingles no codigo, mas manter textos de interface e documentacao de negocio em portugues.

Entidades iniciais sugeridas:

### ProductArea

Representa uma grande area do produto.

Exemplos:

- `tax_reform`
- `credit_recovery`

### Sector

Representa um recorte/setor.

Exemplos:

- `real_estate`
- `construction`

### Module

Representa uma combinacao operacional dentro do produto.

Exemplo:

- Reforma Tributaria Imobiliaria.

### Operation

Representa uma operacao tributavel ou analisavel.

Exemplos:

- venda de imovel;
- venda de lote;
- locacao;
- construcao civil;
- administracao/corretagem;
- cessao de direitos;
- permuta com torna;
- permuta sem torna.

### TaxParameter

Representa parametros editaveis.

Exemplos:

- aliquota cheia IBS/CBS;
- redutor social;
- percentual de reducao;
- vigencia;
- base legal;
- status de validacao.

### LegalBasis

Representa base legal, artigo, observacao e status.

Campos importantes:

- lei;
- artigo;
- descricao;
- link ou referencia;
- status: validado, pendente, divergente, substituido.

### CreditCategory

Representa categorias de creditos permitidos.

Exemplos:

- materiais de construcao;
- servicos de engenharia;
- energia eletrica;
- software de gestao;
- servicos juridicos;
- corretagem vinculada;
- custos financeiros vinculados a torna.

### Simulation

Representa uma simulacao feita pelo usuario.

Deve guardar:

- usuario/conta;
- modulo;
- operacao;
- inputs;
- outputs;
- parametros usados;
- versao das regras;
- observacoes;
- data/hora.

### SimulationResult

Representa resultado estruturado da simulacao.

Outputs minimos:

- base bruta;
- redutor aplicado;
- base liquida;
- aliquota cheia;
- reducao aplicada;
- aliquota efetiva;
- debito IBS/CBS;
- creditos;
- imposto liquido;
- alertas de validacao.

### Assumption

Representa uma hipotese usada no calculo enquanto a regra ainda nao esta fechada.

Exemplos:

- locacao deduz IPTU/condominio ou nao;
- cessao aplica reducao de 70% ou aliquota cheia;
- credito excedente carrega saldo ou apenas zera imposto do periodo.

## 10. Cuidados tecnicos obrigatorios

1. Usar `decimal` no banco para dinheiro, aliquotas e percentuais. Nao usar float para calculo financeiro/tributario.
2. Guardar parametros usados em cada simulacao para permitir auditoria futura.
3. Separar regra de calculo em services ou objetos de dominio, nao deixar calculo pesado em controller/view.
4. Toda regra pendente deve gerar alerta visivel no resultado.
5. Toda simulacao deve poder ser reproduzida depois.
6. O sistema deve conseguir evoluir para multiplos modulos sem reescrever o banco inteiro.
7. Nao misturar cliente com produto. Cliente e conta/projeto/caso, nao nome de modulo.
8. Nao inventar regra juridica definitiva quando houver divergencia. Marcar como pendente.

## 11. Estrutura inicial esperada do repositorio

Estrutura sugerida depois do setup Rails:

```text
tributalab/
  app/
    controllers/
    models/
    services/
      simulations/
      tax_rules/
    views/
    javascript/
  config/
  db/
    migrate/
    seeds.rb
  docs/
    00_brief/
    01_planejamento/
    02_decisoes/
    03_comunicacao/
    04_referencias/
      INDICE_FONTES.md
      pesquisa_original/
    05_qa/
  spec/ ou test/
  README.md
```

A pasta `docs/03_comunicacao/` e obrigatoria. Ela sera o canal de conversa entre os agentes/desenvolvedores e o dono do projeto.

## 12. Protocolo de comunicacao por Markdown

Este projeto deve ser coordenado por arquivos Markdown.

Sempre que uma etapa for iniciada, deve existir um arquivo de pedido/contexto.

Sempre que uma etapa for concluida, o agente/desenvolvedor deve criar um arquivo Markdown de resposta.

### Padrao de nomes

Pedidos:

```text
docs/03_comunicacao/ETAPA_001_PEDIDO.md
docs/03_comunicacao/ETAPA_002_PEDIDO.md
docs/03_comunicacao/ETAPA_003_PEDIDO.md
```

Respostas:

```text
docs/03_comunicacao/ETAPA_001_RESPOSTA.md
docs/03_comunicacao/ETAPA_002_RESPOSTA.md
docs/03_comunicacao/ETAPA_003_RESPOSTA.md
```

Decisoes importantes:

```text
docs/02_decisoes/DECISAO_001_nome_do_topico.md
```

Pendencias ou perguntas:

```text
docs/03_comunicacao/PERGUNTAS_ABERTAS.md
```

## 13. Formato obrigatorio do pedido de etapa

Cada arquivo `ETAPA_XXX_PEDIDO.md` deve conter:

```md
# ETAPA XXX - Pedido

## Objetivo

Descrever o que deve ser feito.

## Contexto

Explicar o motivo da etapa e links para documentos relevantes.

## Escopo

O que entra nesta etapa.

## Fora de escopo

O que nao deve ser feito agora.

## Criterios de aceite

Lista objetiva do que precisa estar pronto para considerar a etapa concluida.

## Restricoes

Stack, padroes, decisoes ja tomadas, cuidados legais e tecnicos.

## Arquivos de referencia

Links ou caminhos dos arquivos relevantes.

## Duvidas conhecidas

Perguntas que precisam ser respondidas, se houver.
```

## 14. Formato obrigatorio da resposta de etapa

Quando terminar qualquer etapa, o agente/desenvolvedor deve criar um arquivo `ETAPA_XXX_RESPOSTA.md` com:

```md
# ETAPA XXX - Resposta

## Resumo do que foi feito

Explicacao curta e objetiva.

## Arquivos criados ou alterados

Lista de arquivos com breve descricao.

## Como rodar

Comandos necessarios para executar ou verificar.

## Testes executados

Comandos rodados e resultado.

## Decisoes tomadas

Decisoes tecnicas ou de produto tomadas durante a etapa.

## Pendencias

O que ficou aberto.

## Perguntas para o dono do projeto

Perguntas que precisam de resposta humana.

## Proxima etapa sugerida

Sugestao objetiva do proximo passo.
```

Essa resposta e obrigatoria. O projeto nao deve avancar para a proxima etapa sem esse arquivo.

## 15. Primeira etapa do projeto

A primeira etapa e criar o esqueleto tecnico do TributaLab em Ruby on Rails com PostgreSQL e a documentacao de coordenacao.

### Objetivo da Etapa 001

Criar um projeto Rails funcional, com PostgreSQL configurado, estrutura de documentacao, primeira modelagem conceitual e seeds iniciais do modulo Reforma Tributaria Imobiliaria.

### Escopo da Etapa 001

1. Criar app Rails no repositorio.
2. Configurar PostgreSQL.
3. Criar estrutura `docs/`.
4. Preservar este documento em `docs/00_brief/README_INICIAL_TRIBUTALAB.md`.
5. Criar `docs/03_comunicacao/ETAPA_001_RESPOSTA.md` ao finalizar.
6. Criar `docs/04_referencias/INDICE_FONTES.md` com o mapa das fontes de pesquisa usadas.
7. Copiar ou referenciar os documentos originais de pesquisa em `docs/04_referencias/pesquisa_original/`, quando estiverem acessiveis.
8. Criar modelagem inicial minima para:
   - areas do produto;
   - setores;
   - modulos;
   - operacoes;
   - parametros tributarios;
   - simulacoes.
9. Criar seeds iniciais do modulo Reforma Tributaria Imobiliaria.
10. Criar ao menos uma rota/tela inicial que mostre o produto e o modulo inicial.
11. Criar testes basicos para models/services iniciais.

### Fora de escopo da Etapa 001

Nao construir ainda uma UI completa.
Nao tentar resolver todos os calculos.
Nao integrar login complexo se isso atrasar o esqueleto inicial.
Nao criar multi-tenant completo se nao for necessario para o primeiro boot.
Nao transformar as regras pendentes em regras definitivas.

## 16. Comandos sugeridos para setup Rails

Se o repositorio estiver vazio ou apenas com este README, preservar este arquivo primeiro.

Exemplo de fluxo:

```bash
mkdir -p docs/00_brief
cp README.md docs/00_brief/README_INICIAL_TRIBUTALAB.md
rails new . --database=postgresql --css=tailwind --skip-git
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

Observacao: se o `rails new .` pedir para sobrescrever o README, preservar este conteudo em `docs/00_brief/README_INICIAL_TRIBUTALAB.md` antes de aceitar qualquer sobrescrita.

Se o ambiente usar Rails 8, seguir a versao estavel disponivel. Se houver incompatibilidade local, usar Rails 7.2+ sem mudar a arquitetura do produto.

## 17. Gems e ferramentas sugeridas

Escolher de forma conservadora. Nao instalar gem desnecessaria.

Sugestoes iniciais:

- `pg` para PostgreSQL;
- `rspec-rails` ou manter Minitest se for decisao do projeto;
- `factory_bot_rails`, se usar RSpec;
- `rubocop-rails` para padrao de codigo;
- `brakeman` para analise de seguranca;
- `dotenv-rails` se houver necessidade de variaveis locais;
- `pagy` apenas quando houver listagens reais;
- `devise` apenas quando autenticacao for entrar de verdade.

Nao adicionar dependencia pesada sem motivo claro.

## 18. Seeds iniciais esperados

O `db/seeds.rb` deve criar dados equivalentes a:

### Areas

- Reforma Tributaria
- Recuperacao de Credito

### Setor inicial

- Imobiliario / Construcao Civil

### Modulo inicial

- Reforma Tributaria Imobiliaria

### Operacoes iniciais

- Venda de imovel / incorporacao
- Venda de lote residencial
- Locacao de imoveis
- Construcao civil
- Administracao / corretagem
- Cessao de direitos
- Permuta sem torna
- Permuta com torna

### Parametros iniciais

- Aliquota cheia IBS/CBS: 26,5%
- Redutor venda imovel residencial: R$ 100.000
- Redutor venda lote residencial: R$ 30.000
- Redutor locacao residencial: R$ 600
- Reducao venda/incorporacao: 50%
- Reducao locacao/cessao/arrendamento: 70%, com alerta de validacao para cessao

## 19. Primeiros calculos a implementar depois do setup

Apos a Etapa 001, a Etapa 002 deve implementar os services de calculo para:

1. Venda de imovel.
2. Venda de lote residencial.
3. Locacao de imoveis.
4. Permuta com torna.

Depois entram:

5. Construcao civil.
6. Administracao/corretagem.
7. Cessao de direitos.
8. Permuta sem torna como tela informativa.

## 20. Formula inicial por operacao

### Venda de imovel

```text
base_calculo = max(0, valor_venda - redutor_social)
aliquota_efetiva = aliquota_cheia * (1 - reducao)
imposto_devido = base_calculo * aliquota_efetiva
```

### Venda de lote residencial

```text
base_calculo = max(0, valor_venda - redutor_lote)
aliquota_efetiva = aliquota_cheia * (1 - reducao)
imposto_devido = base_calculo * aliquota_efetiva
```

### Locacao

Pendente de validacao:

```text
base_bruta = aluguel - iptu - condominio
base_liquida = max(0, base_bruta - redutor_locacao)
aliquota_efetiva = aliquota_cheia * (1 - reducao_locacao)
imposto_devido = base_liquida * aliquota_efetiva
```

A planilha apresenta divergencia no exemplo. O sistema deve exibir alerta enquanto isso estiver pendente.

### Construcao civil

```text
base_calculo = valor_contrato
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

### Administracao/corretagem

```text
base_calculo = valor_servico
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

### Cessao de direitos

Pendente de validacao sobre reducao de aliquota:

```text
base_calculo = valor_cessao
debito = base_calculo * aliquota_aplicavel
imposto_liquido = max(0, debito - creditos)
```

### Permuta com torna

```text
base_calculo = valor_torna
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

## 21. UI inicial esperada

A interface inicial deve ser operacional, nao uma landing page.

Primeira tela sugerida:

- nome do produto: TributaLab;
- area atual: Reforma Tributaria;
- modulo atual: Imobiliario / Construcao Civil;
- cards ou lista de operacoes;
- parametros atuais;
- alertas de regras pendentes;
- botao para criar simulacao quando os services estiverem prontos.

Evitar hero marketing, excesso visual e texto publicitario. O produto e uma ferramenta B2B de trabalho.

## 22. Padrao de desenvolvimento

1. Implementar em pequenos passos.
2. Cada etapa deve rodar localmente antes de ser considerada concluida.
3. Preferir clareza a abstracao prematura.
4. Services para regras de calculo.
5. Models para persistencia e relacionamentos.
6. Controllers finos.
7. Views simples e funcionais.
8. Testes para qualquer formula tributaria.
9. Documentar decisoes em Markdown.
10. Nunca esconder divergencia de regra; mostrar como alerta.

## 23. Criterios de aceite da Etapa 001

A Etapa 001 so termina quando:

- o app Rails inicia sem erro;
- PostgreSQL esta configurado;
- `bin/rails db:create db:migrate db:seed` funciona;
- existe estrutura `docs/`;
- este documento esta preservado em `docs/00_brief/README_INICIAL_TRIBUTALAB.md`;
- existe `docs/04_referencias/INDICE_FONTES.md`;
- a resposta da etapa informa se os documentos de pesquisa foram copiados ou apenas referenciados;
- existe tela inicial do TributaLab;
- seeds criam o modulo Reforma Tributaria Imobiliaria;
- parametros iniciais aparecem no banco;
- existe arquivo `docs/03_comunicacao/ETAPA_001_RESPOSTA.md`;
- a resposta da etapa lista arquivos alterados, testes e pendencias;
- testes basicos passam ou o motivo de falha esta documentado.

## 24. Primeiro pedido para o agente/desenvolvedor

Leia este documento inteiro e execute a **Etapa 001**.

Antes de implementar, confirme no arquivo de resposta se os documentos de pesquisa estavam acessiveis. Se estiverem, use-os para montar seeds, parametros, assumptions e indice de fontes. Se nao estiverem, registre a ausencia e nao invente dados alem dos que aparecem neste README.

Ao terminar, nao responda apenas em chat. Crie obrigatoriamente:

`docs/03_comunicacao/ETAPA_001_RESPOSTA.md`

Esse arquivo deve explicar exatamente o que foi feito, como rodar, quais arquivos foram criados, quais testes foram executados, quais pendencias ficaram abertas e qual deve ser a Etapa 002.

Se alguma decisao tecnica precisar ser tomada durante o setup, registre em:

`docs/02_decisoes/DECISAO_001_setup_inicial.md`

Se houver duvidas de negocio, registre em:

`docs/03_comunicacao/PERGUNTAS_ABERTAS.md`

## 25. Norte do produto

O TributaLab deve virar um sistema que ajuda a responder perguntas como:

- Qual regra tributaria se aplica a esta operacao?
- Qual e a base de calculo?
- Qual redutor ou reducao entra?
- Qual credito pode ser aproveitado?
- Qual e o imposto estimado?
- Quais regras ainda estao pendentes ou divergentes?
- Quais oportunidades existem para o cliente?
- O que mudou entre cenarios?
- Qual decisao deve ser tomada agora?

A primeira versao deve ser simples, mas ja precisa nascer com base correta para evoluir.

## 26. Resumo executivo

**Produto:** TributaLab  
**Stack:** Ruby on Rails + PostgreSQL  
**Primeiro modulo:** Reforma Tributaria Imobiliaria  
**Primeiro objetivo tecnico:** criar Rails app funcional com seeds e docs  
**Protocolo de trabalho:** toda etapa termina com resposta em Markdown  
**Regra principal:** construir aos poucos, com regra parametrizavel, auditoria e alertas de validacao
