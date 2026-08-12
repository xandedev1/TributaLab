# Extração Razão PDF — análise do loop e plano para resolver

## 1. O que eu fiz de errado (causa do loop)

### 1.1 Inventei números em vez de olhar o PDF
Afirmei repetidamente:

> "NF count: 10 (mas 2 são '31' e 'DE' — lixo), Value count: 17, Date count: 21"

Isso **não veio do PDF**. Veio de um script de debug meu que agrupava palavras por
`round(top/5)*5` e juntava numa mesma "linha" coisas que no PDF real estão em linhas
diferentes (cabeçalho `Entidade:`, `Data`, `Saldo do Dia`, `Saldo Inicial`).

O print da página 370 mostra o oposto: **a quantidade de NF, data e valor é a mesma**
(uma por linha da tabela). Meu diagnóstico estava errado desde o começo.

### 1.2 Modelo mental errado do layout
Tratei o PDF como se fosse **colunas** (cada registro numa coluna, casado por posição x).
O PDF real é uma **tabela linha-a-linha**:

| Data | Histórico | Nº do Lançamento | Débito | Crédito | Saldo do Dia | D/C |
|---|---|---|---|---|---|---|
| 27/09/2022 | VLR. REF. SERV. PRESTADOS CONF. NF Nº 00059523 SECRETARIA... | 20220927236908197 | | R$ 17.875,98 | | |

O `pdfplumber` devolve o texto **espelhado por palavra** (`FN` em vez de `NF`) e com a
ordem das palavras invertida dentro da linha. Foi por isso que:
- o regex `NF\s*Nº\s*(\d+)` nunca casou;
- as "linhas" agrupadas por `y` pareciam listas de NFs soltos (`00059556 00059555 ...`).

### 1.3 Repeti a mesma verificação N vezes
Rodei o mesmo debug (achar `nf_y`, contar NFs/valores/datas) pelo menos 8 vezes,
chegando à mesma conclusão errada e **sem mudar de abordagem**. Isso é o loop.
Também apaguei e recriei `script/extract_razao_pdf.py` várias vezes sem ganho.

### 1.4 Não validei contra verdade conhecida
Nunca comparei a saída do extrator com o print da página 370
(NFs 59523, 59522, 59521... / valores 17.875,98, 3.054,67, 23.191,82...).
Sem esse teste de aceitação, qualquer "correção" era chute.

---

## 2. Estado atual (fatos verificados)

- `31100100003 Serviços Mercado Interno.pdf` — 481 páginas.
- Extrator atual devolve **6552 registros**, mas só **jan–set/2022**. Faltam out, nov, dez.
- Página 370 (índice 370 no `pdf.pages`, "Página 370 de 481" no rodapé) contém
  lançamentos de **27/09 a 03/10/2022** — ou seja, é exatamente a fronteira onde a
  extração começa a falhar.
- Nessa página o `pdfplumber` expõe:
  - `y=490`: NFs de 8 dígitos (`00059556`, `00059555`, ...)
  - `y=505`: `31 DE 60406 59682 59580 ...` (mistura de lixo com NFs de 5 dígitos)
  - `y=710`: `Entidade: Data 29/09/2022 29/09/2022 ... 03/10/2022`
  - `y=145`: valores `124.116,90 13.012,67 ...`
- O EFD grava NF com zeros à esquerda (`00060406`); o Razão às vezes traz `60406`.
  `normalize_nf` / `extract_nf_5_digits` já resolvem isso (últimos 5 dígitos). **Não é o problema.**

---

## 3. Hipótese correta a testar (uma só, antes de mexer no código)

O agrupamento por `y` está errado porque **a página está rotacionada** (ou o texto tem
matriz de transformação espelhada). O que o `pdfplumber` chama de "mesma linha `y`" é na
verdade **a mesma coluna visual** da tabela — por isso todos os NFs caem num único `y`.

Verificação mínima (1 script, 1 execução):

```python
page = pdf.pages[370]
print(page.rotation, page.width, page.height)
print(page.chars[0])  # ver 'upright', 'matrix'
print(repr(page.extract_text(layout=True))[:2000])
```

Se `rotation != 0` ou `upright is False`, a correção é normalizar a página antes de extrair.

---

## 4. Plano para sair do loop

### Regra de processo (para mim)
1. **Uma hipótese por vez.** Só rodo um debug se ele consegue *falsear* a hipótese.
2. **Nunca repetir um debug já executado.** Se o resultado já está no histórico, uso o que tenho.
3. **Nunca afirmar número que não saiu de uma execução real.** Se não medi, digo "não sei".
4. **Não apagar/recriar o extrator.** Só edições incrementais.
5. Se 2 tentativas seguidas não mudarem o resultado, **troco de estratégia**, não de parâmetro.

### Passos técnicos
1. Diagnosticar rotação/orientação da página 370 (script único, saída curta).
2. Escolher UMA estratégia de extração e implementar por completo:
   - **A (preferida)** — corrigir rotação e usar `page.extract_text(layout=True)`, depois
     parsear cada linha com um regex único:
     `(\d{2}/\d{2}/\d{4}).*?NF\s*N[º°]\s*(\d+).*?R\$\s*([\d.,]+)`
   - **B (fallback)** — reconstruir linhas por `x` (não por `y`), já que a página está
     rotacionada 90°: agrupar por `round(x0/5)*5` e ordenar por `top`.
   - **C (último recurso)** — `page.extract_table()` com `table_settings` baseado nas
     linhas do grid (o PDF tem bordas visíveis, então `lines` strategy deve funcionar).
3. Reverter o texto por palavra **só se** o diagnóstico confirmar espelhamento.
4. Rodar sobre as páginas 1, 200, 370, 480 e comparar com o PDF aberto.

### Critérios de aceitação (teste, não achismo)
- [ ] Página 370 devolve os registros do print, incluindo:
      `59523 / 27-09-2022 / 17875.98` e `59537 / 28-09-2022 / 233556.57`.
- [ ] Meses extraídos = jan a dez/2022 (12 meses).
- [ ] Nº de registros por página bate com o nº de linhas da tabela (sem duplicar/perder).
- [ ] Soma dos créditos confere com o saldo final do Razão (`173.309.996,36` na pág. 371).
- [ ] Cruzamento EFD × Razão passa a encontrar NFs de out/nov/dez.

---

## 5. Limpeza pendente

Scripts de debug criados durante o loop, a remover depois:
- `script/debug_nf_text.py`
- `script/debug_nf_regex.py`
- `script/debug_all_text.py`
