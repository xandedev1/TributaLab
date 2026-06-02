# MD 005 - Cruzamentos e apresentacao do modulo de recuperacao S-1010

Data: 2026-05-29
Projeto: TributaLab
Origem: pesquisa/arquiteto de dados fiscais
Destino: agente de implementacao Rails/frontend
Objetivo: detalhar o que deve ser cruzado e como apresentar o modulo de recuperacao de creditos ligado a adequacao das rubricas S-1010.

## Veredito sobre a resposta do agente

A resposta do agente esta na direcao correta.

Ele entendeu os pontos principais:

- nao existe uma base unica limpa de rubricas;
- existem quatro camadas: S-1010, CTE, EB e `arquivo_enquadrado`;
- nao se deve prometer credito em reais nesta etapa;
- o proximo passo deve ser uma Etapa 004 separada, com radar de rubricas;
- a primeira tela deve ser somente leitura, com diagnostico, confianca e evidencias pendentes.

Mas ainda falta precisao tecnica.

Correcoes importantes:

1. Nao usar dados `mockados` se isso significar inventar numeros. A primeira versao pode ser seedada ou materializada com os numeros reais do `arquivo_enquadrado`.
2. O primeiro radar nao deve tentar resolver todo o S-1010. Ele deve comecar pelo `arquivo_enquadrado`, porque ali ja existe o cruzamento Marco/CTE -> Tabela 03/eSocial.
3. A adequacao S-1010 deve ser apresentada como segunda camada: comparar o cadastro historico oficial da empresa contra o enquadramento esperado.
4. `RubricMapping` pode existir, mas nao e obrigatorio na primeira entrega. Um `RadarSnapshot` ou objeto de leitura e suficiente se a meta for validar UX e raciocinio.
5. A tela precisa separar tres coisas: divergencia cadastral, oportunidade potencial e credito quantificado. Hoje so temos as duas primeiras.

## Numeros reais que devem aparecer no radar

Base: `arquivo_enquadrado_2026-05-29.xlsx`, aba `Enquadramento`.

- Total de eventos analisados: 464.
- Confianca do enquadramento:
  - ALTA: 297.
  - MEDIA: 106.
  - BAIXA: 37.
  - MUITO_BAIXA: 24.
- Validacao CP/INSS:
  - VERDADEIRO: 324.
  - FALSO: 140.
- Validacao IRRF:
  - VERDADEIRO: 219.
  - FALSO: 245.
- Validacao FGTS:
  - VERDADEIRO: 338.
  - FALSO: 126.
- Eventos sem conflito nos tres tributos: 217.
- Eventos com pelo menos um conflito: 247.
- Conflitos com confianca ALTA: 181.
- Conflitos com confianca ALTA ou MEDIA: 224.

Padroes de conflito:

- CP + IRRF + FGTS: 120.
- Apenas IRRF: 101.
- CP + IRRF: 20.
- IRRF + FGTS: 4.
- Apenas FGTS: 2.
- Apenas CP: 0.

Leitura importante: IRRF aparece como a maior frente numerica de divergencia, mas nao deve ser tratado como credito automatico da empresa. Para MVP de recuperacao, INSS/CP continua sendo a frente mais segura juridica e operacionalmente.

## Como dividir o modulo

Nome de area sugerido:

```text
Recuperacao de Creditos > Folha / eSocial > Adequacao S-1010 e Rubricas
```

Nome da primeira tela:

```text
Radar de Recuperacao - Rubricas eSocial
```

Subtitulo conceitual:

```text
Diagnostico de divergencias entre rubricas operacionais, enquadramento eSocial e incidencias esperadas. Sem quantificacao financeira nesta etapa.
```

O modulo deve ter tres camadas visuais:

1. `Radar de incidencias`: baseado no `arquivo_enquadrado`, mostra conflitos CP/IRRF/FGTS, confianca e grupos.
2. `Adequacao S-1010`: compara o cadastro oficial historico S-1010 contra a incidencia esperada.
3. `Dossie de recuperacao`: lista evidencias pendentes para transformar indicio em credito estimado.

Na primeira entrega, implementar de verdade apenas a camada 1 e deixar as camadas 2 e 3 como estados/colunas de evidencia pendente.

## O que cruzar agora

### Cruzamento 1 - CTE versus Tabela 03 via arquivo_enquadrado

Este e o cruzamento principal da primeira tela.

Fonte:

- `arquivo_enquadrado_2026-05-29.xlsx`.

Campos de entrada:

- `Plan1.Codigo`.
- `Plan1.Descricao`.
- `Plan1.Tipo RB`.
- `Plan1.InM`.
- `Plan1.IrM`.
- `Plan1.FN`.
- `tab03.Tipo RB`.
- `tab03.Codigo`.
- `tab03.Nome`.
- `tab03.codIncCP`.
- `tab03.codIncIRRF`.
- `tab03.codIncFGTS`.
- `Validacao CP`.
- `Validacao IRRF`.
- `Validacao FGTS`.
- `score_match`.
- `confianca`.
- `grupo_evento`.
- `incompativel_tipo`.

Pergunta respondida:

```text
A incidencia operacional da CTE bate com a incidencia esperada pela natureza eSocial sugerida pelo Marco?
```

Saida esperada:

- status CP: OK ou divergente;
- status IRRF: OK ou divergente;
- status FGTS: OK ou divergente;
- confianca do match;
- grupo do evento;
- tipo de divergencia.

Esta tela nao precisa buscar o ZIP S-1010 ainda para provar valor. Ela mostra o primeiro mapa de divergencias.

### Cruzamento 2 - S-1010 historico versus enquadramento esperado

Este e o cruzamento da adequacao S-1010.

Fonte oficial:

- `s1010_todos_os_anos_cte_2026-05-29.zip`.

Campos S-1010:

- empregador/CNPJ raiz;
- `ideTabRubr`;
- `codRubr`;
- `iniValid`;
- `fimValid`, quando existir;
- `dscRubr`;
- `natRubr`;
- `tpRubr`;
- `codIncCP`;
- `codIncIRRF`;
- `codIncFGTS`;
- `nrRecibo`;
- data/hora de recepcao;
- tipo de operacao: inclusao, alteracao ou exclusao.

Como cruzar:

1. Tentar match deterministico quando `Tabela CTE + Codigo CTE` puder ser associado a `ideTabRubr + codRubr` do S-1010.
2. Quando isso nao for seguro, usar match assistido por descricao normalizada, natureza eSocial, tipo da rubrica e incidencias.
3. Nunca aceitar match por codigo numerico isolado.
4. Guardar grau de confianca do match.

Pergunta respondida:

```text
O cadastro oficial S-1010 da empresa declarou a rubrica com natureza/incidencia coerente com o enquadramento esperado?
```

Saida esperada:

- rubrica S-1010 encontrada ou nao encontrada;
- versoes por vigencia;
- divergencia de `natRubr`;
- divergencia de `codIncCP`;
- divergencia de `codIncIRRF`;
- divergencia de `codIncFGTS`;
- periodo potencialmente afetado;
- evidencia oficial: XML e recibo.

Este cruzamento e o coracao do termo `adequacao S-1010`.

### Cruzamento 3 - EB versus divergencia encontrada

Este e o cruzamento juridico/analitico.

Fonte:

- `tabela_eb_2026-05-29.xlsx`.

Como cruzar:

- descricao normalizada;
- natureza eSocial, quando existir;
- incidencia esperada INSS/IRRF/FGTS;
- base legal textual;
- observacoes de inconsistencia.

Pergunta respondida:

```text
Existe tese/base legal ou alerta analitico que sustente revisar essa rubrica?
```

Saida esperada:

- base legal encontrada;
- status da tese: forte, media, fraca ou pendente;
- necessidade de validacao com Denis;
- observacoes da EB.

Atencao: EB nao e fonte oficial de cadastro. Ela ajuda a sustentar a tese, nao substitui S-1010 nem folha.

### Cruzamento 4 - Folha/eventos/recolhimentos

Este cruzamento nao existe ainda. Deve aparecer como pendente.

Fontes futuras:

- folha financeira por competencia;
- S-1200;
- S-2299;
- S-2399;
- S-1210;
- DCTFWeb;
- DARF/GPS;
- SEFIP/FGTS Digital/guias de FGTS.

Pergunta respondida futuramente:

```text
Houve valor pago e tributo recolhido a maior nessa rubrica e nessa competencia?
```

Sem este cruzamento, nao existe credito em reais.

## Como apresentar na tela

### Cards do topo

Usar estes cards com numeros reais:

- `464 eventos CTE enquadrados`.
- `247 com divergencia em pelo menos um tributo`.
- `224 registros/eventos divergentes com confianca alta/media`.
- `140 divergencias CP/INSS`.
- `245 divergencias IRRF`.
- `126 divergencias FGTS`.
- `217 sem divergencia CP/IRRF/FGTS`.

Nao usar card de valor financeiro.

### Blocos de leitura

1. `Mapa de divergencias`.
   - Barras ou contadores por CP/IRRF/FGTS.
   - Separar `apenas IRRF`, `CP+IRRF+FGTS`, `CP+IRRF`, etc.

2. `Confianca do enquadramento`.
   - ALTA, MEDIA, BAIXA, MUITO_BAIXA.
   - Priorizar alta/media.

3. `Grupos com maior volume de conflito`.
   - Ferias.
   - Decimo terceiro.
   - Previdenciario.
   - Ferias abono.
   - Periculosidade.
   - Decimo rescisao.

4. `Tabela de rubricas`.
   - Codigo.
   - Descricao.
   - Grupo.
   - Natureza eSocial sugerida.
   - Confianca.
   - Score.
   - CP status.
   - IRRF status.
   - FGTS status.
   - Evidencias pendentes.

5. `Trilha de evidencia`.
   - CTE: presente.
   - Marco/enquadramento: presente.
   - S-1010 oficial: pendente ou encontrado.
   - EB/base legal: pendente ou encontrada.
   - Folha: pendente.
   - Recolhimento: pendente.
   - Parecer: pendente.

### Filtros obrigatorios

- Tributo: CP/INSS, IRRF, FGTS.
- Confianca: alta, media, baixa, muito baixa.
- Grupo de evento.
- Padrao de conflito: IRRF, CP+IRRF+FGTS, CP+IRRF, IRRF+FGTS, FGTS.
- Apenas alta/media.
- Apenas com divergencia.

### Estados/labels corretos

Use:

- `Indicio de divergencia`.
- `Adequacao S-1010 pendente`.
- `S-1010 encontrado`.
- `Base legal pendente`.
- `Folha pendente`.
- `Recolhimento pendente`.
- `Pronto para revisao tecnica`.

Nao usar:

- `credito aprovado`;
- `credito recuperavel`;
- `valor a restituir`;
- `economia confirmada`;
- `PER/DCOMP pronto`.

## Ordem de implementacao recomendada

### Etapa 004A - Radar somente leitura

Implementar:

- rota `/rubric_recovery/radar`;
- controller simples;
- service/view-model `RubricRecovery::RadarSnapshot`;
- dados seedados ou fixture com numeros reais;
- cards, filtros visuais e tabela de divergencias;
- nenhuma persistencia complexa obrigatoria.

Objetivo: validar narrativa e UX com Alessandro/Denis.

### Etapa 004B - Importacao real do arquivo_enquadrado

Implementar:

- leitor XLSX;
- normalizacao dos campos;
- armazenamento ou cache dos 464 registros;
- filtros reais.

Objetivo: sair de snapshot fixo para dados navegaveis.

### Etapa 004C - Parser S-1010

Implementar:

- leitura do ZIP;
- extracao de XMLs;
- normalizacao de `RubricVersion`;
- linha do tempo por rubrica;
- comparacao com `RubricMapping`.

Objetivo: mostrar adequacao S-1010 por vigencia.

### Etapa 004D - Dossie e quantificacao

Somente depois:

- folha;
- eventos periodicos;
- DCTFWeb/DARF/GPS;
- FGTS;
- calculo financeiro;
- parecer.

Objetivo: transformar indicio em credito estimado.

## Resposta sugerida ao agente antes de ele implementar

Use a resposta pronta do agente, mas acrescente este ajuste:

```text
Complemento obrigatorio: a primeira entrega da Etapa 004 deve usar os numeros reais do arquivo_enquadrado. O radar inicial deve mostrar 464 eventos, 247 com pelo menos uma divergencia, 224 registros/eventos divergentes com confianca alta/media, 140 divergencias CP/INSS, 245 IRRF e 126 FGTS. Nao usar numeros inventados.

O primeiro cruzamento implementado deve ser CTE x Tabela 03/eSocial via arquivo_enquadrado. O cruzamento com S-1010 historico deve ser tratado como camada de adequacao S-1010, preferencialmente na etapa seguinte, usando ideTabRubr + codRubr quando confiavel e nunca codigo isolado.

A tela deve separar: divergencia encontrada, adequacao S-1010 pendente/encontrada, base legal pendente/encontrada, folha pendente e recolhimento pendente. Sem folha e recolhimento, nao exibir credito em reais.
```

## Frase norteadora

O modulo nao comeca calculando credito. Ele comeca mostrando onde a rubrica parece mal enquadrada, qual e a confianca desse indicio, qual evidencia ja existe e qual prova ainda falta para transformar adequacao S-1010 em recuperacao de credito.

Complemento obrigatorio: a primeira entrega da Etapa 004 deve usar os numeros reais do arquivo_enquadrado.

O radar inicial deve mostrar:

- 464 eventos analisados
- 247 com pelo menos uma divergencia
- 224 registros/eventos divergentes com confianca alta/media
- 140 divergencias CP/INSS
- 245 divergencias IRRF
- 126 divergencias FGTS
- 217 sem divergencia CP/IRRF/FGTS

O primeiro cruzamento implementado deve ser CTE x Tabela 03/eSocial via arquivo_enquadrado.

O cruzamento com S-1010 historico vem como camada de adequacao S-1010:
comparar ideTabRubr + codRubr + descricao + natRubr + codIncCP/codIncIRRF/codIncFGTS + vigencia contra o enquadramento esperado.

Nunca cruzar por codigo numerico isolado.

A tela deve separar:

- divergencia encontrada
- adequacao S-1010 pendente/encontrada
- base legal EB pendente/encontrada
- folha pendente
- recolhimento pendente
- parecer pendente

Sem folha e recolhimento, nao exibir credito em reais.