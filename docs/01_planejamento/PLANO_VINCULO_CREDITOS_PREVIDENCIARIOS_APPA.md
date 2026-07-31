# Suspensão de contribuições de terceiros da APPA

## Objetivo

Preparar offline o vínculo entre o processo judicial cadastrado no S-1070 e os códigos de terceiros das lotações S-1020 da APPA para a competência 06/2026. Nenhuma consulta, alteração ou transmissão ao eSocial faz parte desta etapa.

## Evidências confirmadas

Os dois XMLs recebidos em 30/07/2026 são eventos S-1070 do mesmo processo:

| Recibo | Ação | Início da validade | Processo | Suspensão |
| --- | --- | --- | --- | --- |
| `1.1.0000000042395247693` | Inclusão | `2026-06` | `5006491-20.2022.4.03.6119` | `1` |
| `1.1.0000000042403419933` | Alteração | `2023-01` | `5006491-20.2022.4.03.6119` | `1` |

Os dois eventos pertencem à raiz CNPJ `05.969.071`, possuem matéria exclusivamente tributária ou tributária e FGTS, indicativo `01` (liminar em mandado de segurança), decisão em `2023-01-01` e ausência de depósito integral.

O segundo recibo não é S-1010. Ele altera o cadastro S-1070 e antecipa a validade informada para `2023-01`.

Em 30/07/2026 também foram baixadas as duas versões disponíveis do S-1020 da lotação `E00410-001-02A`:

| Recibo | Vigência | FPAS | Código suspenso | Processo vinculado | Entidades |
| --- | --- | --- | --- | --- | --- |
| `1.1.0000000026463341021` | `2023-01` a `2024-11` | `515` | `0115` | `5006493-87.2022.4.03.6119` | `0001`, `0002`, `0016`, `0032`, `0064` |
| `1.1.0000000030322915387` | desde `2024-12` | `515` | `0115` | `5006491-20.2022.4.03.6119` | `0001`, `0002`, `0016`, `0032`, `0064` |

O analisador offline confirmou que os cinco vínculos da vigência aberta correspondem ao S-1070 do processo solicitado e ao código de suspensão `1`, sem erros de leitura. Portanto, a lotação `E00410-001-02A` já está corretamente vinculada desde `12/2024` e não deve receber nova alteração em `06/2026` apenas para repetir esse vínculo.

As duas versões disponíveis do S-1020 da lotação `E00482-001-01A` também foram baixadas em 30/07/2026:

| Recibo | Vigência | FPAS | Código suspenso | Processo vinculado | Entidades |
| --- | --- | --- | --- | --- | --- |
| `1.1.0000000026083272698` | `2018-02` a `2022-12` | `655` | Não informado | Não informado | Nenhuma |
| `1.1.0000000026083346658` | desde `2023-01` | `655` | `0001` | `5006493-87.2022.4.03.6119` | `0001` |

A vigência aberta dessa lotação ainda aponta para o processo anterior. Ela é a divergência comprovada entre os dois perfis representativos e precisa de nova validade em `2026-06` com o processo `5006491-20.2022.4.03.6119`, suspensão `1` e entidade `0001`.

Denis delimitou o trabalho à competência `06/2026` e informou estes códigos de terceiros:

| Código | Entidade | Processo | Código da suspensão |
| --- | --- | --- | --- |
| `0001` | Salário-Educação | `5006491-20.2022.4.03.6119` | `1` |
| `0002` | INCRA | `5006491-20.2022.4.03.6119` | `1` |
| `0016` | SENAC | `5006491-20.2022.4.03.6119` | `1` |
| `0032` | SESC | `5006491-20.2022.4.03.6119` | `1` |
| `0064` | SEBRAE | `5006491-20.2022.4.03.6119` | `1` |

O código combinado é `0115`.

## Evento correto para o vínculo

Como o objeto informado são contribuições destinadas a terceiros, o vínculo pertence ao grupo `fpasLotacao` do evento S-1020, e não ao S-1010. Cada lotação aplicável deve preservar seu enquadramento e informar:

- `codTercs`: código de terceiros normal da lotação;
- `codTercsSusp`: código combinado das entidades suspensas compatíveis com o FPAS;
- um `procJudTerceiro` para cada entidade suspensa, contendo `codTerc`, `nrProcJud` e `codSusp`.

O S-1010/`ideProcessoCP` é utilizado quando a decisão suspende incidência previdenciária de rubricas. Não é o mecanismo correspondente aos cinco códigos de terceiros fornecidos por Denis.

## Distribuição conhecida das lotações

O totalizador local de 01/2025 contém 147 lotações:

| Lotações | FPAS | Código normal | Código suspenso |
| ---: | --- | --- | --- |
| 146 | `515` | `0115` | `0115` |
| 1 | `655` | `0001` | `0001` |

Assim, os cinco códigos não podem ser repetidos indiscriminadamente em todas as lotações. A lotação FPAS `655` admite somente o vínculo compatível `0001`; as lotações FPAS `515` usam o combinado `0115` e os cinco `procJudTerceiro`.

## Ferramenta offline criada

O analisador aceita XML, ZIP, ZIP aninhado ou diretório. Ele extrai S-1070, S-1010 e S-1020 e cruza os vínculos por empregador, processo e código de suspensão:

```powershell
ruby script/analyze_esocial_previdenciary_process.rb CAMINHO_DO_XML_OU_ZIP
```

A saída JSON separa processos, vínculos de rubricas, vínculos de lotações, correspondências confirmadas, vínculos sem processo e erros. A ferramenta não calcula valores, não assina XML, não transmite eventos e não acessa o eSocial.

## Dados já disponíveis no TributaLab

O sistema já possui os dados estruturais necessários das 147 lotações, obtidos pela combinação das referências de FGTS, contribuições e cadastro por CNPJ:

- 143 lotações de tipo `04`;
- 4 lotações de tipo `01`: `E00001-001-02A`, `E00440-001-02A`, `E02021-001-02A` e `E02018-001-02A`;
- código da lotação e vigências;
- tipo e número de inscrição, quando aplicáveis;
- FPAS, código normal de terceiros e código suspenso;
- distribuição de 146 lotações FPAS `515` e uma FPAS `655`.

Nas quatro lotações tipo `01`, `tpInsc` e `nrInsc` não devem ser enviados no S-1020, conforme o leiaute, ainda que a referência visual associe o CNPJ da APPA.

Não é necessário pedir novamente ao Denis um ZIP completo apenas para obter esses campos. O dado histórico não capturado nas referências é o conteúdo atual de `procJudTerceiro` de cada vigência aberta. Os XMLs obtidos comprovam os dois perfis estruturais: a amostra FPAS `515` já está correta e a única lotação FPAS `655` está divergente.

Essa amostragem não equivale a uma auditoria individual dos 146 XMLs FPAS `515`; a conclusão sobre esse grupo depende da uniformidade do cadastro local e do perfil representativo `E00410-001-02A`.

## Artefato preparado

Foi preparado um único evento de revisão para a divergência comprovada:

- arquivo: `storage/private/esocial/appa/s1020_2026-06/S-1020_E00482-001-01A_2026-06_UNSIGNED.xml`;
- operação: inclusão da validade `2026-06`;
- lotação: `E00482-001-01A`;
- FPAS e Terceiros preservados: `655` / `0001`;
- suspensão: `0001`, entidade `0001`, processo `5006491-20.2022.4.03.6119`, código `1`;
- leiaute: S-1.3, namespace `v_S_01_03_00`;
- validação: conteúdo aprovado sem erros pelo XSD oficial em produção desde 01/07/2026; no schema completo falta somente a assinatura digital obrigatória;
- cruzamento offline: vínculo novo correspondente ao S-1070 atual, sem erros de análise.

O identificador do evento é provisório para revisão. O arquivo não está assinado e não foi transmitido.

## Preparação

A preparação deve:

1. selecionar a versão vigente de cada lotação em `06/2026`;
2. identificar quais vigências já possuem o processo `5006491-20.2022.4.03.6119` e a suspensão `1`;
3. não gerar alteração para as lotações que já estejam corretas;
4. nas divergentes, preservar `tpLotacao`, inscrição e FPAS ao criar a nova validade;
5. aplicar `0115` e cinco vínculos somente nas lotações FPAS `515` que precisarem de correção;
6. aplicar `0001` e um vínculo somente à lotação FPAS `655` se ela precisar de correção;
7. validar cada XML necessário no XSD S-1.3;
8. produzir lote não assinado para revisão, sem transmissão automática;
9. depois do envio autorizado, conferir os totalizadores da competência `06/2026`.