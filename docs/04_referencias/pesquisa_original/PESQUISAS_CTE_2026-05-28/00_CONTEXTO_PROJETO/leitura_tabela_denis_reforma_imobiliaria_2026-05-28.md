# Leitura da tabela Denis - Reforma Tributaria segmento imobiliario

Data: 2026-05-28

## Arquivo analisado

Arquivo original localizado em Downloads:

- `Tabela Reforma Tributaria segmento imobiliario adaptada a LC 2272026 (1).xlsx`

Arquivo salvo no projeto:

- `tabela_reforma_tributaria_segmento_imobiliario_lc227_2026.xlsx`

Hash SHA256 da versao copiada:

- `B41076ECDDAE2E43C81CBBD97BFC61FA439EFCC3BD1E694D17BEF167510AEA20`

## Leitura geral

A tabela e o documento norte inicial do recorte imobiliario/construcao civil. Ela confirma a leitura da call: o primeiro produto nasce pequeno, como um conjunto de abas para simular efeitos da reforma tributaria no setor imobiliario.

A planilha tem 15 abas. Ela mistura tres tipos de conteudo:

1. Mapa juridico-operacional das operacoes imobiliarias.
2. Catalogo de redutores, reducoes de aliquota e creditos.
3. Estruturas de calculo com exemplos praticos.

Importante: a planilha nao esta pronta como calculadora automatica completa. Em varias abas de calculo, as formulas estao na coluna `Formula`, enquanto a coluna `Valor` fica em branco. Isso indica que a planilha funciona como roteiro/modelo de calculo. Para virar sistema, precisamos transformar essas formulas em logica real de backend/frontend.

## Abas encontradas

1. `Tab operacoes segto imobiliario`
2. `Redutores sociais OperacaoValor`
3. `Reducoes de Aliquotas`
4. `creditos permtidos`
5. `Creditos Construcao Civil`
6. `Creditos adm_corretagem`
7. `Credito Cessao de direitos`
8. `Credito Permuta com Torna`
9. `Calculo Venda Imovel`
10. `Calculo Venda Lote Residencial`
11. `Calculo Locacao de imoveis`
12. `Calculo Construcao civil`
13. `Calculo Adm corretagem`
14. `Calculo Cessao de direitos`
15. `Calculo Permuta com torna`

## Mapa das abas

### 1. Operacoes do segmento imobiliario

Aba: `Tab operacoes segto imobiliario`

Colunas:

- Operacao
- Incidencia IBS/CBS
- Base Legal
- Base de Calculo

Operacoes mapeadas:

| Operacao | Incidencia | Base legal | Base de calculo |
| --- | --- | --- | --- |
| Venda de imovel/incorporacao | Sim | Art. 252 | Valor da operacao |
| Venda de lote residencial | Sim | Art. 252 | Valor da venda |
| Locacao de imoveis | Sim | Art. 254-255 | Aluguel sem IPTU/condominio |
| Construcao civil | Sim | Art. 252 | Valor do contrato |
| Administracao/corretagem | Sim | Art. 252 | Valor do servico |
| Cessao de direitos | Sim | Art. 252 | Valor da cessao |
| Permuta sem torna | Nao | Art. 252, excecao | Sem base |
| Permuta com torna | Parcial | Art. 252 | Valor da torna |

### 2. Redutores sociais

Aba: `Redutores sociais OperacaoValor`

Redutores cadastrados:

| Operacao | Redutor | Base legal | Aplicacao |
| --- | --- | --- | --- |
| Venda de imovel residencial | R$ 100.000 por unidade | Art. 259 | Deduz da base antes do imposto |
| Venda de lote residencial | R$ 30.000 por lote | Art. 259 | Deduz direto da base |
| Locacao residencial | R$ 600 por mes por imovel | Art. 260 | Deduz do aluguel para calcular IBS/CBS |

### 3. Reducoes de aliquotas

Aba: `Reducoes de Aliquotas`

Regras cadastradas:

| Tipo de operacao | Reducao de aliquota | Base legal |
| --- | --- | --- |
| Venda de imoveis/incorporacao | 50% | Art. 261 caput |
| Locacao / cessao / arrendamento | 70% | Art. 261, paragrafo unico |

Parametro usado nas simulacoes:

- Aliquota cheia IBS/CBS: 26,5%.

### 4. Creditos permitidos por operacao

Aba: `creditos permtidos`

Operacoes com creditos:

| Operacao | Creditos permitidos |
| --- | --- |
| Construcao civil | Insumos: materiais, servicos, energia |
| Administracao/corretagem | Despesas vinculadas a atividade |
| Cessao de direitos | Custos da operacao |
| Permuta com torna | Credito proporcional vinculado a operacao |

Base legal informada:

- Art. 12 e regra geral de nao cumulatividade IBS/CBS.

### 5. Catalogo de creditos - construcao civil

Aba: `Creditos Construcao Civil`

Itens cadastrados:

- Cimento - NCM 2523.29.90
- Vergalhao de aco - NCM 7214.20.00
- Tubos de PVC - NCM 3917.23.00
- Cabos eletricos - NCM 8544.49.00
- Tintas e vernizes - NCM 3208.90.10
- Ceramica / revestimento - NCM 6907.21.00
- Portas de madeira - NCM 4418.20.00
- Vidros planos - NCM 7005.29.00
- Servicos de engenharia - servico
- Energia eletrica - NCM 2716.00.00

### 6. Catalogo de creditos - administracao/corretagem

Aba: `Creditos adm_corretagem`

Itens cadastrados:

- Softwares de gestao imobiliaria
- Servicos de marketing/publicidade
- Servicos juridicos
- Servicos contabeis
- Energia eletrica
- Equipamentos de informatica
- Telefonia e internet
- Aluguel de escritorio
- Material de escritorio
- Veiculos para visitacao de imoveis, se vinculados

### 7. Catalogo de creditos - cessao de direitos

Aba: `Credito Cessao de direitos`

Itens cadastrados:

- Taxas contratuais e custos de cessao
- Servicos juridicos
- Servicos de corretagem vinculados
- Servicos contabeis
- Consultoria imobiliaria
- Energia eletrica vinculada
- Equipamentos de informatica
- Software de gestao imobiliaria
- Despesas administrativas vinculadas
- Marketing vinculado a cessao

### 8. Catalogo de creditos - permuta com torna

Aba: `Credito Permuta com Torna`

Itens cadastrados:

- Servicos juridicos na permuta
- Servicos de corretagem
- Consultoria imobiliaria
- Servicos contabeis
- Energia eletrica
- Equipamentos de informatica
- Software de gestao imobiliaria
- Despesas administrativas vinculadas
- Marketing da operacao
- Custos financeiros vinculados a torna

## Estruturas de calculo

### Venda de imovel

Aba: `Calculo Venda Imovel`

Formula-base:

```text
base_calculo = valor_venda - 100000
aliquota_efetiva = aliquota_cheia * (1 - 0.50)
imposto_devido = base_calculo * aliquota_efetiva
```

Exemplo da planilha:

- Valor da venda: R$ 500.000
- Redutor: R$ 100.000
- Base: R$ 400.000
- Aliquota cheia: 26,5%
- Reducao: 50%
- Aliquota efetiva: 13,25%
- Imposto devido: R$ 53.000

### Venda de lote residencial

Aba: `Calculo Venda Lote Residencial`

Formula-base:

```text
base_calculo = valor_venda - 30000
aliquota_efetiva = aliquota_cheia * (1 - 0.50)
imposto_devido = base_calculo * aliquota_efetiva
```

Exemplo da planilha:

- Valor da venda: R$ 200.000
- Redutor: R$ 30.000
- Base: R$ 170.000
- Aliquota cheia: 26,5%
- Reducao: 50%
- Aliquota efetiva: 13,25%
- Imposto devido: R$ 22.525

### Locacao de imoveis

Aba: `Calculo Locacao de imoveis`

Formula-base indicada:

```text
base_bruta = aluguel - iptu - condominio
base_liquida = base_bruta - 600
aliquota_efetiva = aliquota_cheia * (1 - 0.70)
imposto_devido = base_liquida * aliquota_efetiva
```

Exemplo da planilha:

- Aluguel: R$ 3.000
- IPTU: R$ 300
- Condominio: R$ 500
- Base bruta informada no exemplo: R$ 3.000
- Redutor social: R$ 600
- Base final: R$ 2.400
- Aliquota cheia: 26,5%
- Reducao: 70%
- Aliquota efetiva: 7,95%
- Imposto devido: R$ 190,80

Observacao: ha inconsistencia aparente. A formula indica excluir IPTU e condominio, mas o exemplo usa base bruta de R$ 3.000, sem deduzir IPTU e condominio. Precisa validar com Denis.

### Construcao civil

Aba: `Calculo Construcao civil`

Formula-base:

```text
base_calculo = valor_contrato
debito_ibs_cbs = base_calculo * aliquota_cheia
imposto_liquido = debito_ibs_cbs - creditos
```

Exemplo da planilha:

- Valor do contrato: R$ 1.000.000
- Base: R$ 1.000.000
- Aliquota cheia: 26,5%
- Debito IBS/CBS: R$ 265.000
- Creditos: R$ 150.000
- Imposto liquido: R$ 115.000

### Administracao/corretagem

Aba: `Calculo Adm corretagem`

Formula-base:

```text
base_calculo = valor_servico
debito_ibs_cbs = base_calculo * aliquota_cheia
imposto_liquido = debito_ibs_cbs - creditos
```

Exemplo da planilha:

- Valor do servico: R$ 50.000
- Base: R$ 50.000
- Aliquota: 26,5%
- Debito IBS/CBS: R$ 13.250
- Creditos: R$ 5.000
- Imposto liquido: R$ 8.250

### Cessao de direitos

Aba: `Calculo Cessao de direitos`

Formula-base na aba:

```text
base_calculo = valor_cessao
debito_ibs_cbs = base_calculo * aliquota_cheia
imposto_liquido = debito_ibs_cbs - creditos
```

Exemplo da planilha:

- Valor do servico/cessao: R$ 50.000
- Base: R$ 50.000
- Aliquota: 26,5%
- Debito IBS/CBS: R$ 13.250
- Creditos: R$ 5.000
- Imposto liquido: R$ 8.250

Observacao: a aba de reducoes diz que `locacao / cessao / arrendamento` tem reducao de 70%, mas a aba de calculo de cessao aplica aliquota cheia, sem reducao. Precisa validar.

### Permuta com torna

Aba: `Calculo Permuta com torna`

Formula-base:

```text
base_calculo = valor_torna
imposto_liquido = (base_calculo * aliquota_cheia) - creditos
```

Exemplo da planilha:

- Valor do imovel A: R$ 500.000
- Torna paga: R$ 50.000
- Base tributavel: R$ 50.000
- Aliquota: 26,5%
- Debito IBS/CBS: R$ 13.250
- Creditos: R$ 2.000
- Imposto liquido: R$ 11.250

## O que isso vira no sistema

### Abas/telas iniciais do recorte imobiliario

O MVP pode nascer com estas abas maiores:

1. Visao geral do recorte imobiliario.
2. Operacoes tributadas.
3. Redutores sociais.
4. Reducoes de aliquota.
5. Creditos permitidos.
6. Simulador de venda de imovel.
7. Simulador de venda de lote.
8. Simulador de locacao.
9. Simulador de construcao civil.
10. Simulador de administracao/corretagem.
11. Simulador de cessao de direitos.
12. Simulador de permuta com torna.

### Parametros do sistema

Parametros globais:

- aliquota cheia IBS/CBS, inicial 26,5%;
- redutor venda imovel residencial, inicial R$ 100.000;
- redutor venda lote residencial, inicial R$ 30.000;
- redutor locacao residencial, inicial R$ 600;
- reducao venda/incorporacao, inicial 50%;
- reducao locacao/cessao/arrendamento, inicial 70%.

Esses parametros precisam ser editaveis, porque a propria call diz que a aliquota cheia e parametrizavel e pode mudar.

### Inputs do usuario

Inputs por operacao:

- tipo de operacao;
- valor da operacao;
- quantidade de unidades/lotes, quando aplicavel;
- valor mensal de aluguel;
- IPTU e condominio, quando aplicavel;
- valor de contrato;
- valor da torna;
- creditos informados;
- despesas vinculadas;
- materiais/servicos/energia com potencial de credito.

### Outputs do sistema

Outputs minimos:

- base de calculo bruta;
- redutor aplicado;
- base de calculo liquida;
- aliquota cheia;
- reducao aplicada;
- aliquota efetiva;
- debito IBS/CBS;
- creditos aproveitaveis;
- imposto liquido a pagar;
- observacoes de risco/validacao.

## Pontos que precisam voltar para Denis

1. A planilha esta nomeada como adaptada a LC 227/2026, mas varias abas citam `LC 214/2025`. Confirmar qual e a base legal correta e se os artigos 252, 254, 255, 259, 260 e 261 estao na lei certa.
2. A aba de locacao diz que IPTU e condominio nao entram na base, mas o exemplo nao deduz esses valores. Confirmar formula correta.
3. A reducao de 70% para cessao aparece na aba de reducoes, mas o calculo de cessao usa aliquota cheia. Confirmar se cessao de direitos deve aplicar reducao.
4. Confirmar se construcao civil realmente nao tem reducao de aliquota no modelo, apenas creditos.
5. Confirmar se administracao/corretagem usa aliquota cheia sem redutor/reducao.
6. Confirmar se todos os creditos listados sao automaticamente aproveitaveis ou se dependem de documento, vinculacao direta e destaque do imposto na aquisicao.
7. Confirmar se o sistema deve permitir que o usuario cadastre novos itens de credito por NCM/servico.
8. Confirmar se a base de calculo nunca pode ficar negativa apos redutor. O sistema provavelmente deve aplicar `max(0, base - redutor)`.
9. Confirmar como tratar creditos maiores que o debito: carregar saldo, zerar imposto do periodo, ou apenas mostrar credito excedente.
10. Confirmar se permuta sem torna deve aparecer apenas como informativa/nao tributada ou se precisa de simulador proprio.

## Conclusao

A tabela do Denis e suficiente para iniciar o MVP do recorte imobiliario da reforma tributaria. Ela da a espinha dorsal: operacoes, redutores, reducoes, creditos e formulas. Antes de transformar em sistema, os pontos de inconsistencia precisam ser validados, principalmente LC 214 vs LC 227, locacao com IPTU/condominio e reducao aplicavel a cessao de direitos.
