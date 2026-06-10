# Coleta de Lotacao Tributaria S-1020 sem consulta oficial

## Objetivo

Montar uma tabela auditavel com todos os codigos de lotacao tributaria e seus enquadramentos EPS/FPAS, preservando codigos como texto e mantendo evidencia da fonte.

## Regra de seguranca

Nao usar Download Cirurgico nem servicos oficiais de consulta/download do eSocial para esta coleta sem autorizacao explicita. O caminho preferencial e ler dados ja existentes ou coletados manualmente no eSocial Web.

Senha, PIN de certificado, token e qualquer segredo devem ser digitados somente pelo usuario na interface do navegador. Esses dados nao devem ser enviados por chat, arquivo de configuracao ou script.

## Fontes aceitas

1. ZIP/XML S-1020 ja baixado: melhor fonte, pois contem `evtTabLotacao` estruturado.
2. Export/salvamento do eSocial Web: usar quando a tela de Lotacao Tributaria permitir exportar, imprimir ou salvar detalhe completo.
3. Captura assistida no navegador: usuario faz login manual por certificado/procuracao e a coleta le somente a tabela/detalhes ja abertos.

## Fluxo no eSocial Web

1. Entrar no eSocial Web com certificado/procuracao.
2. Selecionar a empresa alvo.
3. Acessar `Empregador/Contribuinte > Tabelas > Lotacao Tributaria`.
4. Preferir uma listagem/export que traga todos os codigos, sem filtro de codigo especifico.
5. Para cada codigo, capturar a vigencia mais recente e os campos de FPAS/terceiros/processos suspensos.
6. Salvar os XMLs/ZIPs/exports fora de pastas versionadas, por exemplo em `storage/private/esocial/lotacoes/<empresa>/<data>/`.

## Extrator local

Quando houver XML/ZIP S-1020, rodar:

```powershell
ruby script/extract_s1020_lotacoes.rb --as-of 2026-06-10 --out tmp/lotacoes_s1020 "C:\caminho\para\fonte_s1020.zip"
```

Tambem e possivel passar uma pasta:

```powershell
ruby script/extract_s1020_lotacoes.rb --as-of 2026-06-10 --out tmp/lotacoes_s1020 "C:\caminho\para\pasta\com\xmls"
```

Arquivos gerados:

- `lotacoes_s1020_eventos.csv`: todos os eventos S-1020 encontrados.
- `lotacoes_s1020_quadro.csv`: um registro consolidado por codigo de lotacao, priorizando a vigencia atual na data `--as-of`.
- `lotacoes_s1020_resumo.json`: estatisticas da leitura, codigos encontrados e avisos de parsing.

## Colunas principais

- `codigo_lotacao`: codigo preservado como texto.
- `ini_valid` e `fim_valid`: intervalo de validade do evento.
- `registro_atual`: `sim` quando a vigencia cobre a data `--as-of`.
- `tp_lotacao`: tipo de lotacao.
- `enquadramento_eps_fpas`: resumo legivel do enquadramento.
- `fpas`: codigo FPAS.
- `cod_tercs`: codigo de terceiros.
- `cod_tercs_suspensos`: terceiros suspensos por processo, quando houver.
- `processos_judiciais`: processos vinculados a suspensao de terceiros.
- `source_path`, `nested_zip_path`, `xml_path`, `xml_sha256`: rastreabilidade.

## Controle de qualidade

- Conferir se os codigos esperados aparecem com zeros a esquerda.
- Conferir se `lotacoes_s1020_quadro.csv` tem um registro por codigo.
- Validar pelo menos um codigo manualmente na tela do eSocial Web contra o CSV.
- Se o portal mostrar mais codigos que o CSV, salvar/exportar novamente a listagem completa e reprocessar.
