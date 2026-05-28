# MD 002 - Para Agente de Implementacao Rails

Data: 2026-05-28
Projeto: TributaLab
Origem: arquiteto do sistema
Destino: agente de implementacao Rails
Formato esperado de resposta: um unico arquivo Markdown de volta

## Estado atual do produto

O TributaLab **ainda nao esta pronto para uso real com empresas/clientes**.

A Etapa 001 concluiu o esqueleto tecnico e validou a base inicial:

- Rails 8.1.3
- Ruby 3.3.11
- PostgreSQL
- Tailwind
- Hotwire/Turbo/Stimulus
- Minitest
- dashboard inicial
- modelagem inicial
- seeds do modulo Reforma Tributaria Imobiliaria
- copia das fontes de pesquisa
- documentos de coordenacao por Markdown

A Etapa 001 passou nos testes e no boot local. Isso significa que o projeto esta pronto para desenvolvimento da Etapa 002, **nao** para cadastro real de empresas, operacao comercial ou simulacoes confiaveis para cliente.

## Objetivo deste MD

Este MD transforma a revisao arquitetural da Etapa 001 em pedido pratico para a Etapa 002.

Voce deve implementar a Etapa 002 e, ao terminar, responder criando obrigatoriamente:

```text
docs/03_comunicacao/ETAPA_002_RESPOSTA.md
```

Nao responda apenas em chat. O arquivo Markdown de resposta e parte obrigatoria do processo.

## Leitura obrigatoria antes de implementar

Antes de alterar codigo, leia estes arquivos no repositorio TributaLab:

1. `docs/03_comunicacao/ETAPA_001_RESPOSTA.md`
2. `docs/04_referencias/INDICE_FONTES.md`
3. `docs/02_decisoes/DECISAO_001_setup_inicial.md`
4. `docs/03_comunicacao/PERGUNTAS_ABERTAS.md`
5. `docs/00_brief/README_INICIAL_TRIBUTALAB.md`
6. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/leitura_tabela_denis_reforma_imobiliaria_2026-05-28.md`
7. `docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/arquitetura_inicial_sistema.md`

Se algum arquivo nao existir, registre isso em `ETAPA_002_RESPOSTA.md` e siga apenas com as informacoes ja disponiveis no repo. Nao invente regra tributaria ausente.

## Decisoes arquiteturais para seguir

### 1. Hierarquia aprovada

Manter a hierarquia atual:

```text
ProductArea -> Sector -> TaxModule -> Operation
```

Exemplo:

```text
ProductArea: tax_reform
Sector: real_estate_construction
TaxModule: real_estate_tax_reform
Operation: sale_property, lease_property, etc.
```

### 2. Nome tecnico aprovado

Manter `TaxModule`.

Nao trocar para `Module`, porque `Module` conflita com constante nativa do Ruby.

### 3. Services por operacao

Na Etapa 002, nao criar motor generico universal.

Criar services por operacao, com contrato padronizado de retorno:

```text
TaxRules::RealEstate::SalePropertyCalculator
TaxRules::RealEstate::SaleResidentialLotCalculator
TaxRules::RealEstate::LeasePropertyCalculator
TaxRules::RealEstate::ExchangeWithBootCalculator
```

Se for util, criar uma classe base simples, mas sem superengenharia.

### 4. Versionamento leve de regras

Criar uma entidade simples para versao de regra.

Nome recomendado:

```text
TaxRuleVersion
```

Campos sugeridos:

- `tax_module_id`
- `code`
- `name`
- `status`
- `effective_from`
- `effective_until`
- `source_summary`
- `notes`

Seed inicial sugerido:

```text
code: real_estate_tax_reform_v1
name: Reforma Tributaria Imobiliaria v1
status: pending_validation
```

Essa versao deve ser associada as simulacoes feitas na Etapa 002.

### 5. Auditoria por snapshot

Toda simulacao precisa guardar snapshot dos dados usados no momento do calculo.

Salvar, no minimo:

- inputs;
- parametros usados;
- assumptions aplicadas;
- alertas de validacao;
- bases legais consideradas, se disponiveis;
- versao de regra usada.

Mesmo que `TaxParameter` mude depois, a simulacao antiga precisa continuar reproduzivel.

### 6. Simulation e SimulationResult

Manter `Simulation` e `SimulationResult` separados.

`Simulation` representa o evento de simulacao:

- modulo;
- operacao;
- versao de regra;
- inputs;
- snapshots;
- data/hora.

`SimulationResult` representa o resultado calculado:

- base bruta;
- redutor/deducao;
- base liquida;
- aliquota cheia;
- reducao aplicada;
- aliquota efetiva;
- debito IBS/CBS;
- creditos;
- imposto liquido;
- alertas;
- detalhes do calculo.

Usar campos `decimal` para valores financeiros e percentuais. JSON pode ser usado para snapshots e detalhes, mas os principais valores numericos devem ser consultaveis.

### 7. Assumption

`Assumption` nao deve ser apenas documentacao.

Na Etapa 002, ela deve pelo menos:

- aparecer nos alertas;
- ser copiada para o snapshot da simulacao;
- indicar que determinada regra esta pendente ou divergente.

Quando a assumption alterar o comportamento do calculo, documentar claramente qual caminho foi usado.

Exemplo: locacao deduz ou nao deduz IPTU/condominio.

## Objetivo da Etapa 002

Implementar calculos auditaveis do modulo:

```text
Reforma Tributaria > Imobiliario / Construcao Civil
```

A Etapa 002 deve transformar a base criada na Etapa 001 em um fluxo minimo de simulacao real para quatro operacoes.

## Escopo obrigatorio da Etapa 002

### 1. Criar versionamento de regra

Criar `TaxRuleVersion` ou equivalente simples, com migration, model, seed e testes.

Relacionar a versao de regra ao `TaxModule`.

Associar `Simulation` a `TaxRuleVersion`.

### 2. Criar calculators

Implementar calculators para:

1. Venda de imovel / incorporacao.
2. Venda de lote residencial.
3. Locacao de imoveis.
4. Permuta com torna.

### 3. Contrato padrao de retorno

Cada calculator deve retornar uma estrutura padrao contendo:

```ruby
{
  operation_code: "...",
  inputs: {},
  parameters: {},
  assumptions: [],
  alerts: [],
  result: {
    gross_base: ...,
    deductions_amount: ...,
    net_base: ...,
    full_rate: ...,
    reduction_rate: ...,
    effective_rate: ...,
    debit_amount: ...,
    credits_amount: ...,
    tax_due: ...
  }
}
```

Adaptar nomes ao estilo do app, mas manter essa separacao conceitual.

### 4. Persistir simulacoes

Criar fluxo para salvar:

- `Simulation`
- `SimulationResult`

A simulacao precisa guardar snapshots suficientes para auditoria futura.

### 5. Criar UI minima de simulacao

Criar tela simples para executar simulacoes das quatro operacoes da Etapa 002.

Nao precisa ser UI final. Precisa ser operacional.

Pode ser uma tela com selecao de operacao e campos condicionais, ou uma tela simples por operacao.

Apos calcular, exibir:

- inputs usados;
- parametros usados;
- resultado;
- assumptions;
- alertas de regra pendente;
- versao de regra usada.

### 6. Criar testes

Criar testes para:

- cada calculator;
- persistencia de `Simulation` e `SimulationResult`;
- snapshots de parametros/assumptions;
- rota ou fluxo basico de simulacao, se aplicavel.

Manter Minitest, salvo se houver decisao explicita para trocar.

### 7. Criar decisao tecnica

Criar:

```text
docs/02_decisoes/DECISAO_002_versionamento_regras_simulacoes.md
```

Esse documento deve explicar:

- por que `TaxRuleVersion` foi criado;
- como snapshots funcionam;
- por que `Simulation` e `SimulationResult` ficaram separados;
- como calculators foram organizados;
- quais simplificacoes ficaram para depois.

### 8. Criar resposta final da etapa

Criar:

```text
docs/03_comunicacao/ETAPA_002_RESPOSTA.md
```

A resposta deve conter:

- resumo do que foi feito;
- arquivos criados ou alterados;
- migrations criadas;
- como rodar;
- testes executados;
- resultados dos testes;
- screenshots ou descricao da tela, se nao houver captura;
- pendencias;
- perguntas para dono do projeto/Denis;
- proposta de Etapa 003.

## Formulas iniciais

### Venda de imovel / incorporacao

```text
base_calculo = max(0, valor_venda - redutor_social)
aliquota_efetiva = aliquota_cheia * (1 - reducao)
imposto_devido = base_calculo * aliquota_efetiva
```

Parametros:

- aliquota cheia IBS/CBS: 26,5%;
- redutor venda imovel residencial: R$ 100.000;
- reducao venda/incorporacao: 50%.

### Venda de lote residencial

```text
base_calculo = max(0, valor_venda - redutor_lote)
aliquota_efetiva = aliquota_cheia * (1 - reducao)
imposto_devido = base_calculo * aliquota_efetiva
```

Parametros:

- aliquota cheia IBS/CBS: 26,5%;
- redutor venda lote residencial: R$ 30.000;
- reducao venda de lote residencial: 50%.

### Locacao de imoveis

Formula inicial pendente de validacao:

```text
base_bruta = aluguel - iptu - condominio
base_liquida = max(0, base_bruta - redutor_locacao)
aliquota_efetiva = aliquota_cheia * (1 - reducao_locacao)
imposto_devido = base_liquida * aliquota_efetiva
```

Parametros:

- aliquota cheia IBS/CBS: 26,5%;
- redutor locacao residencial: R$ 600;
- reducao locacao: 70%.

Alerta obrigatorio:

A planilha indica excluir IPTU e condominio, mas o exemplo usa aluguel integral. A simulacao de locacao precisa exibir alerta de divergencia enquanto Denis/dono do projeto nao validar.

### Permuta com torna

```text
base_calculo = valor_torna
debito = base_calculo * aliquota_cheia
imposto_liquido = max(0, debito - creditos)
```

Parametros:

- aliquota cheia IBS/CBS: 26,5%;
- creditos informados pelo usuario, se houver.

## Fora de escopo da Etapa 002

Nao implementar agora:

- login;
- cadastro real de empresas;
- multi-tenant;
- recuperacao de credito;
- importacao automatica da planilha;
- relatorios finais;
- motor tributario generico universal;
- NCM detalhado;
- regras definitivas para pontos pendentes;
- modulo completo de construcao civil, administracao/corretagem ou cessao de direitos.

## Criterios de aceite

A Etapa 002 so termina quando:

- `TaxRuleVersion` ou equivalente existir e estiver seedado;
- calculators das quatro operacoes existirem;
- calculators tiverem testes;
- calculos usarem `decimal`, nao float;
- simulacoes forem persistidas;
- resultados forem persistidos;
- snapshots de parametros/assumptions/alertas forem salvos;
- UI minima permitir executar ao menos as quatro simulacoes;
- locacao mostrar alerta de divergencia;
- `DECISAO_002_versionamento_regras_simulacoes.md` existir;
- `ETAPA_002_RESPOSTA.md` existir;
- testes passarem;
- comandos para rodar estiverem documentados.

## Perguntas que continuam pendentes

Estas perguntas nao bloqueiam a Etapa 002, mas precisam continuar aparecendo como pendencias:

1. A base legal correta e LC 227/2026, LC 214/2025 ou outro texto consolidado?
2. Os artigos 252, 254, 255, 259, 260 e 261 estao corretos?
3. Na locacao, IPTU e condominio saem da base ou nao?
4. Cessao de direitos aplica reducao de 70% ou aliquota cheia?
5. Construcao civil tem alguma reducao especifica ou apenas credito?
6. Administracao/corretagem usa aliquota cheia sem redutor?
7. Credito maior que debito vira saldo ou apenas zera imposto da simulacao?
8. Permuta sem torna precisa de tela propria ou apenas aviso informativo?
9. O usuario final sera interno, consultor tributario ou cliente externo?
10. A primeira versao precisa salvar clientes/casos ou pode simular sem cadastro de cliente?

## Estado esperado apos Etapa 002

Depois da Etapa 002, o TributaLab ainda nao sera produto completo para cliente final.

Mas deve estar pronto para:

- rodar simulacoes internas das quatro operacoes iniciais;
- auditar parametros usados;
- auditar assumptions aplicadas;
- testar formulas;
- validar fluxo com dono do projeto;
- preparar Etapa 003.

Nao cadastrar empresas reais ainda, salvo como teste manual controlado.

## Proxima resposta esperada

Ao concluir, responda criando:

```text
docs/03_comunicacao/ETAPA_002_RESPOSTA.md
```

Use este formato:

```md
# ETAPA 002 - Resposta

## Resumo do que foi feito

## Arquivos criados ou alterados

## Migrations e modelos

## Services de calculo

## Fluxo de simulacao

## Como rodar

## Testes executados

## Resultado dos testes

## Decisoes tomadas

## Pendencias

## Perguntas para o dono do projeto ou Denis

## Proxima etapa sugerida
```

Se houver decisao critica adicional, criar tambem:

```text
docs/02_decisoes/DECISAO_003_nome_do_tema.md
```
