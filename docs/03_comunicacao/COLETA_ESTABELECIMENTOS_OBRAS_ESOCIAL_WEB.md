# Coleta de Estabelecimentos e Obras S-1005 sem consulta oficial

## Objetivo

Montar a segunda tabela do cliente com o historico de `Empregador/Contribuinte > Tabelas > Estabelecimentos/Obras`, preservando inicio/fim de validade, CNAE preponderante, aliquota GILRAT/RAT, FAP, RAT ajustado, data de recepcao e recibo.

## Onde fica no eSocial Web

1. Entrar no eSocial Web com certificado digital.
2. Usar o certificado/procuracao disponivel para acessar como procurador do CNPJ da CTE.
3. No menu geral, abrir `Empregador/Contribuinte > Tabelas > Estabelecimentos/Obras`.
4. Informar o tipo de inscricao `CNPJ` e o CNPJ da CTE/estabelecimento.
5. Consultar a listagem/historico de validade exibido pelo portal.

Senha, PIN de certificado, token e qualquer segredo devem ser digitados somente pelo usuario na interface do navegador. Esses dados nao devem ser enviados por chat, arquivo de configuracao ou script.

## Evento eSocial correspondente

A tela de Estabelecimentos/Obras corresponde ao evento `S-1005` (`evtTabEstab`). Os principais campos extraidos sao:

- `tpInsc` e `nrInsc` do estabelecimento/obra.
- `iniValid` e `fimValid`.
- `cnaePrep`.
- `aliqGilrat`.
- `fap`.
- `aliqRatAjust`.
- `dhRecepcao` ou `dhProcessamento`, quando existir no XML/retorno.
- `nrRecibo`.

## Extrator local

Quando houver XML/ZIP S-1005, rodar:

```powershell
ruby script/extract_s1005_estabelecimentos_obras.rb --as-of 2026-06-10 --out tmp/estabelecimentos_s1005 "C:\caminho\para\fonte_s1005.zip"
```

Tambem e possivel passar uma pasta:

```powershell
ruby script/extract_s1005_estabelecimentos_obras.rb --as-of 2026-06-10 --out tmp/estabelecimentos_s1005 "C:\caminho\para\pasta\com\xmls"
```

Arquivos gerados:

- `estabelecimentos_s1005_eventos.csv`: todos os eventos S-1005 encontrados, incluindo historico anual.
- `estabelecimentos_s1005_quadro.csv`: registro consolidado vigente por tipo/numero de inscricao.
- `estabelecimentos_s1005_resumo.json`: estatisticas da leitura e avisos de parsing.

## Tela no Prev Lab

A pagina fica em:

```text
/esocial/estabelecimentos_obras
```

Ela le automaticamente os CSVs em `tmp/estabelecimentos_s1005`. Se os CSVs ainda nao existirem, mostra um demonstrativo visual marcado como `demonstrativo` para validar o formato da tabela.

## Controle de qualidade

- Conferir se cada periodo anual aparece com `iniValid` e `fimValid` corretos.
- Conferir se o periodo vigente fica sem `fimValid` ou com validade aberta.
- Validar manualmente no portal um ano antigo e o ano vigente contra o CSV.
- Confirmar se a data exibida no portal e data de recepcao ou processamento; o extrator preenche a primeira tag disponivel entre `dhRecepcao`, `dhProcessamento`, `dtRecepcao` e `dtRecibido`.
