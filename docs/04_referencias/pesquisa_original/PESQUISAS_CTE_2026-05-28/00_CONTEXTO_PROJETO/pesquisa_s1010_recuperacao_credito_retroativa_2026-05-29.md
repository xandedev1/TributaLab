# Pesquisa: S-1010, rubricas e recuperacao retroativa de credito

Data: 2026-05-29

Objetivo: entender, com base em fontes oficiais e nas planilhas recebidas, como o historico de rubricas do eSocial S-1010 pode sustentar um produto de diagnostico e formacao de dossie para recuperacao de creditos decorrentes de incidencias indevidas em folha.

## Conclusao executiva

Da para usar o S-1010 como uma das pecas centrais de um radar de recuperacao, mas ele nao basta sozinho para pedir credito em valor liquido.

O S-1010 prova como a empresa cadastrou cada rubrica ao longo do tempo: natureza eSocial, tipo da rubrica, vigencia e codigos de incidencia para CP/INSS, IRRF e FGTS. Quando esse cadastro historico e cruzado com a Tabela 03 do eSocial, a Tabela EB, o `arquivo_enquadrado` e uma tese tecnica/legal, ele revela rubricas com possivel tributacao errada.

Para transformar esse indicio em credito recuperavel, o dossie precisa de tres camadas adicionais: valores pagos por competencia, declaracoes/recolhimentos efetivos e validacao juridica da tese por rubrica.

Em linguagem de produto: o TributaLab pode entregar primeiro um `Radar de Recuperacao de Rubricas`, com score, conflitos e trilha de evidencias. O produto so deve chamar de `credito estimado` quando houver folha/eventos periodicos e recolhimentos; e so deve chamar de `credito recuperavel` depois de validacao tecnica/juridica.

## Fontes oficiais consultadas

- Portal eSocial - Documentacao Tecnica: https://www.gov.br/esocial/pt-br/documentacao-tecnica
- Portal eSocial - Tabelas do eSocial: https://www.gov.br/esocial/pt-br/tabelas-do-esocial
- Receita Federal - DCTFWeb: https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/declaracoes-e-demonstrativos/DCTFWeb
- Receita Federal - Restituicao, Ressarcimento, Reembolso e Compensacao: https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/restituicao-ressarcimento-reembolso-e-compensacao
- Receita Federal - Creditos: https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/restituicao-ressarcimento-reembolso-e-compensacao/creditos
- Receita Federal - Meios para solicitar ou compensar cada tipo de credito: https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/restituicao-ressarcimento-reembolso-e-compensacao/meios-para-solicitar-ou-compensar-cada-tipo-de-credito
- Receita Federal - PGD PER/DCOMP: https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/restituicao-ressarcimento-reembolso-e-compensacao/perdcomp
- IN RFB 2005/2021, DCTF e DCTFWeb: https://normasinternet2.receita.fazenda.gov.br/#/consulta/externa/115131/visao/multivigente
- Lei 8.212/1991: https://www.planalto.gov.br/ccivil_03/leis/l8212cons.htm
- Lei 7.713/1988: https://www.planalto.gov.br/ccivil_03/leis/l7713.htm
- Lei 8.036/1990: https://www.planalto.gov.br/ccivil_03/leis/l8036consol.htm

Observacao: a pagina direta de `PER/DCOMP Web` nao retornou conteudo util no extrator, mas a area oficial de restituicao/compensacao da Receita retornou os caminhos de creditos, meios por tipo, PGD PER/DCOMP, consulta de processamento e roteiros.

## O que cada fonte oficial confirma

### eSocial / S-1010

O portal oficial do eSocial concentra leiautes, XSD, Manual de Orientacao do eSocial, Manual do Desenvolvedor e tabelas oficiais. Para o nosso caso, isso confirma que o S-1010 e a fonte tecnica de cadastro historico de rubricas.

Campos importantes para o produto:

- `ideTabRubr`: tabela de rubricas da empresa.
- `codRubr`: codigo interno da rubrica.
- `iniValid` / `fimValid`: vigencia da configuracao.
- `dscRubr`: descricao.
- `natRubr`: natureza da rubrica na Tabela 03 do eSocial.
- `tpRubr`: vencimento, desconto, informativa etc.
- `codIncCP`: incidencia de contribuicao previdenciaria.
- `codIncIRRF`: incidencia de IRRF.
- `codIncFGTS`: incidencia de FGTS.
- `nrRecibo` / recepcao: trilha oficial do envio.

Papel na recuperacao: o S-1010 mostra a regra declarada pela empresa em cada periodo. Ele e forte para descobrir uma rubrica cadastrada como tributavel quando a classificacao esperada indicaria nao incidencia, isencao, verba indenizatoria ou tratamento diferente.

Limite: o S-1010 nao mostra quanto foi pago naquela rubrica a cada trabalhador, nem prova que houve recolhimento. Para isso entram S-1200, S-2299, S-2399, S-1210, totalizadores, folha financeira, DCTFWeb/DARF/GPS e documentos de FGTS.

### DCTFWeb

A IN RFB 2005/2021 confirma pontos decisivos:

- A DCTFWeb e elaborada com base nas informacoes prestadas no eSocial e/ou EFD-Reinf.
- A DCTFWeb constitui confissao de divida e instrumento habil para exigencia dos creditos tributarios declarados.
- A declaracao pode ser retificada para declarar novos debitos, aumentar ou reduzir valores ja informados ou alterar creditos vinculados.
- O direito de retificar DCTF/DCTFWeb extingue-se em 5 anos, contados do primeiro dia do exercicio seguinte ao da declaracao, conforme regra da propria IN.
- A DCTFWeb substitui GFIP como instrumento de confissao de divida e constituicao do credito previdenciario a partir dos cronogramas aplicaveis.
- Para IRRF de relacao de trabalho, a DCTFWeb passa a substituir a DCTF em periodos especificos, com destaque para os fatos geradores de maio/2023 em diante na norma consultada.

Papel na recuperacao: depois de identificar a rubrica suspeita, a retificacao da escrituração/declaracao pode reduzir debitos declarados quando houver base documental. O valor pago indevidamente ou a maior pode seguir para restituicao/compensacao conforme o tipo de credito e o meio aplicavel.

### Contribuicao previdenciaria / INSS

A Lei 8.212/1991 e a fonte central para folha/previdencia:

- Art. 22: trata da contribuicao da empresa sobre remuneracoes pagas, devidas ou creditadas a segurados.
- Art. 28: define salario-de-contribuicao.
- Art. 28, paragrafo 9: lista parcelas que nao integram salario-de-contribuicao.
- Art. 32: obriga preparo de folha e declaracao de fatos geradores; a declaracao constitui confissao de divida e instrumento habil.
- Art. 89: contribuicoes sociais somente podem ser restituidas ou compensadas em caso de pagamento ou recolhimento indevido ou maior que o devido, nos termos da Receita Federal.

Papel na recuperacao: e a frente mais forte para o MVP. O S-1010 fornece `codIncCP`; a lei fornece o criterio de incidencia/não incidencia; DCTFWeb/DARF/GPS mostram o valor declarado/recolhido; PER/DCOMP ou meio equivalente fecha o pedido/compensacao.

### IRRF sobre folha

A Lei 7.713/1988 ajuda a separar rendimentos tributaveis, isentos e tratamentos especificos:

- Art. 3: IR incide sobre rendimento bruto, incluindo produto do trabalho e proventos.
- Art. 6: traz hipoteses de isencao, como determinadas verbas indenizatorias, diarias, alimentacao/transporte/uniformes fornecidos gratuitamente e outros casos.
- Art. 7: rendimentos do trabalho assalariado pagos por pessoa juridica ficam sujeitos ao IRRF.
- Art. 12-A: trata de rendimentos recebidos acumuladamente.

Papel na recuperacao: o S-1010 fornece `codIncIRRF` e a rubrica; a lei/tese indica se a verba deveria ou nao compor base de IRRF. A maior cautela aqui e economica/juridica: IRRF e imposto retido do beneficiario. Em muitos cenarios, o direito material pode ser do trabalhador, ou exigir ajuste especifico de folha/declaracao. Para o produto, esta frente deve aparecer como risco/oportunidade a validar, nao como compensacao automatica da empresa.

### FGTS

A Lei 8.036/1990 confirma:

- Art. 15: deposito de 8% sobre remuneracao paga ou devida no mes anterior, incluindo parcelas dos arts. 457 e 458 da CLT e 13o salario.
- Art. 15, paragrafo 6: nao integram remuneracao para fins de FGTS as parcelas elencadas no art. 28, paragrafo 9, da Lei 8.212.
- Art. 17: servicos digitais aos empregadores incluem procedimentos de restituicao e compensacao.
- Art. 17-A: declaracao por escrituracao digital constitui reconhecimento dos creditos e confissao de debito.

Papel na recuperacao: o S-1010 fornece `codIncFGTS` e ajuda a localizar rubrica com deposito indevido. Mas FGTS nao e credito administrado pela Receita Federal da mesma forma que contribuicao previdenciaria/IRRF; o fluxo deve ser tratado como trilha propria, com FGTS Digital/Caixa/MTE conforme periodo.

## Cadeia de prova recomendada

1. Identificar a versao da rubrica no S-1010.
   - Chave: empregador, `ideTabRubr`, `codRubr`, `iniValid`, `fimValid`.
   - Evidencia: XML, recibo, schema, ambiente e data de recepcao.

2. Classificar a natureza esperada.
   - Fontes: Tabela 03 eSocial, Tabela EB, `arquivo_enquadrado`, avaliacao tecnica.
   - Evidencia: natureza eSocial esperada, incidencia CP/IRRF/FGTS esperada, score e confianca.

3. Comparar declarado versus esperado.
   - Campos: `natRubr`, `tpRubr`, `codIncCP`, `codIncIRRF`, `codIncFGTS`.
   - Resultado: divergencia por tributo e por periodo de vigencia.

4. Buscar valores por competencia.
   - Fontes: folha financeira, S-1200, S-2299, S-2399, S-1210, totalizadores de retorno quando disponiveis.
   - Evidencia: trabalhador, competencia, rubrica, valor, base tributada e vinculo.

5. Confirmar declaracao e recolhimento.
   - INSS/CP: DCTFWeb/DARF ou, para periodos antigos, GFIP/GPS conforme obrigatoriedade.
   - IRRF: DCTF/DCTFWeb, DARF, DIRF/eSocial conforme periodo e obrigacao aplicavel.
   - FGTS: SEFIP/GRF, FGTS Digital, guias, extratos e declaracoes aplicaveis.

6. Calcular diferenca.
   - Base indevida por rubrica/competencia/trabalhador.
   - Aliquota efetiva aplicavel.
   - Valor recolhido a maior.
   - Atualizacao/juros somente depois de definida a regra juridica e o canal de recuperacao.

7. Preparar dossie e caminho administrativo.
   - Se Receita Federal: retificar escritura/declaracao quando necessario, depois PER/DCOMP ou meio indicado para o credito.
   - Se FGTS: fluxo proprio de restituicao/compensacao/devolucao no ambiente competente.
   - Registrar prova, justificativa, parecer e trilha de alteracao.

## Como isso conversa com as fontes locais da CTE

Fontes ja preservadas no pacote:

- `s1010_todos_os_anos_cte_2026-05-29.zip`: 2.018 XMLs S-1010, 1.083 `codRubr` unicos, 2018-2025.
- `tabela_eventos_rubricas_cte_2026-05-29.xlsx`: 464 eventos operacionais da CTE.
- `tabela_eb_2026-05-29.xlsx`: 1.033 rubricas, camada analitica/legal, 371 inconsistencias marcadas.
- `arquivo_enquadrado_2026-05-29.xlsx`: 464 eventos CTE cruzados com Tabela 03/eSocial, score, confianca e validacoes CP/IRRF/FGTS.

Papel pratico de cada uma:

- S-1010: historico oficial declarado pela empresa.
- CTE: linguagem operacional usada pelo cliente/consultoria.
- EB: leitura legal/analitica e base de divergencias.
- Arquivo enquadrado: ponte entre CTE e Tabela 03/eSocial.

Regra critica: nao cruzar por codigo isolado. O mesmo numero pode representar coisas diferentes em fontes diferentes. A chave minima deve considerar origem, tabela, codigo, descricao, natureza eSocial, incidencia, vigencia e contexto.

## Tributo por tributo: viabilidade inicial

### INSS / Contribuicao previdenciaria

Viabilidade: alta para MVP.

Motivo: S-1010 tem `codIncCP`; Lei 8.212 define salario-de-contribuicao e exclusoes; DCTFWeb nasce do eSocial e confessa debitos; Lei 8.212 art. 89 admite restituicao/compensacao em recolhimento indevido ou maior que o devido.

Produto recomendado: priorizar rubricas com divergencia entre `codIncCP` declarado e incidencia esperada, principalmente quando o `arquivo_enquadrado` trouxer confianca alta/media e a EB apontar base legal.

### IRRF

Viabilidade: media, com cautela.

Motivo: S-1010 tem `codIncIRRF`, e a Lei 7.713 traz regra de tributacao/isencao. A dificuldade e que IRRF e retencao do trabalhador/beneficiario; a recuperacao pode depender de quem suportou economicamente o tributo, de ajustes nas declaracoes e da natureza da verba.

Produto recomendado: mostrar como frente de risco/oportunidade, com separacao entre `possivel retencao indevida`, `impacto ao trabalhador`, `impacto empresa` e `requer parecer`.

### FGTS

Viabilidade: media para diagnostico, com canal separado.

Motivo: S-1010 tem `codIncFGTS`; Lei 8.036 liga FGTS a remuneracao e remete a exclusoes da Lei 8.212. Mas o caminho nao e PER/DCOMP/RFB. Precisa tratar FGTS Digital/Caixa/MTE e o periodo de ocorrencia.

Produto recomendado: calcular indicio e dossie separado, sem misturar com credito federal administrado pela Receita.

## Primeira tela recomendada para o TributaLab

Nome sugerido: `Radar de Recuperacao - Rubricas eSocial`.

Blocos:

- Volume analisado: rubricas S-1010, eventos CTE, rubricas EB, periodos cobertos.
- Divergencias por tributo: CP/INSS, IRRF, FGTS.
- Confianca do enquadramento: alta, media, baixa, muito baixa.
- Top rubricas por risco: codigo, descricao, natureza declarada, natureza esperada, incidencia declarada, incidencia esperada.
- Cobertura de evidencias: cadastro S-1010, base legal EB, valores de folha, declaracao/recolhimento, parecer.
- Status da oportunidade: indicio, em quantificacao, credito estimado, dossie pronto, protocolado.

Mensagem de produto importante: onde ainda nao houver folha e recolhimento, mostrar `potencial tecnico`, nao `credito em R$`.

## Modelo de dados sugerido

- `RubricSource`: origem do dado, hash, arquivo, data de carga.
- `RubricVersion`: empregador, tabela, codigo, descricao, natureza, incidencias, vigencia, recibo.
- `RubricMapping`: ligacao entre CTE, S-1010, EB e Tabela 03, com score/confiança.
- `LegalPosition`: tese, tributo, incidencia esperada, base legal, status de revisao.
- `PayrollOccurrence`: trabalhador, competencia, rubrica, valor, base informada.
- `TaxDeclaration`: DCTFWeb/DCTF/GFIP/FGTS, periodo, debito, credito, pagamento vinculado.
- `CreditOpportunity`: tributo, periodo, rubrica, valor potencial, confianca, pendencias.
- `EvidenceItem`: XML, planilha, DARF, GPS, guia FGTS, parecer, recibo, comprovante.
- `RecoveryCase`: dossie administrativo com eventos, calculo, documentos e status.

## Dados que ainda faltam para sair de radar e virar calculo

- Folha financeira por competencia com rubrica e valor.
- Eventos periodicos e de desligamento/pagamento: S-1200, S-2299, S-2399, S-1210.
- Totalizadores/retornos eSocial, quando disponiveis.
- DCTFWeb transmitidas, DARFs pagos e recibos.
- Para periodos anteriores ou fora da DCTFWeb: GFIP/GPS/SEFIP conforme caso.
- Para FGTS: guias, SEFIP/FGTS Digital, extratos e regras de devolucao/compensacao do periodo.
- Parecer/tese final por rubrica, principalmente para IRRF e verbas indenizatorias.

## Riscos e controles

- Risco de falso positivo: codigo numerico igual em fontes diferentes nao significa mesma rubrica.
- Risco juridico: verba semelhante pode ter tratamento diferente conforme acordo, natureza do pagamento, decisao judicial, periodicidade ou comprovacao.
- Risco de titularidade: em IRRF, o valor pode pertencer economicamente ao trabalhador.
- Risco declaratorio: retificar DCTFWeb/DCTF pode ser retido para analise e exigir prova documental.
- Risco operacional: FGTS tem canal proprio; nao tratar como PER/DCOMP federal comum.

Controles:

- Versionar cada fonte e guardar hash.
- Preservar XML original e recibos.
- Separar `indicio`, `credito estimado` e `credito validado`.
- Exigir base legal e evidencias antes de mudar status.
- Manter trilha de auditoria para toda alteracao de incidencia ou calculo.

## Proximo passo recomendado

1. Importar os XMLs S-1010 em uma tabela normalizada de `RubricVersion`.
2. Importar `arquivo_enquadrado` como camada inicial de `RubricMapping`.
3. Produzir o primeiro ranking de divergencias por CP/IRRF/FGTS, sem valores em R$.
4. Escolher 10 rubricas de maior confianca para dossie manual.
5. Pedir ao cliente folha/eventos/recolhimentos de um periodo piloto para calcular credito estimado.

## Frase norteadora

O S-1010 nao e o pedido de credito; ele e o mapa historico das regras de rubrica que permite encontrar onde a empresa provavelmente tributou errado. O credito nasce quando esse mapa encontra valor pago, declaracao/recolhimento e tese legal validada.