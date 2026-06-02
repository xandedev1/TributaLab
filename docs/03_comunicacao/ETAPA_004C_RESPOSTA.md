# ETAPA 004C - Resposta da implementacao

Data: 2026-06-01
Projeto: TributaLab
Etapa: 004C - Adequacao S-1010 via Pontuacao de Naturezas

## Resumo

Foi implementada a etapa de adequacao cadastral por pontuacao deterministica de naturezas eSocial, usando a planilha Marcos + Tab03 como fonte local.

A entrega cria uma mesa operacional para revisar eventos/rubricas CTE, gerar top 10 de naturezas candidatas por rubrica, selecionar uma natureza, revisar CP/IRRF/FGTS com justificativa obrigatoria quando houver alteracao e manter historico auditavel.

O escopo aprovado foi respeitado: nao houve consulta ao eSocial, nao houve parser do ZIP historico S-1010, nao houve EB/base legal, folha, recolhimentos ou calculo financeiro.

Nao ha credito financeiro calculado, exibido ou afirmado nesta etapa.

## Rotas implementadas

```text
/rubric_recovery/adequacy
/rubric_recovery/adequacy/:id
/rubric_recovery/rubrics_natures
```

As entradas tambem foram adicionadas ao menu lateral:

- Pontuacao S-1010;
- Rubricas + Natureza.

## Fonte lida

Arquivo utilizado:

```text
docs/04_referencias/pesquisa_original/PESQUISAS_CTE_2026-05-28/00_CONTEXTO_PROJETO/tabela_eventos_rubricas_marcos_tab03_2026-06-01.xlsx
```

SHA256 validado:

```text
867D8E7B38D0968C94F9721D4202CBD089A3543D31594AE1817A541D71886BA4
```

Leitura implementada com `rubyzip` e `REXML`, sem biblioteca externa de Excel.

Abas lidas:

- `Plan1`: 464 eventos/rubricas CTE importados;
- `tab03`: 148 linhas de natureza importadas;
- duplicidades de natureza por vigencia preservadas por `source_row`, inclusive casos como `1016` e `1017`.

## Persistencia criada

Migration:

```text
db/migrate/20260601090000_create_rubric_adequacy_tables.rb
```

Tabelas criadas:

- `rubric_companies`;
- `rubric_events`;
- `esocial_natures`;
- `rubric_nature_suggestions`;
- `rubric_nature_assignments`;
- `rubric_nature_assignment_versions`.

Modelos criados:

- `RubricCompany`;
- `RubricEvent`;
- `EsocialNature`;
- `RubricNatureSuggestion`;
- `RubricNatureAssignment`;
- `RubricNatureAssignmentVersion`.

## Servicos criados

- `RubricRecovery::MarcosTab03Workbook`: leitor XLSX das abas `Plan1` e `tab03`.
- `RubricRecovery::TextNormalizer`: normalizacao deterministica, tokens e termos de dominio.
- `RubricRecovery::IncidenceComparator`: comparacao entre indicadores CTE e codigos CP/IRRF/FGTS da Tabela 03.
- `RubricRecovery::NatureScorer`: algoritmo deterministico `nature-score-v2`, com score 0-10, sinais positivos, penalidades e nivel de confianca.
- `RubricRecovery::NatureSuggestionBuilder`: geracao do top 10 por rubrica.
- `RubricRecovery::AdequacyImporter`: carga idempotente da planilha e regeneracao das sugestoes.
- `RubricRecovery::AssignmentUpdater`: edicao de CP/IRRF/FGTS com justificativa obrigatoria e historico.

## Algoritmo de score

O score e deterministico e reproduzivel. A ordenacao usa:

- sobreposicao de tokens entre descricao da rubrica e nome da natureza;
- sobreposicao com descricao longa da Tabela 03;
- termos de dominio, como ferias, 1/3 de ferias, 13o, estagio, aviso indenizado, insalubridade, periculosidade, desconto e assistencia medica;
- alinhamento dos indicadores CTE `InM`, `IrM`, `FN` contra `codIncCP`, `codIncIRRF`, `codIncFGTS`;
- bonus para frases fortes preservadas;
- penalidades explicitas para falso positivo, como 13o em rubrica sem 13o, adiantamento em rubrica sem adiantamento, terco de ferias em ferias comuns e aviso indenizado contra aviso trabalhado.

Empates sao resolvidos de forma estavel por score, especificidade, codigo da natureza e linha de origem. Casos com score proximo permanecem visivelmente ambiguos para revisao humana.

## Numeros importados

Base de desenvolvimento apos importacao:

```text
events: 464
natures: 148
suggestions_v2: 4640
```

Cada evento CTE recebeu 10 sugestoes de natureza.

## Exemplos reais de top 10

### 0001 - Salario

```text
1. 1000 - Salario, vencimento, soldo | score 8.3 | boa sugestao
2. 1010 - Salario in natura - Pagos em bens ou servicos | score 8.3 | boa sugestao
3. 1409 - Salario-familia | score 7.8 | boa sugestao
4. 4050 - Salario-maternidade | score 6.3 | sugestao media
5. 9930 - Salario-maternidade pago pela Previdencia Social | score 6.3 | sugestao media
6. 6002 - 13 salario proporcional na rescisao | score 5.3 | sugestao media
7. 5001 - 13 salario | score 5.3 | sugestao media
8. 4051 - Salario-maternidade - 13 salario | score 5.3 | sugestao media
9. 9931 - Salario-maternidade pago pela Previdencia Social - 13 salario | score 5.3 | sugestao media
10. 1018 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 5.3 | sugestao media
```

### 0271 - Bolsa Estagio

```text
1. 1350 - Bolsa de estudo - Estagiario | score 5.3 | sugestao media
2. 1407 - Auxilio-educacao | score 4.3 | baixa confianca
3. 6002 - 13 salario proporcional na rescisao | score 0.0 | baixa confianca
4. 6006 - Ferias proporcionais | score 0.0 | baixa confianca
5. 5001 - 13 salario | score 0.0 | baixa confianca
6. 6001 - 13 salario relativo ao aviso previo indenizado | score 0.0 | baixa confianca
7. 1012 - Descanso semanal remunerado - DSR e feriado | score 0.0 | baixa confianca
8. 1015 - Adiantamento de ferias | score 0.0 | baixa confianca
9. 1017 - Terco constitucional de ferias | score 0.0 | baixa confianca
10. 4010 - Complementacao salarial de auxilio-doenca | score 0.0 | baixa confianca
```

### 0558 - 1/3 Ferias

```text
1. 1017 - Terco constitucional de ferias | score 7.5 | boa sugestao
2. 1019 - Terco constitucional de ferias - Abono ou gratificacao de ferias superior a 20 dias | score 7.5 | boa sugestao
3. 1017 - Terco constitucional de ferias | score 5.7 | sugestao media
4. 1022 - Ferias - Abono ou gratificacao de ferias nao excedente a 20 dias | score 5.0 | sugestao media
5. 1015 - Adiantamento de ferias | score 4.2 | baixa confianca
6. 1016 - Ferias | score 0.05 | baixa confianca
7. 1018 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 0.05 | baixa confianca
8. 1021 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 0.05 | baixa confianca
9. 6002 - 13 salario proporcional na rescisao | score 0.0 | baixa confianca
10. 6006 - Ferias proporcionais | score 0.0 | baixa confianca
```

### 0005 - Horas Ferias Diurnas

```text
1. 1016 - Ferias | score 4.47 | baixa confianca
2. 1018 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 4.47 | baixa confianca
3. 1021 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 4.47 | baixa confianca
4. 6004 - Ferias - Dobro na rescisao | score 3.47 | baixa confianca
5. 6007 - Ferias vencidas na rescisao | score 3.47 | baixa confianca
6. 1024 - Ferias - Dobro na vigencia do contrato | score 3.47 | baixa confianca
7. 1023 - Ferias - Abono pecuniario | score 3.47 | baixa confianca
8. 1017 - Terco constitucional de ferias | score 3.07 | baixa confianca
9. 1019 - Terco constitucional de ferias - Abono ou gratificacao de ferias superior a 20 dias | score 3.07 | baixa confianca
10. 6006 - Ferias proporcionais | score 2.8 | baixa confianca
```

### 0950 - Aviso Previo Indenizado

```text
1. 6003 - Indenizacao compensatoria do aviso previo | score 6.93 | sugestao media
2. 6001 - 13 salario relativo ao aviso previo indenizado | score 6.6 | sugestao media
3. 6006 - Ferias proporcionais | score 5.6 | sugestao media
4. 6002 - 13 salario proporcional na rescisao | score 2.6 | baixa confianca
5. 6901 - Desconto do aviso previo | score 2.23 | baixa confianca
6. 5001 - 13 salario | score 0.0 | baixa confianca
7. 1012 - Descanso semanal remunerado - DSR e feriado | score 0.0 | baixa confianca
8. 1015 - Adiantamento de ferias | score 0.0 | baixa confianca
9. 1017 - Terco constitucional de ferias | score 0.0 | baixa confianca
10. 4010 - Complementacao salarial de auxilio-doenca | score 0.0 | baixa confianca
```

### 1951 - Insalubridade

```text
1. 1202 - Adicional de insalubridade | score 8.8 | sugestao forte
2. 1012 - Descanso semanal remunerado - DSR e feriado | score 2.1 | baixa confianca
3. 1016 - Ferias | score 2.1 | baixa confianca
4. 1018 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 2.1 | baixa confianca
5. 1021 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 2.1 | baixa confianca
6. 1800 - Alimentacao concedida em pecunia com carater salarial | score 2.1 | baixa confianca
7. 4050 - Salario-maternidade | score 2.1 | baixa confianca
8. 9930 - Salario-maternidade pago pela Previdencia Social | score 2.1 | baixa confianca
9. 1000 - Salario, vencimento, soldo | score 2.1 | baixa confianca
10. 1003 - Horas extraordinarias | score 2.1 | baixa confianca
```

### 1952 - Periculosidade

```text
1. 1203 - Adicional de periculosidade | score 6.8 | sugestao media
2. 1012 - Descanso semanal remunerado - DSR e feriado | score 2.1 | baixa confianca
3. 1016 - Ferias | score 2.1 | baixa confianca
4. 1018 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 2.1 | baixa confianca
5. 1021 - Ferias - Abono ou gratificacao de ferias superior a 20 dias | score 2.1 | baixa confianca
6. 1800 - Alimentacao concedida em pecunia com carater salarial | score 2.1 | baixa confianca
7. 4050 - Salario-maternidade | score 2.1 | baixa confianca
8. 9930 - Salario-maternidade pago pela Previdencia Social | score 2.1 | baixa confianca
9. 1000 - Salario, vencimento, soldo | score 2.1 | baixa confianca
10. 1003 - Horas extraordinarias | score 2.1 | baixa confianca
```

## Edicao e historico

Na tela `Rubricas + Natureza`, cada rubrica selecionada permite editar:

- `selected_cod_inc_cp`;
- `selected_cod_inc_irrf`;
- `selected_cod_inc_fgts`;
- `status`.

Quando CP/IRRF/FGTS mudam, o servico exige justificativa. A alteracao cria linha em `rubric_nature_assignment_versions` com valores anteriores, valores novos, motivo, responsavel e data/hora.

## Arquivos principais alterados/criados

- `db/migrate/20260601090000_create_rubric_adequacy_tables.rb`
- `app/models/rubric_company.rb`
- `app/models/rubric_event.rb`
- `app/models/esocial_nature.rb`
- `app/models/rubric_nature_suggestion.rb`
- `app/models/rubric_nature_assignment.rb`
- `app/models/rubric_nature_assignment_version.rb`
- `app/services/rubric_recovery/marcos_tab03_workbook.rb`
- `app/services/rubric_recovery/text_normalizer.rb`
- `app/services/rubric_recovery/incidence_comparator.rb`
- `app/services/rubric_recovery/nature_scorer.rb`
- `app/services/rubric_recovery/nature_suggestion_builder.rb`
- `app/services/rubric_recovery/adequacy_importer.rb`
- `app/services/rubric_recovery/assignment_updater.rb`
- `app/controllers/rubric_recovery/adequacy_controller.rb`
- `app/controllers/rubric_recovery/adequacy_assignments_controller.rb`
- `app/controllers/rubric_recovery/rubrics_natures_controller.rb`
- `app/views/rubric_recovery/adequacy/index.html.erb`
- `app/views/rubric_recovery/adequacy/show.html.erb`
- `app/views/rubric_recovery/rubrics_natures/index.html.erb`
- `config/routes.rb`
- `app/helpers/application_helper.rb`
- `db/seeds.rb`
- `test/services/rubric_recovery/marcos_tab03_workbook_test.rb`
- `test/services/rubric_recovery/nature_scoring_test.rb`
- `test/controllers/rubric_recovery/adequacy_controller_test.rb`
- `docs/04_referencias/INDICE_FONTES.md`
- `docs/03_comunicacao/ETAPA_004C_RESPOSTA.md`

## Validacao

Comandos executados:

```text
ruby bin/rails db:migrate
```

Resultado: migration aplicada com sucesso em desenvolvimento.

```text
ruby bin/rails runner "RubricRecovery::AdequacyImporter.ensure_loaded!; puts({events: RubricEvent.count, natures: EsocialNature.count, suggestions_v2: RubricNatureSuggestion.where(algorithm_version: RubricRecovery::NatureScorer::VERSION).count}.to_json)"
{"events":464,"natures":148,"suggestions_v2":4640}
```

```text
ruby bin/rails test test/services/rubric_recovery/marcos_tab03_workbook_test.rb test/services/rubric_recovery/nature_scoring_test.rb test/controllers/rubric_recovery/adequacy_controller_test.rb
6 runs, 51 assertions, 0 failures, 0 errors, 0 skips
```

```text
ruby bin/rails test
46 runs, 281 assertions, 0 failures, 0 errors, 0 skips
```

```text
ruby bin/rails zeitwerk:check
All is good!
```

Rotas verificadas no servidor local ja ativo:

```text
/rubric_recovery/adequacy           200
/rubric_recovery/adequacy/1         200
/rubric_recovery/rubrics_natures    200
```

Tambem foi feita varredura no modulo `app/controllers`, `app/services` e `app/views` de `rubric_recovery` para evitar termos de quantificacao financeira proibidos nesta etapa.

## Limites da etapa

Nao houve consulta ao eSocial.

Nao foi implementado parser do ZIP S-1010 historico nesta etapa.

Ficaram fora de escopo:

- cruzamento historico por vigencia de S-1010 real;
- EB/base legal;
- folha, eventos periodicos e recolhimentos;
- DCTFWeb, DARF/GPS, FGTS Digital ou PER/DCOMP;
- calculo financeiro, valor recuperavel ou credito em reais.

Proximo passo natural, apenas apos nova aprovacao: usar as naturezas revisadas como base para cruzamento historico S-1010 real por vigencia.