# Arquitetura inicial do sistema

Data: 2026-05-28

## Entendimento corrigido

O sistema nao nasce como dois modulos fechados chamados "recuperacao de credito" e "reforma tributaria imobiliaria". A arquitetura correta e em camadas.

Primeiro existem grandes tipos de trabalho:

1. Recuperacao de credito: olha para tras.
2. Reforma tributaria: olha para frente.

Depois, dentro de cada tipo, entram areas, setores ou recortes de analise.

O imobiliario e um desses recortes. Ele nao e o modulo principal do sistema inteiro. Ele e o primeiro recorte pratico a ser construido, em abas, porque conversa com a CTE e com a tabela/documento do Denis.

## Forma mental do sistema

```text
Sistema RealPrev / CTE
├── Recuperacao de credito
│   ├── Folha / eSocial / rubricas
│   ├── Imobiliario / construcao civil
│   ├── SPED / fiscal
│   └── outros recortes futuros
│
└── Reforma tributaria
    ├── Imobiliario / construcao civil
    ├── Locacao
    ├── Incorporacao
    ├── Venda de imoveis
    ├── Corretagem / administracao
    └── outros recortes futuros
```

## Escopo de agora

O foco imediato e construir aos poucos, com apenas o recorte imobiliario/construcao civil neste inicio.

Esse recorte deve funcionar em abas maiores, provavelmente derivadas da tabela do Denis. As abas iniciais devem representar operacoes, regras de calculo, redutores, aliquotas, creditos e simulacoes.

Nada indica que o sistema precisa nascer com todos os segmentos. A estrategia correta e:

1. Entender os dois grandes tipos: recuperacao e reforma.
2. Escolher um recorte inicial: imobiliario/construcao civil.
3. Transformar a tabela do Denis em estrutura de dados, regras e telas/abas.
4. Validar as duvidas com Denis.
5. Depois replicar o padrao para outros recortes.

## Recuperacao de credito

Trabalha com passado.

Fontes possiveis:

- historico de folha;
- eSocial;
- tabela de rubricas;
- totalizadores;
- SPED, quando o tema for fiscal;
- documentos de recolhimento;
- demonstrativos e memorias de calculo.

Objetivo:

- encontrar tributos pagos indevidamente;
- revisar incidencia de rubricas ou operacoes;
- calcular credito recuperavel;
- gerar memoria de recuperacao.

## Reforma tributaria

Trabalha com futuro.

Fontes possiveis:

- SPEDs;
- faturamento;
- tipos de operacao;
- NCM/servicos;
- despesas e creditos;
- dados operacionais preenchidos pela empresa;
- parametros legais de IBS/CBS.

Objetivo:

- simular impacto futuro;
- calcular imposto estimado;
- aplicar redutores e reducoes de aliquota;
- aplicar creditos permitidos;
- indicar adequacoes da empresa.

## Recorte imobiliario/construcao civil

Este e o primeiro recorte a ser implementado.

Operacoes citadas na call:

- venda de imovel;
- incorporacao;
- venda de lote;
- locacao de imoveis;
- construcao civil;
- administracao e corretagem;
- cessao de direitos;
- permuta sem torna;
- permuta com torna.

Regras citadas na call:

- redutor de base para imovel residencial, exemplo de R$100.000 por unidade;
- redutor para lote residencial, exemplo de R$30.000;
- redutor para locacao residencial, citado como R$600;
- aliquota cheia parametrizavel, citada como 26,5%;
- reducoes de aliquota por tipo de operacao;
- creditos permitidos para construcao civil, como materiais, servicos e energia;
- imposto liquido a pagar depois de creditos.

## Estrutura esperada das abas

A tabela/documento do Denis deve ser tratada como documento norte para identificar as abas reais. Pela call, ela deve conter algo como:

1. mapa de operacoes imobiliarias;
2. redutores de base de calculo;
3. reducoes de aliquota;
4. creditos permitidos;
5. calculo de venda de imovel;
6. calculo de lote;
7. calculo de locacao;
8. calculo de construcao civil;
9. simulacoes por operacao;
10. parametros legais e referencias.

O numero exato de abas deve ser confirmado quando o arquivo do Denis for enviado.

## Campos de calculo citados

Campos de entrada:

- tipo de operacao;
- valor da venda/contrato/locacao;
- quantidade de unidades;
- valor medio por unidade;
- despesas vinculadas;
- materiais comprados;
- servicos contratados;
- energia;
- creditos disponiveis;
- aliquota cheia parametrizada.

Campos calculados:

- redutor aplicavel;
- base de calculo reduzida;
- percentual de reducao de aliquota;
- aliquota efetiva;
- imposto bruto;
- creditos aproveitaveis;
- imposto liquido a pagar;
- comparativo/projecao futura.

## Decisoes importantes da call

- A recuperacao de credito e um tipo de trabalho voltado ao passado.
- A reforma tributaria e um tipo de trabalho voltado ao futuro.
- O imobiliario e um recorte/aba/submodulo, nao o modulo maior do sistema.
- O inicio deve ser pequeno: apenas imobiliario/construcao civil.
- A tabela do Denis e base inicial e ainda pode ser ampliada.
- A tabela tem cerca de 15 abas.
- A tabela deve gerar perguntas para Denis quando houver duvida.

## Status dos proximos insumos

- Call com Denis: salva em `call_denis_transcricao_2026-05-28.md`.
- Documento/tabela do Denis: pendente de envio.
- Depois do envio, cruzar tabela + call para gerar o escopo funcional do MVP.
