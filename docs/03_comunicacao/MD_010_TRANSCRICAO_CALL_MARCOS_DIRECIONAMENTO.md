# Call com Marcos - direcionamento do produto eSocial/TributaLab

Data do registro: 2026-06-12  
Fonte: transcricao enviada pelo usuario a partir de reuniao gravada.  
Participantes inferidos: Marcos (`SPEAKER_00`) e Xandao/produto (`SPEAKER_01`).  
Status: transcricao revisada para leitura tecnica, com correcoes obvias de termos do dominio.

## Correcoes aplicadas

- `isis social`, `ISO Social`, `facil social` e variacoes foram normalizadas para `Easy Social` quando o contexto indicava o sistema/projeto.
- `e social`, `E-Social` e variacoes foram normalizadas para `eSocial`.
- `KINAI`, `KINAIs`, `CNAS` e variacoes foram normalizadas para `CNAE`/`CNAEs` quando o contexto era atividade economica.
- `FPS`/`FPA` foi normalizado para `FPAS` quando o contexto era lotacao tributaria.
- `Gilrath`, `Gilrat` e variacoes foram normalizadas para `GILRAT`; `RAT ajustado` foi mantido quando o contexto era ajuste por FAP.
- Eventos foram padronizados como `S-1000`, `S-1005`, `S-1010`, `S-1020`, `S-1200`, `S-1210`, `S-5002`.
- `CT`, quando o contexto era a empresa/caso em analise, foi padronizado como `CTE`.
- Trechos com audio ou termo incerto foram mantidos com observacao `a confirmar`.

## Transcricao revisada

### 00:00 - Cruzamento de rubricas

**Marcos:** A gente vai pegar o numero deles e talvez a descricao, e fazer esse enquadramento para avaliar se a natureza da rubrica que nos interpretamos esta de acordo com a deles. Se nao estiver, isso e divergencia. Essas validacoes que a gente vai fazer precisam, na verdade, dos dados completos: uma tabelinha para a gente conseguir cruzar tudo.

**Xandao:** Eu perdi muito tempo nessa briga tentando puxar esse negocio via API, mas agora a gente entendeu exatamente. Voce estava desenhando uma tabela, tipo uma aba certinha. Voce pode explicitar exatamente o que a gente quer de cada uma delas para montar essa tabela? Vamos recapitular aproveitando que esta gravando, que eu ja envio e a gente ja faz esse gerador de tabela bonito.

### 01:15 - S-1000: empregador

**Marcos:** Para a parte da tabela do empregador, esse e o evento `S-1000`. A gente vai pegar CNPJ, razao social, CNAE ou CNAEs. As vezes nao e so o CNAE principal que eles tem enviado; tem secundarios tambem.

**Xandao:** No caso que a gente olhou da CTE, citava so o primario.

**Marcos:** Isso e o padrao tradicional. Mas tem empresas que acabam tendo outros CNAEs.

**Xandao:** Eu lembro que, quando a gente olhou APA, Solucoes e Objetivo, elas citavam um CNAE primario e uns tres, quatro, cinco ou seis secundarios.

**Marcos:** Entao, a natureza juridica da empresa e tudo isso teoricamente estao no cartao CNPJ e, teoricamente, na base do eSocial. Com esses dados a gente ja consegue trabalhar logicas de validacao.

### 02:59 - S-1005 e S-1020: estabelecimento e lotacao tributaria

**Marcos:** O ponto aqui e separar os eventos corretamente: o `S-1005` traz estabelecimento/obras e aliquotas como FAP, GILRAT e RAT ajustado; o `S-1020` traz lotacao tributaria, FPAS e codigo de terceiros.

**Xandao:** FAP ou FPAS?

**Marcos:** Tem FPAS tambem, mas a gente precisa separar: o `S-1020` traz a lotacao tributaria e o FPAS; o `S-1005` traz estabelecimento, obras e aliquotas como GILRAT/FAP/RAT ajustado.

**Xandao:** Entendi. Eu estava olhando errado e me confundindo. A tabela `S-1020` e lotacao tributaria. A `S-1005` e estabelecimentos/obras. No caso da CTE, a gente esta trazendo FAP, RAT e ajuste na tabela `S-1005`.

**Marcos:** Isso. O `S-1005` detalha matriz, filiais, obras e aliquotas do GILRAT. A `S-1020` e a tabela de lotacoes tributarias.

**Xandao:** Entao ficou certo. Eu achei que tinha feito tudo errado, mas a `S-1020` esta mesmo como lotacao tributaria e a `S-1005` como estabelecimento.

### 06:00 - S-1010: rubricas e linha do tempo

**Marcos:** A `S-1010` e a tabela de rubricas.

**Xandao:** E a rubrica que a gente pegou pelos envios do eSocial deles, certo?

**Marcos:** Sim. Como a gente vai acessar a base declarada, vamos pegar de la. Os eventos declarados no eSocial sao o equivalente padronizado daqueles Excels que recebemos, so que os Excels vem fora de padrao. O eSocial organiza isso.

**Xandao:** Entendi. A `S-1010` que a gente fala de rubricas e basicamente a tabela que vamos montar com todas as `S-1010` enviadas de 2018 ate hoje, como aquele arquivo que eu separei.

**Marcos:** E isso. E a montagem do cenario. A gente precisa ter a linha do tempo, porque nem toda rubrica vale ate hoje. Tem rubrica excluida, tem data de expiracao.

**Xandao:** Entendi. Entao, na tabela das `S-1010`, vamos construir o historico com os envios de 2018 ate hoje, respeitando vigencia, expiracao e exclusoes.

### 07:37 - Confirmacao da S-1020

**Xandao:** Aqui eu estava chamando a `S-1020` de lotacao tributaria.

**Marcos:** Esta certo. E tabela de lotacao tributaria mesmo.

**Xandao:** A `S-1005` e estabelecimento/obras. Vou chamar de estabelecimento. Beleza. Na `S-1020`, ela identifica o FPAS, que e o principal, o FPAS vigente, com as mudancas ao longo do tempo. Entao vou trazer o FPAS vigente com data.

**Marcos:** Tem o codigo de terceiros tambem. Ele e importante.

**Xandao:** Sim. Aqui ele traz automatico o codigo de terceiros; no caso da CTE, apareceu `0115`.

### 09:45 - S-1200, S-1210 e totalizadores

**Marcos:** Depois a `S-1200`, que traz base de INSS.

**Xandao:** Entao entra funcionario, nome, CPF, e os dados relacionados a base de INSS, valores e rubricas.

**Marcos:** Exato. E tambem a base de FGTS. Estou achando que o fundo de garantia ja e contemplado na `S-1200`, entao precisamos colocar base de FGTS na `S-1200`.

**Marcos:** A `S-1210` e Imposto de Renda.

**Xandao:** A `S-1210` traz bastante informacao: incidencia de Imposto de Renda, plano de saude, pensao e valores relacionados.

**Marcos:** Isso. Tudo que estiver dentro da `S-1210`.

**Xandao:** A ideia e fazer a tabela completa primeiro, depois limpar e deixar os dados que a gente quer usar. Tambem podemos trazer totalizadores, como `S-5002` e outros totalizadores, para conferencia.

**Marcos:** Sim.

### 12:11 - Primeiro objetivo: construir os dados declarados

**Marcos:** Aqui nos construimos os dados deles, correto?

**Xandao:** De cada empresa que entrar, a gente vai puxar isso pelo proprio eSocial/XML, parametrizar com script automatico e comecar a trabalhar com isso.

**Marcos:** Quando tivermos todas essas informacoes, vamos comecar a construir a nossa logica para validar com o resultado que trouxemos deles.

**Xandao:** Hoje, em tese, eu ja consigo puxar tudo isso; o programa analisa esses eventos e tambem os totalizadores. So nao consigo ainda amarrar e criar exatamente nesse formato de tabela que voce pediu.

### 13:14 - Logica propria de enquadramento

**Marcos:** Agora vem a nossa parte. E bom voce ja ter isso em mente para comecar a verificar a melhor logica para aplicar. Vou chamar de `ACE` [termo a confirmar]. No `S-1000`, a gente pega CNAE e natureza juridica.

**Xandao:** A natureza nao importa tanto?

**Marcos:** A sequencia e primeiro o CNAE. Quando tiver cooperativa, por exemplo, pode ser o mesmo CNAE, e ai entra a natureza juridica. Primeiro e o CNAE mesmo.

**Marcos:** Pela descricao da atividade economica ate seria possivel fazer um enquadramento mais refinado, por exemplo diferenciando criacao de camaroes em agua salgada e salobra, mas acho que no inicio vamos trabalhar so com codigo.

**Marcos:** A partir do CNAE, conseguimos enquadrar o FPAS. O CNAE vem no `S-1000`. Para o enquadramento do FPAS, vamos usar a logica do RealPrev, que ja faz isso. Nao ha necessidade de criar outra logica.

**Xandao:** Entao vamos herdar a logica do RealPrev para enquadramento.

**Marcos:** Sim. Posso pegar so a parte da filtragem que faz esse enquadramento, e a gente monta o calculo em cima disso.

### 19:57 - Calculo previdenciario revisado

**Marcos:** A partir desse enquadramento, chegamos nas aliquotas previdenciarias: os 20% tradicionais da contribuicao patronal, mais FAP, GILRAT/RAT ajustado e terceiros. Para terceiros, quando enquadrar, algumas empresas terao SESI, outras SENAI, cada uma com seu percentual.

**Marcos:** Assim montamos a estrutura do INSS. O resultado sera validado com a `S-1200`.

**Xandao:** Entendi. Nao olhamos so totalizador; a validacao principal passa pela `S-1200`.

**Marcos:** Isso. Essa validacao pode apontar divergencias ou nao.

**Xandao:** Em tese, o ideal e que apareca que eles estao pagando a mais, para conseguirmos recuperar.

**Marcos:** Sim. Essa e a tese. O nosso enquadramento tambem traz o percentual de participacao.

### 22:55 - Receita Federal e base de calculo revisada

**Marcos:** Vamos fazer algo parecido com Receita Federal, mas a sistematica e mais simplificada. Vamos trabalhar com base de calculo.

**Marcos:** Para montar a base de calculo, vamos pegar a informacao financeira deles com a tabela de rubricas revisada.

**Xandao:** A tabela de rubricas revisada e um trabalho que vai estar dentro do Easy Social.

**Marcos:** Isso. Com essa tabela revisada, pegamos os eventos que eles declararam e montamos uma nova base de calculo. A partir dessa base de calculo, chegamos na parte da Previdencia e tambem na parte do Imposto de Renda.

**Xandao:** Entendi. As aliquotas previdenciarias dependem do enquadramento correto das rubricas anteriormente.

**Marcos:** Exato. Revisamos as rubricas e, a partir delas, pegamos os eventos da `S-1200` para montar a base de calculo revisada. Essa base pode ser igual ou diferente da base deles. Eu acredito que vamos encontrar divergencias. A partir dessa base, fazemos o calculo previdenciario como deveria ser.

### 25:12 - Fases do produto

**Marcos:** E uma coisa grande, por isso o ideal e fazer por partes. Primeiro construimos a estrutura. Depois vem a fase 2, que e a parte do Easy Social.

**Xandao:** Entao eu preciso da base de dados exatamente desse jeito que voce desenhou.

**Marcos:** A fase 3 e o cruzamento, onde montaremos os relatorios de diagnostico.

**Xandao:** A fase 3 e a consultoria em si.

**Marcos:** Exatamente. A Receita Federal e o INSS faziam isso in loco: iam ate a empresa, pegavam o plano de contas, avaliavam incidencias e remontavam. Hoje a fiscalizacao faz isso eletronicamente. O que vamos planejar aqui e uma auditoria preventiva antes da fiscalizacao, para que a empresa saiba os apontamentos, as correcoes necessarias e possiveis creditos que podera recuperar para compensar nas proximas guias.

### 27:21 - Encaminhamento imediato

**Xandao:** Agora o produto tem direcao para acontecer. A gente ja tem logicas em outros aplicativos.

**Marcos:** Sim. Vou pegar a parte que faz o enquadramento e ja montamos o codigo estruturado.

**Xandao:** Eu vou te mandar as tabelas que o sistema gerar. As tabelas atuais estao vazias porque os dados nao foram puxados, e talvez estejam trazendo coisa demais. Com essa conversa, entendi exatamente o que precisa trazer. Hoje ainda tento te mandar essas tabelas.

**Marcos:** Tranquilo. Sei que ha urgencia.

**Xandao:** A CTE esta esperando a gente dizer algo. Vou fazer as tabelas e te aviso.

### 29:00 - Observacao final do Xandao sobre arquitetura

**Xandao:** Hoje temos um aplicativo chamado Easy Social V2. Ele foi utilizado para APA, Solucoes e Objetivo. Nessas empresas foram feitos enquadramentos de rubricas e envios `S-1210` na readequacao, tudo com a tecnologia do Easy Social V2.

**Xandao:** Hoje tambem existe o TributaLab, outro repositorio. A ideia era usar o TributaLab como um modulo dentro do Easy Social. Em tese, talvez seja necessario criar o Easy Social V3: um novo repositorio com tudo que tem no V1, tudo que tem no V2 e tambem o PrevLab/TributaLab junto.

## Direcionamento final entendido

O ponto central da reuniao e uma mudanca de paradigma: nao tratar o eSocial como uma API que devolve respostas prontas para a aplicacao. O caminho pratico e montar uma base propria a partir dos XMLs/eventos oficiais declarados, transformar esses eventos em tabelas padronizadas e entao aplicar a logica de auditoria.

O eSocial entra como fonte padronizada dos eventos declarados. O produto nao depende de uma resposta analitica pronta do webservice; depende de conseguir importar, organizar e interpretar os XMLs corretos.

## Tabelas que precisam ser montadas

### 1. S-1000 - Empregador

Objetivo: montar o perfil cadastral da empresa.

Campos citados ou implicados:

- CNPJ.
- Razao social.
- CNAE principal.
- CNAEs secundarios, quando existirem.
- Natureza juridica.
- Vigencia do evento.
- Recibo/evento de origem.

Uso na logica:

- O CNAE e o primeiro driver do enquadramento.
- A natureza juridica entra como criterio complementar em casos especificos, como cooperativas.
- A partir do CNAE, a logica herdada do RealPrev deve sugerir FPAS e codigos de terceiros esperados.

### 2. S-1005 - Estabelecimentos/obras

Objetivo: mapear estabelecimentos, obras, matriz/filiais e aliquotas associadas.

Campos citados ou implicados:

- Tipo e numero de inscricao do estabelecimento/obra.
- Identificacao de matriz, filial ou obra.
- CNAE preponderante, quando disponivel.
- GILRAT/RAT.
- FAP.
- RAT ajustado.
- Vigencia.
- Recibo/evento de origem.

Uso na logica:

- Alimentar o calculo previdenciario revisado.
- Comparar parametros declarados com parametros esperados pela logica de enquadramento.

### 3. S-1010 - Rubricas

Objetivo: montar a linha do tempo completa da tabela de rubricas da empresa.

Campos citados ou implicados:

- Codigo/numeral da rubrica.
- Descricao da rubrica.
- Natureza da rubrica declarada pela empresa.
- Incidencias previdenciarias, IRRF e FGTS.
- Inicio e fim de validade.
- Status: inclusao, alteracao ou exclusao.
- Recibo/evento de origem.

Uso na logica:

- Comparar a natureza/incidencia declarada pela empresa com a natureza/incidencia interpretada pela consultoria.
- Identificar divergencias de enquadramento.
- Montar a tabela de rubricas revisada, que sera usada para recalcular bases de INSS, FGTS e IRRF.

### 4. S-1020 - Lotacoes tributarias

Objetivo: mapear lotacoes tributarias e seus parametros de FPAS/terceiros.

Campos citados ou implicados:

- Codigo da lotacao.
- FPAS vigente.
- Data/vigencia do FPAS.
- Codigo de terceiros.
- Suspensoes/processos, quando houver.
- Tipo de lotacao.
- Recibo/evento de origem.

Uso na logica:

- Validar o FPAS declarado.
- Validar o codigo de terceiros declarado.
- Comparar com o enquadramento esperado pela logica RealPrev a partir do CNAE/natureza.

### 5. S-1200 - Remuneracao do trabalhador

Objetivo: capturar os valores declarados por trabalhador e por rubrica.

Campos citados ou implicados:

- CPF do trabalhador.
- Nome/identificacao do trabalhador, se disponivel na fonte complementar.
- Periodo de apuracao.
- Rubricas e valores.
- Bases de INSS.
- Bases de FGTS.
- Lotacao/estabelecimento relacionado.
- Recibo/evento de origem.

Uso na logica:

- Principal fonte de validacao do calculo previdenciario.
- Base para remontar o calculo com a tabela de rubricas revisada.

### 6. S-1210 - Pagamentos e IRRF

Objetivo: capturar pagamentos, retencoes, deducoes e informacoes relacionadas ao Imposto de Renda.

Campos citados ou implicados:

- CPF do trabalhador/beneficiario.
- Periodo de pagamento.
- Valores pagos.
- IRRF.
- Plano de saude.
- Pensao.
- Outras deducoes/informacoes financeiras do evento.
- Recibo/evento de origem.

Uso na logica:

- Base para revisao de IRRF.
- Cruzamento com a tabela de rubricas revisada e com os eventos financeiros.

### 7. Totalizadores

Objetivo: usar como conferencia, nao como unica fonte de verdade.

Eventos citados:

- `S-5002`.
- Outros totalizadores a confirmar conforme disponibilidade e utilidade.

Uso na logica:

- Conferir resultados calculados.
- Apoiar conciliacao.
- Nao substituir a leitura detalhada dos eventos originais.

## Logica de produto proposta

### Fase 1 - Cenario declarado pela empresa

Montar tabelas padronizadas a partir dos eventos do eSocial/XML:

- Cadastro da empresa (`S-1000`).
- Estabelecimentos/obras (`S-1005`).
- Rubricas com linha do tempo (`S-1010`).
- Lotacoes tributarias (`S-1020`).
- Remuneracoes e bases (`S-1200`).
- Pagamentos/IRRF (`S-1210`).
- Totalizadores como conferencia.

Resultado esperado: uma base normalizada que represente exatamente o que a empresa declarou.

### Fase 2 - Cenario revisado pela consultoria

Aplicar logicas proprias:

- Reenquadrar rubricas pela interpretacao tecnica.
- Herdar do RealPrev a logica de enquadramento CNAE -> FPAS -> terceiros.
- Considerar natureza juridica quando o CNAE nao resolver sozinho.
- Reconstruir bases de INSS, FGTS e IRRF com a tabela revisada.
- Calcular contribuicao patronal, GILRAT/RAT ajustado, FAP e terceiros conforme o enquadramento esperado.

Resultado esperado: uma base recalculada com o que a consultoria entende como correto.

### Fase 3 - Cruzamento e diagnostico

Comparar o declarado com o revisado:

- Base declarada x base recalculada.
- Rubrica declarada x rubrica revisada.
- FPAS/codigo de terceiros declarado x esperado.
- Aliquotas declaradas x aliquotas esperadas.
- Valores pagos/recolhidos x valores devidos.

Resultado esperado: relatorio de divergencias, riscos, correcoes necessarias e possiveis creditos recuperaveis.

## Implicacoes para o TributaLab

1. O foco imediato deve voltar para XML/ZIP e parsing, nao para insistir em resposta direta de API.
2. As telas precisam sempre declarar a fonte do dado: XML importado, XML baixado oficialmente, CSV extraido, totalizador ou dado complementar.
3. A tabela de rubricas `S-1010` deve ser historica, nao apenas o estado atual.
4. A aplicacao precisa separar duas bases: `declarado pela empresa` e `revisado pela consultoria`.
5. O motor de divergencias deve nascer do cruzamento entre essas duas bases.
6. O RealPrev deve ser tratado como fonte da regra de enquadramento CNAE/FPAS/terceiros.
7. O Easy Social V2 ja provou parte do fluxo operacional em APA, Solucoes e Objetivo; o novo desenho deve reaproveitar essa experiencia.
8. Faz sentido avaliar um `Easy Social V3` consolidando V1, V2 e TributaLab/PrevLab, mas isso deve ser uma decisao de arquitetura depois que a modelagem das tabelas estiver clara.

## Pontos de atencao

- Confirmar se o `S-1000` traz todos os CNAEs secundarios necessarios em todos os casos; se nao trouxer, pode ser preciso importar fonte complementar do CNPJ.
- Confirmar exatamente quais totalizadores entram no MVP e quais ficam como conferencia posterior.
- Confirmar o significado do termo `ACE` citado por Marcos.
- Separar claramente `S-1005` de `S-1020` na UI e no banco: estabelecimento/obra nao e lotacao tributaria.
- Evitar depender do Download Cirurgico como unico caminho, por causa de limite diario, filtros sensiveis e dificuldade operacional.
- Preservar a rastreabilidade: toda linha de tabela deve apontar para XML, evento, recibo e periodo de vigencia.

## Proximos passos praticos

1. Criar/ajustar importador de XML/ZIP para aceitar pacotes oficiais por empresa.
2. Gerar as tabelas base da CTE para `S-1000`, `S-1005`, `S-1010`, `S-1020`, `S-1200` e `S-1210`.
3. Mostrar essas tabelas ao Marcos para validar colunas antes de aprofundar regra de calculo.
4. Mapear a regra RealPrev de CNAE -> FPAS -> terceiros e isolar em modulo reutilizavel.
5. Criar a camada `declarado x revisado` para rubricas primeiro, porque ela alimenta INSS, FGTS e IRRF.
6. Depois criar os relatorios de diagnostico e recuperacao.
