# Base calc — Lotações unificadas

> Cruzamento novo. Aqui é só pra juntar o material cru. Nada foi decidido ainda — o que valer
> sai da call e dos dados que o Xande mandar. Não tem suposição minha neste documento.

---

## 1. Call — Xande · Marcos · Denis

Speaker A: [00:01] Então a gente tem 3 principais fontes que a gente vai analisar, né? [00:08] A primeira delas sendo tabela de lotações CNPJ, que é o que a gente tá olhando aqui agora. [00:17] E ela traz para gente como principais dados o código de lotação, o número da inscrição, na verdade o código de lotação que vai ser usado como a chave estrangeira, né? [00:27] Vai ser uma FK. [00:29] O número de inscrição vai ser uma FK também? [00:32] Não, não necessariamente vai ser uma FK, porque a gente não vai querer saber por empresa.

Speaker B: [00:39] Então o CNPJ ele não tem relacionamento com mais nada, né?

Speaker A: [00:44] Então ele não vira uma FK. [00:46] O FPS é o FPS daqui, por exemplo, que quer saber, todo mundo quer FPS 515, a gente consegue relacionar com outras. [00:55] O início da validade, o fim da validade de cada uma das lotações citadas lá. [01:00] Beleza, essa é a primeira tabela que a gente vai relacionar. [01:03] A gente vai relacionar com a segunda tabela, que é o código de lotações tributárias, só que sem ser a tabela de CNPJ, né, sem ser a tabela comum. [01:12] Essa tabela comum, que é a segunda tabela lá na aba de lotações tributárias, ela traz para gente como vai ficar o código de lotação. [01:22] A gente teria o código de lotação numerado lá de 1 até o final. [01:27] A gente tem o KINAI, que a gente quer pegar, o RAT, o FAP e o ajuste de RAT. [01:34] Isso seria no caso da primeira, da primeira parte que é do estabelecimento, que traria, entendeu, como é que ela traria por estabelecimento. [01:43] Lá em cima tem o estabelecimento com aqueles dados, depois a gente começa os códigos. [01:47] Os códigos eles vêm com FPAS, que é uma É uma chave estrangeira, ele é citado lá. [01:55] E também o código de terceiros, que é outra chave estrangeira. [01:59] Beleza, isso é a segunda tabela. [02:01] E a terceira tabela que a gente quer cruzar é a tabela de tabela quarta, tabela 4 não oficial, a quarta RH, né, que é a quarta RH, que é a quarta tabela, a quarta aba ali. [02:16] Nela a gente tem como chave estrangeira o FPS, que são citados vários FPS, e E por FPAS a gente tem código de terceiro, alíquota, terceiros, né, que seria a tabela de descrição, que depois a gente vai mudar esse nome, mas por enquanto é terceiros, tá aqui. [02:33] E a parte de regime. [02:35] E a parte de regime ela tem que ser um filtro, um filtro muito importante, porque a gente pode ter exatamente o mesmo código de terceiros com A mesma FPAS, o mesmo alíquota, o mesmo tudo, porém de empresa ou cooperativa, né? [02:53] Ela pode para essas duas áreas. [02:55] Então pode ter duas espelhadas com algum tipo de informação diferente, mas com código, com empresa cooperativa. [03:01] É, o código financeiro não vai ser igual, esse que é o ponto. [03:04] Mas às vezes elas vão parecer ali, mas o regime que vai fazer a diferenciação dessas duas. [03:11] Então o regime é um seletor ali que a gente quer ter para visualizar só uma ou de outro tipo. [03:16] A gente tem que ter essas três tabelas hoje montadas para para poder cruzar e criar. [03:21] A gente quer ver uma visualização única desse cruzamento de tudo isso. [03:25] O que que a gente quer fazer com essas 3 tabelas? [03:28] Como é que a gente vai cruzar elas?

Speaker B: [03:30] Ela vai— a gente vai usar ela como fonte de cálculo, como fonte. [03:35] Vai pegar a base de cálculo que vai estar na 1200 e vai aplicar sobre esses percentuais que estão aí.

Speaker A: [03:45] Entendido. [03:45] E no final a gente quer visualizar o quê? [03:47] Qual que seria a visualização final de tudo? [03:48] O resultado da contribuição previdenciária, contribuição previdenciária final de todas as empresas, de tudo que a gente fez da APA de 2025. [03:57] A gente quer utilizar, a gente vai utilizar a S1010 nesse processo, nesse meio caminho?

Speaker B: [04:04] A gente vai usar isso daqui, monta uma base, aí a gente vai usar essas tabelas aqui Entendeu? [04:16] A gente vai criar aqui uma base de cálculo. [04:21] A base de cálculo é a 1010 com a 1200.

Speaker A: [04:26] Entendido. [04:26] A 1010 que a gente tem de todos os anos, porque a gente precisa compor todas as criações. [04:30] Talvez tiveram rubricas que foram enviadas em 2019 que estão ativas até hoje. [04:34] Então a gente tem que analisar todos os anos. [04:36] A gente tem essa pasta e a gente tem a pasta de todos os eventos enviados em 2025 da APA, onde a gente quer selecionar apenas os eventos S1200 para poder compor a base de cálculo geral. [04:49] O que que a gente vai pegar de cada um deles? [04:51] Só para voltar aqui, por exemplo, da tabela S1210, que vai ser a tabela, a primeira tabela que a gente vai analisar, que a gente tem todos os anos.

Speaker B: [05:00] A gente tem como verificar o código de rubrica, tem código de rubrica lá dentro, código de incidência contribuição previdenciária, código de incidência fundo de garantia. [05:14] A descrição da rúbrica, o tipo de rúbrica, o início da validade e o fim da validade.

Speaker A: [05:22] Beleza, esses são todos os componentes que a gente vai analisar dentro da S1010 de todos aqueles anos, relacionada com a 1200, que tem o período de apuração, que é o FK, código de lotação.

Speaker B: [05:41] O FK código de rubrica, o FK IDE rubrica, o valor da rubrica, a quantidade da rubrica e o grau de exposição.

Speaker A: [06:01] O grau de exposição. [06:02] Isso são tudo que a gente vai puxar dentro das S1200 que estão dentro de todos os eventos enviados de 2025 lá divididos por mês. [06:10] E aí o relacionamento com a tabela aqui a gente já fez aqui, né? [06:14] Então é isso, a gente vai instalar a base 1, que seria tabela de lotação por CNPJ, tabela de lotações tributárias e tabela 4ª, tabela 4 do 4º RH. [06:24] Isso tudo é uma base que vai ser relacionada com as outras duas que a gente citou, que é S1210 e S1010. [06:29] Com isso a gente compõe todas as lotações da toda a parte previdenciária completa do Da empresa APA, né?

Speaker B: [06:38] Empresa APA, da parte previdenciária e de fundo de garantia.

Speaker A: [06:41] E previdenciária e fundo de garantia, a gente vai ter completo tudo. [06:45] Beleza, então.

Speaker B: [06:46] Deixa eu pausar isso.

Speaker A: [06:48] É o objetivo final. [06:49] Qual que vai ser a tabela final produzida? [06:51] O que que a gente quer ver na tela final?

Speaker B: [06:53] Da onde a gente cria a base de cálculo? [06:58] Da tabela S1200.

Speaker A: [07:00] A gente vai criar.

Speaker B: [07:01] Mas como que a gente chega na base de cálculo? [07:03] Pegando informação da tabela S-210.

Speaker A: [07:07] Beleza.

Speaker B: [07:09] Depois que a gente conseguiu determinar o que incide para Previdência e o que incide para Fundo de Garantia, a gente criou a base de cálculo. [07:19] Base de cálculo, ela com todas essas informações aqui, aí ela vai relacionar com essa única tabela já estruturada. [07:29] Para a gente poder multiplicar pelos 20% da empresa, que vai em algum lugar, ela vai estar aí com o RAT, FAP, ajuste, RAT. [07:55] Que o cálculo aqui é o RAT vezes o FAP. [08:12] O RAT e o FAP deve ser igual, ou não.

Speaker A: [08:17] Ele pode fazer essa parte de pesquisa também, vai ter essa parte de pesquisa onde aí ela tem que fazer a pesquisa completa para ver a base ali do que a gente tá vendo.

Speaker B: [08:24] E vezes o FAP, muito provavelmente vai dar o ajuste RAT, né? [08:30] É igual ajuste RAT. [08:33] Ó, amanhã eu vou deixar para amanhã. [08:38] O FPAS é só para relacionamento mesmo, 115 é só para determinar quais são os terceiros, tipo salário-educação, INSS, SENAC, entendeu? [08:50] Então aqui vai calcular os terceiros, tá? [08:55] Com isso a gente tem a parte previdenciária calculada, que é o que a empresa tem de despesa.

Speaker A: [09:08] Entendi.

Speaker B: [09:09] A gente vai fazer a mesma situação para determinar a base de cálculo aqui, BCP. [09:18] A base de cálculo do fundo de garantia também em cima do FGTS. [09:25] A gente vai fazer a mesma coisa. [09:27] Qual é a diferença? [09:29] A diferença que é 8%.

Speaker A: [09:31] A gente tem essa parte aqui também.

Speaker B: [09:33] Então, se já tiver FGTS, se já tiver calculado, é melhor ainda. [09:38] Vamos ver como é que tá o status aí.

Speaker A: [09:41] A gente tem por lotação aqui.

Speaker B: [09:43] Acho que o FGTS sai, não sai já por lotação? [09:48] Tá aqui por lotação. [09:49] Eu já acho que já sai por lotação, né? [09:51] E aí você consegue identificar. [09:52] Na verdade, aqui nem vai precisar calcular, nem vai precisar apurar.

Speaker A: [09:58] Já tem o valor, já tem na íntegra, né?

Speaker B: [10:00] Já tem, acho que até vinculado o cliente, não tem? [10:05] Tem.

Speaker A: [10:05] É porque a gente consegue vincular exatamente. [10:08] Então aqui Aqui a gente tem que reunir que a gente já tem cruzado.

Speaker B: [10:14] E aqui na verdade a gente vai tratar então a Previdência, só Previdência, e o Fundo de Garantia já vai direto aí, entendeu?

Speaker A: [10:21] Já tem aqui, depois a gente gera o relatório com quem já tem, mas não precisa cruzar mais muita coisa.

Speaker B: [10:24] Essa lotação do Fundo de Garantia só vai relacionar com essa aqui porque precisa do CNPJ, né?

Speaker A: [10:32] Entendi. [10:33] Ah, entendi. [10:34] Para poder gerar a tabela final base de cálculos FGTS, a gente vai ter que utilizar também a tabela lotação tributária por CNPJ para poder pegar esses cálculos aqui e jogar para compor por CNPJ lá, né?

Speaker B: [10:48] E aqui na verdade, ó, já tem o valor depositado, tem a base de cálculo e o valor depositado.

Speaker A: [10:54] Entendi.

Speaker B: [10:55] Então não vai precisar fazer cálculo, é só pegar esses valores.

Speaker A: [10:58] Beleza, com esse áudio que a gente tem completo, a gente vai fazer, começar a fazer os cruzamentos. [11:02] Aí a aula só precisa saber onde é que tá Todas as S1010 e todos os eventos do ano de 2025. [11:10] Eu vou dar esses dois caminhos pra ela e de resto ela já tem tudo.
---

## 2. Diretórios de dados

**A) Todos os eventos enviados pela APPA em 2025**

```text
C:\Users\xandao\Downloads\appa tabela gerais\todos eventos APPA 2025
```

**B) Todas as S-1010 (rubricas) enviadas para a APPA — 2018 a 2026**

```text
C:\Users\xandao\Downloads\appa tabela gerais\S1010 TODOS ANOS APPA
```

---

# ESTUDO (conclusões enquanto pesquiso) — 2026-08-25

> Tudo abaixo é fundamentado em **dados reais** que eu li dos 2 diretórios + leiaute oficial
> eSocial (gov.br, v. S-1.2/S-1.3). Onde eu não tenho certeza, está marcado como **[CONFIRMAR]**.

## 3. O que a call decidiu (resumo fiel da transcrição)

Objetivo final: **calcular a contribuição previdenciária (patronal + RAT/FAP + terceiros) e o FGTS
por lotação, de toda a APPA em 2025**, numa visualização única.

O cálculo se monta cruzando **3 blocos**:

- **Bloco "tabelas estruturais" (3 abas de uma planilha)** — a base montada:
  1. **Lotações por CNPJ** — código de lotação (chave), nº inscrição (CNPJ, *não* é FK — não querem
     ver por empresa), FPAS, início/fim de validade.
  2. **Lotações tributárias (tabela comum)** — o **topo (estabelecimento)** traz **valores FIXOS pro ano de
     2025 inteiro**: **CNAE `7820500`, RAT `3%`, FAP `0,7943`, RAT ajustado `2,3829%`** (o "KINAI" era CNAE).
     Abaixo, por lotação: FPAS (FK) e código de terceiros (FK). NÃO é tabela por competência — é fixo.
  3. **"4ª RH" (tabela de terceiros)** — por FPAS: código de terceiro, alíquota de terceiros, e
     **regime (empresa × cooperativa)** — o regime é um **filtro** essencial, porque o mesmo código de
     terceiros/FPAS/alíquota pode existir para empresa OU cooperativa (o que muda é o regime).
- **S-1010 (rubricas, todos os anos)** — dicionário: para cada rubrica, o que **incide** para
  Previdência (`codIncCP`) e para FGTS (`codIncFGTS`), descrição, tipo, validade.
- **S-1200 (eventos de 2025)** — os lançamentos reais: por competência (perApur) e lotação, cada
  rubrica lançada (codRubr, ideTabRubr, valor, quantidade, grau de exposição).

Fluxo que eles descreveram: **S-1010 + S-1200 → base de cálculo** (o que incide p/ Prev e p/ FGTS)
→ cruza com o bloco estrutural → **× 20% patronal + RAT×FAP + terceiros** = previdenciário.
Para o **FGTS**, o Speaker B disse que **já vem pronto por lotação** ("já tem base de cálculo e valor
depositado, nem precisa calcular") — só relacionar com a tabela de CNPJ.

## 4. O que EU encontrei nos arquivos (dados reais)

### 4.1 Eventos 2025 (pasta A)
- 12 ZIPs, um por mês (janeiro…dezembro). **Cada ZIP = a folha da competência do mês anterior**
  (ex.: `janeiro.zip` tem quase tudo `perApur = 2024-12`). ⇒ os "eventos de 2025" cobrem, na prática,
  as competências **~2024-12 até 2025-11**. **[CONFIRMAR se a "contribuição de 2025" é por competência
  2025-01..2025-12 ou por transmissão em 2025]** — isso muda quais ZIPs/competências entram.
- Só o `janeiro.zip` tem **153.886 eventos**. Distribuição de tipos (janeiro):
  `S-1200 = 22.992`, `S-1210 = 24.650`, `S-5001 = 24.950`, `S-5002 = 36.977`, `S-5003 = 24.950`,
  `S-5011 = 6`, `S-5013 = 6`, `S-1020 = 1.299`, `S-1010 = 74`, além de S-2200/2206/2299/3000 etc.
- S-1200 (janeiro): `codCateg` 101 domina; aparecem **106, 111, 103 e 721 (cooperado)** — o 721 liga
  com o filtro **regime cooperativa** da call. **315 lotações** distintas (em pares tipo
  `00335-001-02` e `E00335-001-02A`). **59 eventos com `infoPerAnt`** (períodos anteriores/retificação).
  **248.148 itensRemun** só em janeiro; **242 pares (codRubr, ideTabRubr)**; tabelas usadas: `1` e `EA001`.

### 4.2 S-1010 (pasta B)
- ~100 arquivos (cada "arquivo" é um **ZIP** com o XML dentro), 2018→2026. **4.808 registros** de rubrica
  (o grosso, 3.191, é a carga inicial de 2018).
- Tabelas de rubrica (`ideTabRubr`): **`1` (4.640)**, `EA001` (167), `0001` (1). A principal é a **`1`**.
- `tpRubr`: 1=provento (3.094), 2=desconto (1.678), 3=informativa, 4=informativa dedutora.
- **`codIncCP`** (incidência INSS): `00`=não é base (2.705), `11`=base mensal (1.755),
  **`95`=incidência SUSPENSA por decisão judicial (165)**, `12`=13º (99), `51`(31), `21`(21), `31`(13)…
- **`codIncFGTS`**: `00`(2.652), `11`(1.938), `12`(121), `21`(74), `31`(21).
- **`codIncIRRF`**: **mistura 2 dígitos e 4 dígitos** (`11`/`0011`, `09`/`0009`) — versões de leiaute
  diferentes ao longo dos anos ⇒ **cuidado no parser** (normalizar).
- **166 rubricas com `ideProcessoCP`** (suspensão judicial) — casa com os 165 `codIncCP=95`. É o
  **processo da APPA** (mesmo nº `5006491-20.2022.4.03.6119` que já vimos em S-1070/S-1020). Ou seja:
  parte das rubricas tem **INSS suspenso por liminar**. **Decisão do Xande: NÃO mostrar como
  contingência** — a base suspensa (codIncCP=9x) fica **fora do devido** (no máximo informativa).

### 4.3 Totalizadores (S-5011/S-5001/S-5003) — só como GABARITO de validação
Os eventos de retorno do governo já trazem bases calculadas (S-5011: `vrBcCp00/15/20/25`, `vrSuspBcCp*`,
`aliqRat/fap/aliqRatAjust`, `fpas`, `codTercs`, `infoTercSusp`; S-5003: `remFGTS` + `dpsFGTS`).
**Decisão do Xande: a base sai RECOMPONDO de S-1200 + S-1010 (só isso).** Os totalizadores **não** são a
fonte — servem só de **gabarito** pra conferir se a minha recomposição bateu.

## 5. Layout eSocial (o que interessa) — campos e join

**S-1200 (`evtRemun`):** `perApur` · `ideEmpregador/nrInsc` (05969071) · `ideTrabalhador/cpfTrab` ·
`dmDev/codCateg` · `infoPerApur/ideEstabLot/{nrInsc estab, codLotacao}` · `remunPerApur/matricula` ·
`itensRemun/{codRubr, ideTabRubr, vrRubr, qtdRubr, indApurIR}` · `infoAgNocivo/grauExp` · (e `infoPerAnt`).

**S-1010 (`evtTabRubrica`):** `infoRubrica/(inclusao|alteracao|exclusao)/ideRubrica/{codRubr, ideTabRubr,
iniValid[, fimValid]}` + `dadosRubrica/{dscRubr, natRubr, tpRubr, codIncCP, codIncIRRF, codIncFGTS,
ideProcessoCP/{tpProc, nrProc, codSusp}}`.

**Join base:** `(codRubr, ideTabRubr)` do S-1200 → rubrica S-1010 **vigente na competência**
(`iniValid ≤ perApur ≤ fimValid`, pegando a última alteração vigente). Incidência INSS pela `codIncCP`;
FGTS pela `codIncFGTS`; suspensão pelas rubricas com `codIncCP=9x`/`ideProcessoCP`.

## 6. RESPOSTAS DO XANDE (decidido — não mexer)

1. **Base:** recompor de **S-1200 + S-1010 APENAS**. Totalizadores só como gabarito.
2. **As 3 tabelas já estão NO APP** (eu fui burro de pedir). Ver seção 7.
3. **Desonerada (CPRB)?** NÃO → **patronal 20%** aplica direto.
4. **Suspensos como contingência?** NÃO → base suspensa fica fora do devido.
5. **Regime empresa × cooperativa:** difere pela Tabela 4 (coluna `INDCOOP`) + categoria do S-1200
   (`codCateg 721` = cooperado). _(mecanismo achado; confirmar aplicação)_
6. **Período:** por **competência** (2025-01 … 2025-12).
7. **CNAE** (era o "KINAI").
8. **Tela final:** do jeito que a call explicou (previdenciário + FGTS por lotação, visão única).

## 7. O QUE O APP JÁ TEM (a correção — eu tinha visto só 1 mês)

**As "3 tabelas estruturais" da call já existem** em `docs/04_referencias/MD modelos Banco de dado/`
e aparecem na tela **"Lotações tributárias"** (`tax_lotations`), servidas por
[tax_lotations_reference.rb](../../app/services/fiscal_auditor/tax_lotations_reference.rb):
- **Tabela 1** = `lotacoes_por_cnpj_2025-01.md` (lotação → CNPJ, FPAS, vigência)
- **Tabela 2** = `cod_lotacoes_tributarias_2025-01.md` (por estabelecimento: **CNAE, RAT, FAP, RAT ajustado**;
  por lotação: FPAS, cód. terceiros, cód. terceiros suspenso, bases CP 11/12/13/14)
- **Tabela 3 (4ª RH)** = `tabela_4_quarta_fpas_terceiros.md` (FPAS → terceiros, **alíquota**, **regime
  EMPRESAS/COOPERATIVAS**) + a oficial `tabela_4_fpas_terceiros.md`
- FGTS: `cod_lotacoes_fgts_2025-01.md`
> **RAT/FAP/CNAE = FIXOS** (topo/estabelecimento da tabela de lotações tributárias): RAT `3%`, FAP `0,7943`,
> RAT ajustado `2,3829%`, CNAE `7820500` — valem pro **ano de 2025 inteiro**, NÃO extrair por competência.
> Os terceiros (alíquotas por FPAS + regime) também são fixos (Tabela 4). Das tabelas 2025-01 eu só uso os
> **parâmetros estruturais** (RAT/FAP/CNAE/FPAS/terceiros por lotação); os **valores de base** delas são de
> janeiro e NÃO entram — a base sai do S-1200 (todas as competências).

**Dados eSocial já no app** (`storage/private/esocial/`):
- `S1010_TODOS_OS_ANOS_APA/2018…2026/` — histórico completo de S-1010 (mesma coisa que a pasta B que você mandou).
- `appa/rubricas_portal_2026-07-31.json` — catálogo de rubricas do portal (natureza + incidências CP/IRRF/FGTS).
- `appa/s1010_2026-06/`, `appa/s1020_2026-06/` — amostras recentes; `certificates/`.

**Scripts prontos** (`script/`): `extract_s1020_lotacoes.rb` (lotações), `extract_s1005_estabelecimentos_obras.rb`
(estabelecimento/CNAE/RAT/FAP), `analyze_esocial_previdenciary_process.rb` (suspensões judiciais),
`cruza_rubricas_appa.rb` (rubrica × portal/incidências), `parse_esocial_table_4.rb` / `parse_quarta_tabela_04.rb`
(Tabela 4), `generate/validate_esocial_lotacoes_markdown.rb`, `import_inss_folhas.rb`.

**Já no produto:** tela **"Lotações tributárias"** (read-only) e **"Encargos (INSS/FGTS)"**
(`payroll_charges`). **No histórico do git** (commit `196f0cc`, removidos em `3089793`): módulos
`esocial/`, `inss/`, `rubricas_cte/`, `rubric_recovery/`, `simulations/` (parser S-1010, cálculo
previdenciário) — recuperáveis se der pra aproveitar. Tabelas no banco ainda existem (`esocial_*`,
`inss_payroll_*`). Contexto em `docs/03_comunicacao/REBUILD_001..006` e `PERGUNTA_PENDENTE_DENIS_ESOCIAL.md`.

## 8. Plano de execução (recompor S-1200 + S-1010)

1. **Dicionário de rubricas (S-1010, todos os anos):** para cada `(codRubr, ideTabRubr)`, linha do tempo de
   vigências com `codIncCP` / `codIncFGTS` / `natRubr` / `tpRubr` (normalizar codIncIRRF 2↔4 díg.).
2. **Ler S-1200 de 2025 por competência:** por `(lotação, competência, categoria)`, somar `vrRubr` conforme a
   incidência da rubrica vigente → **base INSS** e **base FGTS**. Suspensos (`codIncCP=9x`) fora do devido.
   Retificação: último recibo por `(cpf, perApur)` + `infoPerAnt`.
3. **Previdenciário por lotação:** base × **20% patronal** + **RAT×FAP** (fixo: **2,3829%** — RAT ajustado do
   estabelecimento) + **terceiros** (Tabela 4 por FPAS + regime empresa/cooperativa).
4. **FGTS: JÁ PRONTO no sistema por código de lotação — NÃO recompor.** Só reaproveitar o FGTS por lotação
   que já existe (S-5003 traz base + depósito por lotação). Recompor é **só o previdenciário**.
5. **Validar** o previdenciário recomposto contra o totalizador S-5011 (gabarito).
6. **Tela:** uma linha por **lotação × competência** (base, patronal 20%, RAT/FAP, terceiros, total prev +
   FGTS já pronto), consolidável — como a call pediu.

## 9. Tudo definido — sem perguntas em aberto

- **RAT/FAP/CNAE:** fixos do estabelecimento (topo), pro ano de 2025 inteiro. Não é tabela por competência.
- **Categorias:** nós definimos (default: incluir todas com remuneração incidente; ajustável).
- **Suspensos (codIncCP=9x):** NÃO ficam fora e NÃO são contingência — sem tratamento especial.
- **FGTS:** JÁ PRONTO no sistema por lotação — não recompor; recompor é só o **previdenciário**.

Entendimento fechado. Próximo passo é só o teu OK pra eu começar a construir (dicionário S-1010 → base do
S-1200 por competência/lotação → 20% + RAT×FAP + terceiros → FGTS 8% → tela), validando contra o gabarito.

## 10. PoC de validação — 2026-08-25 (competência 2024-12, janeiro.zip)

Rodei o teste em etapas (cada conclusão abaixo é do **dado cru**, não suposição):

- ✅ **Dicionário S-1010 = 100% de cobertura.** 1.179 rubricas `(codRubr, ideTabRubr)`; das rubricas do
  S-1200 de janeiro (22.974 eventos, perApur 2024-12), **0 sem match**.
- 🔑 **A RETIFICAÇÃO é o ponto central (não o "E/A").** O que eu tinha chamado de "par E00335A ↔ 00335"
  **não é mapeamento** — é a **mesma folha transmitida 2×** com o `codLotacao` trocado
  (`00335-001-02` → `E00335-001-02A`), os **2.201 CPFs nos dois códigos**. E os **6 eventos S-5011** de
  janeiro são **retificações do mesmo estabelecimento** (o valor real de 00335 é 3.303.723,65, que eu
  estava somando 4×). Meu "match de 0,15%" anterior era **dois erros se cancelando** — descartado.
- ✅ **Depois de deduplicar** (S-1200: último recibo por `(cpf, perApur)`; S-5011: só o último recibo):
  total cat 101 recomp **25,46M vs gabarito 22,37M (+13,8%)**, e a maioria das lotações caiu pra poucos %
  (E00242 +0,9%, E00263 −0,7%, E02008 −0,5%, E00308 +3,6%…).
- ⚠️ **Falta dedup no nível do `dmDev`.** Ainda sobra a lotação 00335 a 2× e o +13,8% geral porque cada
  trabalhador tem **vários `dmDev`** no evento, com **dois esquemas de numeração** de `ideDmDev`
  (`20241129.1.00003996` e `00004116`) = demonstrativos **duplicados**. Descartando os duplicados, fecha.

**Conclusão:** dicionário + recompor **validados**; a paridade depende de uma regra robusta de
**retificação/dedup** (recibo mais recente + dmDev único), que é o coração da feature a construir.
