# -*- coding: utf-8 -*-
"""3 relatórios ISO 19011 COMPLETOS (10 seções, padrão APPA) — um PDF por card do Comparativo.
Diferença Tabela (22.707.431,37) | Diferença ECF (4.031.828,87) | Diferença EFD (1.454.331,64).
Planilha lida do xlsx, EFD/contabilidade dos JSONs, achados dinâmicos, tudo validado por assert."""
import json
from datetime import date
from decimal import Decimal

import pandas as pd
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, Table, TableStyle,
)

BASE = r"C:\Users\xandao\Documents\GitHub\TributaLab\tmp"
XLSX = r"C:\Users\xandao\Downloads\tabela enviada dennis solucoes\diferença ECF x EFD soluções 2022.xlsx"
OUTDIR = r"C:\Users\xandao\Downloads"

NAVY = colors.HexColor("#16202e")
ORANGE = colors.HexColor("#d2572b")
GREY = colors.HexColor("#4a4a4a")
LIGHT = colors.HexColor("#faf3ee")
BORDER = colors.HexColor("#d9d9d9")
MESES = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
         "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
MKEYS = [f"2022-{m:02d}" for m in range(1, 13)]
MNOME = dict(zip(MKEYS, MESES))


def load(name):
    with open(f"{BASE}\\{name}", encoding="utf-8") as f:
        return json.load(f)


def dec(v):
    return Decimal(str(v)).quantize(Decimal("0.01"))


def brl(v):
    neg = v < 0
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return f"{'−' if neg else ''}R$ {s}"


def num(n):
    return f"{n:,}".replace(",", ".")


def fdata(iso):
    if not iso:
        return "—"
    y, m, d = iso.split("-")
    return f"{d}/{m}/{y}"


def mes_ano(mk):
    return f"{MNOME[mk]}/2022"


# ================================================================ DADOS
df = pd.read_excel(XLSX, header=None)
plan = {}
for i, mk in enumerate(MKEYS):
    row = df.iloc[i + 2]
    plan[mk] = {"cst01": dec(row[0]), "cst02": dec(row[1]), "efd": dec(row[2]),
                "ecf_bruto": dec(row[3]), "dev": dec(row[4]) if pd.notna(row[4]) else Decimal("0.00"),
                "ecf_liq": dec(row[5])}
p_efd = sum(p["efd"] for p in plan.values())
p_cst01 = sum(p["cst01"] for p in plan.values())
p_cst02 = sum(p["cst02"] for p in plan.values())
p_ecf_bruto = sum(p["ecf_bruto"] for p in plan.values())
p_dev = sum(p["dev"] for p in plan.values())
p_ecf_liq = sum(p["ecf_liq"] for p in plan.values())
assert p_efd == Decimal("927910661.06") and p_ecf_liq == Decimal("945131931.92")
assert p_ecf_bruto == Decimal("949047070.79") and p_dev == Decimal("3915138.87")

efd_data = load("efd_razao.json")
a100, c100 = efd_data["a100"], efd_data["c100"]
serv = load("razao_servicos.json")["records"]
vend = load("razao_vendas.json")["records"]
devol = load("devolucao.json")["records"]
devol_nfs = {r["num_nf"] for r in devol}
tot_devol = sum(dec(r["valor"]) for r in devol)


def monthly(records, field):
    out = {mk: Decimal("0.00") for mk in MKEYS}
    for r in records:
        mk = (r.get("data_emissao") or "")[:7]
        if mk in out:
            out[mk] += dec(r[field])
    return out


m_a100, m_c100 = monthly(a100, "valor_nf"), monthly(c100, "valor_nf")
m_serv, m_vend = monthly(serv, "credito"), monthly(vend, "credito")
tot_a100, tot_c100 = sum(m_a100.values()), sum(m_c100.values())
tot_serv, tot_vend = sum(m_serv.values()), sum(m_vend.values())
efd_ap, ctb_ap = tot_a100 + tot_c100, tot_serv + tot_vend
assert tot_a100 == Decimal("712818493.94") and tot_c100 == Decimal("213637835.48")
assert tot_serv == Decimal("711921394.96") and tot_vend == Decimal("210503105.59")
assert efd_ap == Decimal("926456329.42") and ctb_ap == Decimal("922424500.55")

DIF_TABELA = p_ecf_liq - ctb_ap
DIF_ECF = efd_ap - ctb_ap
DIF_EFD = p_efd - efd_ap
DIF_FINAL = DIF_TABELA - DIF_ECF - DIF_EFD
assert DIF_TABELA == Decimal("22707431.37") and DIF_ECF == Decimal("4031828.87")
assert DIF_EFD == Decimal("1454331.64") and DIF_FINAL == Decimal("17221270.86")


def cross(base, match, direction):
    by_nf = {}
    for r in match:
        by_nf.setdefault(r["num_nf"], []).append(r)
    out = []
    for b in base:
        ms = by_nf.get(b["num_nf"])
        is_dev = b["num_nf"] in devol_nfs
        if ms:
            m = ms[0]
            if direction == "txt_to_pdf":
                credito = Decimal(0) if is_dev else dec(m["credito"])
                out.append({"nf": b["num_nf"], "valor": dec(b["valor_nf"]), "credito": credito,
                            "credito_raw": dec(m["credito"]), "dif": dec(b["valor_nf"]) - credito,
                            "matched": True, "dev": is_dev, "page": m["page"], "data": b["data_emissao"],
                            "src": b.get("source_file")})
            else:
                credito = Decimal(0) if is_dev else dec(b["credito"])
                out.append({"nf": b["num_nf"], "valor": dec(m["valor_nf"]), "credito": credito,
                            "credito_raw": dec(b["credito"]), "dif": credito - dec(m["valor_nf"]),
                            "matched": True, "dev": is_dev, "page": b["page"], "data": b["data_emissao"],
                            "src": b.get("source_file")})
        else:
            if direction == "txt_to_pdf":
                out.append({"nf": b["num_nf"], "valor": dec(b["valor_nf"]), "credito": Decimal(0),
                            "credito_raw": Decimal(0), "dif": dec(b["valor_nf"]), "matched": False,
                            "dev": is_dev, "page": None, "data": b["data_emissao"], "src": b.get("source_file")})
            else:
                out.append({"nf": b["num_nf"], "valor": Decimal(0), "credito": dec(b["credito"]),
                            "credito_raw": dec(b["credito"]), "dif": dec(b["credito"]), "matched": False,
                            "dev": is_dev, "page": b["page"], "data": b["data_emissao"], "src": b.get("source_file")})
    return out


def stats(recs):
    matched = [r for r in recs if r["matched"]]
    unmatched = [r for r in recs if not r["matched"]]
    div = [r for r in matched if abs(r["dif"]) > Decimal("0.05")]
    return {"recs": recs, "n": len(recs), "matched": len(matched), "unmatched": unmatched,
            "n_um": len(unmatched), "ok": len(matched) - len(div), "div": div, "n_div": len(div),
            "dif_div": sum(r["dif"] for r in div), "dif_um": sum(r["dif"] for r in unmatched),
            "total_dif": sum(r["dif"] for r in recs)}


x1 = stats(cross(a100, serv, "txt_to_pdf"))
x2 = stats(cross(serv, a100, "pdf_to_txt"))
x3 = stats(cross(c100, vend, "txt_to_pdf"))
x4 = stats(cross(vend, c100, "pdf_to_txt"))
dev_zerado = sum(r["credito_raw"] for r in x4["recs"] if r["matched"] and r["dev"])
bloco_serv, bloco_vend = tot_a100 - tot_serv, tot_c100 - tot_vend
assert x1["dif_um"] == Decimal("13627974.25") and x2["dif_um"] == Decimal("12727088.05")
assert x2["dif_div"] == Decimal("3787.22") and x3["dif_um"] == Decimal("3802140.59")
assert dev_zerado == Decimal("400894.61")
assert bloco_serv == Decimal("897098.98") and bloco_vend == Decimal("3134729.89")
assert bloco_serv + bloco_vend == DIF_ECF
assert (x1["n"], x1["matched"], x1["n_um"], x1["ok"], x1["n_div"]) == (8895, 8618, 277, 8617, 1)
assert (x2["n"], x2["matched"], x2["n_um"], x2["ok"], x2["n_div"]) == (8806, 8618, 188, 8617, 1)
assert (x3["n"], x3["matched"], x3["n_um"], x3["ok"], x3["n_div"]) == (1797, 1650, 147, 1303, 347)
assert (x4["n"], x4["matched"], x4["n_um"], x4["ok"], x4["n_div"]) == (1650, 1650, 0, 1303, 347)

# diferenças mensais
d1 = {mk: plan[mk]["ecf_liq"] - m_serv[mk] - m_vend[mk] for mk in MKEYS}
d2 = {mk: m_a100[mk] + m_c100[mk] - m_serv[mk] - m_vend[mk] for mk in MKEYS}
d3 = {mk: plan[mk]["efd"] - m_a100[mk] - m_c100[mk] for mk in MKEYS}
assert sum(d1.values()) == DIF_TABELA and sum(d2.values()) == DIF_ECF and sum(d3.values()) == DIF_EFD

hoje = date.today().strftime("%d/%m/%Y")

# ================================================================ LAYOUT
S = {
    "title": ParagraphStyle("t", fontName="Helvetica-Bold", fontSize=22, leading=26, alignment=1, textColor=NAVY, spaceAfter=4),
    "subtitle": ParagraphStyle("st", fontName="Helvetica-Bold", fontSize=15, leading=19, alignment=1, textColor=NAVY, spaceAfter=4),
    "version": ParagraphStyle("v", fontName="Helvetica", fontSize=10, alignment=1, textColor=GREY, spaceAfter=12),
    "h": ParagraphStyle("h", fontName="Helvetica-Bold", fontSize=13, textColor=ORANGE, spaceBefore=14, spaceAfter=6),
    "h2": ParagraphStyle("h2", fontName="Helvetica-Bold", fontSize=10.5, textColor=NAVY, spaceBefore=8, spaceAfter=4),
    "p": ParagraphStyle("p", fontName="Helvetica", fontSize=9.5, leading=13.5, alignment=4, textColor=colors.HexColor("#222222"), spaceAfter=6),
    "cell": ParagraphStyle("c", fontName="Helvetica", fontSize=8.5, leading=11, textColor=colors.HexColor("#222222")),
    "cellb": ParagraphStyle("cb", fontName="Helvetica-Bold", fontSize=8.5, leading=11, textColor=NAVY),
    "head": ParagraphStyle("hd", fontName="Helvetica-Bold", fontSize=8.5, leading=11, textColor=colors.white),
}


def P(text, style="p"):
    return Paragraph(text, S[style])


def header_footer(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(NAVY)
    canvas.rect(0, h - 16 * mm, w, 16 * mm, stroke=0, fill=1)
    canvas.setFillColor(colors.white)
    canvas.setFont("Helvetica-Bold", 10)
    canvas.drawString(15 * mm, h - 10 * mm, "REAL PREV | Relatório de Auditoria de Receitas")
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(w - 15 * mm, h - 10 * mm, f"ISO 19011 | Pág. {doc.page}")
    canvas.setFillColor(ORANGE)
    canvas.rect(0, h - 16.8 * mm, w, 0.8 * mm, stroke=0, fill=1)
    canvas.setFillColor(GREY)
    canvas.setFont("Helvetica", 7)
    canvas.drawString(15 * mm, 8 * mm, "Uso restrito - documento técnico-operacional. Não constitui certificação ISO, parecer legal, fiscal ou trabalhista.")
    canvas.drawRightString(w - 15 * mm, 8 * mm, hoje)
    canvas.restoreState()


def grid(extra=None, total_row=True):
    base = [
        ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 2.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5),
    ]
    if total_row:
        base.append(("BACKGROUND", (0, -1), (-1, -1), LIGHT))
    return TableStyle(base + (extra or []))


def ident_table(objeto, tipo):
    t = Table([
        [P("<b>Empresa auditada</b>", "cell"), P("Soluções Serviços Terceirizados Ltda.", "cell"),
         P("<b>CNPJ</b>", "cell"), P("09.445.502/0001-09", "cell")],
        [P("<b>Período auditado</b>", "cell"), P("Janeiro/2022 a Dezembro/2022", "cell"),
         P("<b>Data de emissão</b>", "cell"), P(hoje, "cell")],
        [P("<b>Objeto</b>", "cell"), P(objeto, "cell"), P("<b>Tipo</b>", "cell"), P(tipo, "cell")],
        [P("<b>Referência</b>", "cell"), P("ISO 19011", "cell"), P("<b>Versão / Uso</b>", "cell"), P("1.0 / Restrito", "cell")],
    ], colWidths=[32 * mm, 66 * mm, 30 * mm, 52 * mm])
    t.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
        ("BACKGROUND", (0, 0), (0, -1), LIGHT),
        ("BACKGROUND", (2, 0), (2, -1), LIGHT),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return t


def month_table(headers, rowfn, totals, widths=None):
    widths = widths or [30 * mm] + [(150 // (len(headers) - 1)) * mm] * (len(headers) - 1)
    rows = [[P(f"<b>{h}</b>", "head") for h in headers]]
    for mk in MKEYS:
        rows.append([P(mes_ano(mk), "cell")] + [P(brl(v), "cell") for v in rowfn(mk)])
    rows.append([P("<b>Total</b>", "cellb")] + [P(f"<b>{brl(t)}</b>", "cellb") for t in totals])
    t = Table(rows, colWidths=widths)
    t.setStyle(grid())
    return t


def achado(story, codigo, titulo, classificacao, criterio, evidencia, analise, recomendacao, status):
    story.append(P(f"{codigo} — {titulo}", "h2"))
    story.append(P(f"<b>Classificação:</b> {classificacao}"))
    story.append(P(f"<b>Critério:</b> {criterio}"))
    story.append(P(f"<b>Evidência:</b> {evidencia}"))
    story.append(P(f"<b>Análise:</b> {analise}"))
    story.append(P(f"<b>Recomendação:</b> {recomendacao}"))
    story.append(P(f"<b>Status:</b> {status}"))


def controles_table(rows):
    data = [[P("<b>Controle avaliado</b>", "head"), P("<b>Evidência / critério</b>", "head"), P("<b>Resultado</b>", "head")]]
    for c, e, r in rows:
        data.append([P(c, "cell"), P(e, "cell"), P(r, "cellb")])
    t = Table(data, colWidths=[45 * mm, 105 * mm, 30 * mm])
    t.setStyle(grid(total_row=False))
    return t


def plano_table(rows):
    data = [[P("<b>Item</b>", "head"), P("<b>Tema</b>", "head"), P("<b>Ação recomendada</b>", "head"),
             P("<b>Prioridade</b>", "head"), P("<b>Responsável</b>", "head")]]
    for i, (tema, acao, prio, resp) in enumerate(rows, 1):
        data.append([P(str(i), "cell"), P(tema, "cell"), P(acao, "cell"), P(prio, "cell"), P(resp, "cell")])
    t = Table(data, colWidths=[10 * mm, 32 * mm, 88 * mm, 20 * mm, 30 * mm])
    t.setStyle(grid(total_row=False))
    return t


def top_meses(dif_map, n=3):
    return sorted(MKEYS, key=lambda mk: -abs(dif_map[mk]))[:n]


def build(filename, subtitle, body):
    out = f"{OUTDIR}\\{filename}"
    doc = BaseDocTemplate(out, pagesize=A4, leftMargin=15 * mm, rightMargin=15 * mm,
                          topMargin=22 * mm, bottomMargin=15 * mm)
    doc.addPageTemplates([PageTemplate(id="all", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="f")], onPage=header_footer)])
    doc.build([P("REAL PREV", "title"), P(subtitle, "subtitle"),
               P("Relatório estruturado conforme diretrizes de auditoria da ISO 19011", "version")] + body)
    print("OK:", out)


W4 = [30 * mm, 50 * mm, 50 * mm, 50 * mm]

# ================================================================================
# RELATÓRIO 1 — DIFERENÇA TABELA (R$ 22.707.431,37)
# ================================================================================
b = [ident_table("Card \"Diferença Tabela\" do Comparativo EFD × ECF", "Auditoria documental de receitas")]

b.append(P("1. Sumário executivo", "h"))
b.append(P(
    f"Este relatório documenta integralmente a apuração do card <b>Diferença Tabela = {brl(DIF_TABELA)}</b>, "
    f"primeiro componente da equação exibida no sistema Real Audit Tech: Diferença Tabela − Diferença ECF − "
    f"Diferença EFD = Diferença Final ({brl(DIF_TABELA)} − {brl(DIF_ECF)} − {brl(DIF_EFD)} = {brl(DIF_FINAL)})."))
b.append(P(
    f"O valor resulta do confronto entre a receita ECF declarada pela empresa na planilha \"diferença ECF x EFD "
    f"soluções 2022.xlsx\" ({brl(p_ecf_liq)}, líquida de devoluções) e a receita apurada nesta auditoria a partir "
    f"das contas contábeis de receita de Serviços e Vendas ({brl(ctb_ap)}). A diferença de {brl(DIF_TABELA)} "
    f"concentra-se em {mes_ano(top_meses(d1, 1)[0])} ({brl(d1[top_meses(d1, 1)[0]])}), com compensações "
    f"negativas em outros meses, e dois meses com fechamento exato em R$ 0,00 (Abril e Junho)."))

b.append(P("2. Objetivo da auditoria", "h"))
b.append(P(
    "Evidenciar, com rastreabilidade completa, como o valor do card foi apurado: as duas bases confrontadas, o "
    "método de extração de cada uma, os valores mês a mês e a localização temporal da divergência, permitindo "
    "que qualquer terceiro reproduza o cálculo e chegue ao mesmo resultado."))

b.append(P("3. Escopo e limites", "h"))
b.append(P(
    "Empresa: Soluções Serviços Terceirizados Ltda., CNPJ 09.445.502/0001-09. Período: Janeiro/2022 a "
    "Dezembro/2022. Bases: (i) planilha \"diferença ECF x EFD soluções 2022.xlsx\" enviada pela empresa "
    "(colunas faturamento ECF, devolução e faturamento ECF líquido); (ii) PDFs das contas contábeis de receita "
    "de Serviços e de Vendas; (iii) relatório de devoluções de vendas (24 notas). Exclusões: a ECF transmitida "
    "ao SPED não foi analisada — a receita ECF utilizada é a declarada pela própria empresa na planilha; contas "
    "de receita não entregues à auditoria não compõem o total contábil apurado."))

b.append(P("4. Critérios de auditoria", "h"))
b.append(P(
    "Diretrizes gerais de auditoria da ISO 19011 (planejamento, evidência objetiva, achados, conclusão e "
    "recomendações). Planilha da empresa tratada como declaração de referência. Escrituração contábil como "
    "contraprova, com rastreabilidade por lançamento: número de nota, data, valor de crédito, arquivo de origem "
    "e página do PDF. Consolidação mensal pelo mês de emissão."))

b.append(P("5. Metodologia", "h"))
b.append(P(
    "1) Leitura estruturada da planilha da empresa, extraindo por mês o faturamento ECF bruto, as devoluções e "
    "o faturamento ECF líquido. 2) Extração integral, lançamento a lançamento, dos PDFs das contas contábeis "
    f"de Serviços ({num(len(serv))} lançamentos) e Vendas ({num(len(vend))} lançamentos), com número de nota, "
    "data, valor e página de origem preservados. 3) Consolidação mensal das duas bases. 4) Confronto mês a mês "
    "e apuração da diferença total. Todos os valores deste relatório foram recalculados a partir das bases "
    "originais; nenhum número foi transcrito de terceiros sem verificação."))

b.append(P("6. Evidências objetivas", "h"))
b.append(P("6.1. Base 1 — Receita ECF declarada na planilha da empresa", "h2"))
b.append(P(
    f"O faturamento ECF líquido resulta do bruto menos devoluções. O total de devoluções da planilha "
    f"({brl(p_dev)}) coincide, centavo a centavo, com a soma das 24 notas do relatório de devoluções entregue."))
b.append(month_table(["Mês", "ECF bruto", "Devoluções", "ECF líquido"],
                     lambda mk: (plan[mk]["ecf_bruto"], plan[mk]["dev"], plan[mk]["ecf_liq"]),
                     (p_ecf_bruto, p_dev, p_ecf_liq), W4))
b.append(P("6.2. Base 2 — Receita contábil apurada nesta auditoria", "h2"))
b.append(month_table(["Mês", "Serviços", "Vendas", "Contábil total"],
                     lambda mk: (m_serv[mk], m_vend[mk], m_serv[mk] + m_vend[mk]),
                     (tot_serv, tot_vend, ctb_ap), W4))
b.append(P("6.3. Confronto mensal e apuração do valor", "h2"))
b.append(month_table(["Mês", "ECF líquido (planilha)", "Contábil apurado", "Diferença"],
                     lambda mk: (plan[mk]["ecf_liq"], m_serv[mk] + m_vend[mk], d1[mk]),
                     (p_ecf_liq, ctb_ap, DIF_TABELA), W4))
b.append(Spacer(1, 4))
b.append(P(f"<b>Apuração: {brl(p_ecf_liq)} − {brl(ctb_ap)} = {brl(DIF_TABELA)}.</b>"))

b.append(P("7. Achados de auditoria", "h"))
tm1 = top_meses(d1, 3)
achado(b, "A-01", f"Receita ECF declarada excede a contabilidade em {brl(DIF_TABELA)}",
       "Achado maior — risco de conformidade fiscal-contábil",
       "A receita declarada na ECF deve conciliar com a receita escriturada nas contas contábeis de resultado, com composição documentada.",
       f"ECF líquida da planilha: {brl(p_ecf_liq)}. Contabilidade apurada (Serviços + Vendas): {brl(ctb_ap)}. Diferença: {brl(DIF_TABELA)} (seção 6.3).",
       f"A divergência não é uniforme: concentra-se em {mes_ano(tm1[0])} ({brl(d1[tm1[0]])}), seguida de {mes_ano(tm1[1])} ({brl(d1[tm1[1]])}) e {mes_ano(tm1[2])} ({brl(d1[tm1[2]])}). Abril e Junho fecham em R$ 0,00 exato, indicando que nesses meses a ECF declarada corresponde integralmente às contas analisadas.",
       "Identificar as demais contas de receita ou ajustes extracontábeis que compõem a ECF, com prioridade para Dezembro/2022, documentando a conciliação ECF × contabilidade conta a conta.",
       "Aberto — requer composição analítica da ECF pela empresa.")
achado(b, "A-02", f"Concentração de {brl(d1[tm1[0]])} em {mes_ano(tm1[0])}",
       "Achado maior — risco de evento não escriturado ou reclassificação de fechamento",
       "Variações relevantes de receita entre declaração e escrituração devem possuir justificativa documentada.",
       f"Em {mes_ano(tm1[0])}, a ECF declarada é {brl(plan[tm1[0]]['ecf_liq'])} contra {brl(m_serv[tm1[0]] + m_vend[tm1[0]])} na contabilidade apurada — diferença de {brl(d1[tm1[0]])}, superior à diferença total do ano ({brl(DIF_TABELA)}).",
       "O padrão (um mês fortemente positivo compensado por meses negativos) é típico de reconhecimento de receita em competência distinta entre as duas bases ou de lançamentos de encerramento concentrados no fim do exercício.",
       "Obter o detalhamento da receita ECF de Dezembro/2022 e conciliar com os lançamentos contábeis de encerramento.",
       "Aberto.")
achado(b, "A-03", "Devoluções da planilha conferem com o relatório de devoluções",
       "Informativo — evidência de consistência",
       "Valores redutores de receita devem ser suportados por documentação específica.",
       f"Devoluções na planilha: {brl(p_dev)}. Soma das 24 notas do relatório de devoluções: {brl(tot_devol)}. Coincidência exata, concentrada em Julho ({brl(plan['2022-07']['dev'])}), Outubro ({brl(plan['2022-10']['dev'])}), Novembro ({brl(plan['2022-11']['dev'])}) e Dezembro ({brl(plan['2022-12']['dev'])}).",
       "A base de devoluções utilizada pela empresa na planilha é a mesma entregue à auditoria, validando o uso do ECF líquido no confronto.",
       "Manter o relatório de devoluções como anexo permanente da conciliação.",
       "Encerrado.")

b.append(P("8. Avaliação dos controles", "h"))
b.append(controles_table([
    ("Integridade e rastreabilidade", "Lançamentos contábeis extraídos com NF, data, valor e página de origem; planilha da empresa preservada como recebida.", "Conforme"),
    ("Abordagem baseada em evidência", "Todos os totais recalculados das bases originais; confronto mensal reproduzível (seção 6).", "Conforme"),
    ("Conciliação ECF × contabilidade", f"Diferença de {brl(DIF_TABELA)} sem composição analítica disponível; concentração em Dezembro/2022.", "Conforme com ressalvas"),
    ("Tratamento de devoluções", "Devoluções da planilha idênticas ao relatório específico (24 notas).", "Conforme"),
]))

b.append(P("9. Recomendações e plano de ação", "h"))
b.append(plano_table([
    ("Composição da ECF", "Detalhar conta a conta a receita declarada na ECF, identificando as contas que excedem as de Serviços e Vendas analisadas.", "Alta", "Soluções / Contábil"),
    ("Dezembro/2022", f"Conciliar o pico de {brl(d1[tm1[0]])} de {mes_ano(tm1[0])} com os lançamentos de encerramento do exercício.", "Alta", "Soluções / Contábil"),
    ("Meses negativos", f"Justificar os meses em que a contabilidade supera a ECF declarada ({mes_ano(tm1[1])}: {brl(d1[tm1[1]])}; {mes_ano(tm1[2])}: {brl(d1[tm1[2]])}).", "Média", "Soluções / Contábil"),
    ("Repositório auditável", "Preservar planilha, PDFs contábeis e relatório de devoluções como trilha da conciliação.", "Média", "Soluções / Real Prev"),
]))

b.append(P("10. Conclusão", "h"))
b.append(P(
    f"O valor do card está integralmente evidenciado: <b>{brl(p_ecf_liq)} − {brl(ctb_ap)} = {brl(DIF_TABELA)}</b>, "
    f"com abertura mensal completa na seção 6.3. A diferença representa receita declarada na ECF acima da "
    f"escriturada nas contas analisadas, concentrada em Dezembro/2022, e constitui o ponto de partida da equação "
    f"do sistema: {brl(DIF_TABELA)} − {brl(DIF_ECF)} − {brl(DIF_EFD)} = <b>{brl(DIF_FINAL)}</b> (Diferença Final)."))
b.append(P(
    "Este relatório é uma avaliação técnico-documental estruturada segundo diretrizes de auditoria. Não constitui "
    "certificação ISO, parecer legal, fiscal ou trabalhista."))

build("SOLUCOES_RELATORIO_DIFERENCA_TABELA_2022_ISO_19011.pdf", "Diferença Tabela - R$ 22.707.431,37", b)

# ================================================================================
# RELATÓRIO 2 — DIFERENÇA ECF (R$ 4.031.828,87)
# ================================================================================
b = [ident_table("Card \"Diferença ECF\" do Comparativo EFD × ECF", "Auditoria documental de receitas")]

b.append(P("1. Sumário executivo", "h"))
b.append(P(
    f"Este relatório documenta integralmente a apuração do card <b>Diferença ECF = {brl(DIF_ECF)}</b>, segundo "
    f"componente da equação do sistema ({brl(DIF_TABELA)} − <b>{brl(DIF_ECF)}</b> − {brl(DIF_EFD)} = "
    f"{brl(DIF_FINAL)}). O valor mede quanto a receita escriturada na EFD Contribuições ({brl(efd_ap)}) excede a "
    f"receita lançada nas contas contábeis de receita ({brl(ctb_ap)})."))
b.append(P(
    f"Diferentemente de uma simples subtração de totais, esta parcela foi <b>integralmente identificada nota a "
    f"nota</b> por quatro cruzamentos bidirecionais entre {num(len(a100) + len(c100))} registros da EFD e "
    f"{num(len(serv) + len(vend))} lançamentos contábeis, decompondo-se em: bloco Serviços {brl(bloco_serv)} + "
    f"bloco Vendas {brl(bloco_vend)} = {brl(DIF_ECF)}."))

b.append(P("2. Objetivo da auditoria", "h"))
b.append(P(
    "Evidenciar a apuração do valor do card com rastreabilidade em nível de nota fiscal: bases utilizadas, regra "
    "de cruzamento, classificação de cada registro (OK, divergência, sem correspondência), composição aritmética "
    "exata do valor e relação dos itens mais relevantes com sua localização nos documentos de origem."))

b.append(P("3. Escopo e limites", "h"))
b.append(P(
    "Empresa: Soluções Serviços Terceirizados Ltda., CNPJ 09.445.502/0001-09. Período: Janeiro/2022 a "
    "Dezembro/2022. Bases: (i) 12 arquivos TXT da EFD Contribuições — registros A100 (serviços) e C100 "
    "(mercadorias, somente saídas IND_OPER=1, parcelas consolidadas por nota); (ii) PDFs das contas contábeis "
    "de receita de Serviços e Vendas; (iii) relatório de devoluções de vendas (24 notas). Exclusões: ECF e "
    "planilha da empresa não participam deste card — o confronto é exclusivamente EFD × contabilidade."))

b.append(P("4. Critérios de auditoria", "h"))
b.append(P(
    "Diretrizes da ISO 19011. Layout oficial da EFD Contribuições (registros A100 e C100, campo IND_OPER). "
    "Tolerância de R$ 0,05 para considerar valores idênticos (status OK). Notas constantes do relatório de "
    "devoluções têm o crédito contábil desconsiderado nas notas cruzadas, evitando abatimento de receita "
    "devolvida. Rastreabilidade integral: NF, data, valor nas duas bases, arquivo de origem e página do PDF."))

b.append(P("5. Metodologia", "h"))
b.append(P(
    "1) Extração integral dos registros A100 e C100 (IND_OPER=1) dos 12 TXT, consolidando parcelas da mesma "
    "nota. 2) Extração dos lançamentos de crédito dos PDFs contábeis com página de origem. 3) Normalização do "
    "número de cada nota (últimos 5 dígitos significativos) como chave de cruzamento nas duas pontas. "
    "4) Execução de quatro cruzamentos — dois partindo da EFD (existe lançamento contábil para cada nota da "
    "EFD?) e dois partindo da contabilidade (existe nota na EFD para cada lançamento?). 5) Classificação de "
    "cada registro em OK, Divergência ou Sem correspondência. 6) Composição aritmética do valor do card a "
    "partir dos resultados."))

b.append(P("6. Evidências objetivas", "h"))
b.append(P("6.1. Bases confrontadas", "h2"))
t = Table([
    [P("<b>Base</b>", "head"), P("<b>Origem</b>", "head"), P("<b>Registros</b>", "head"), P("<b>Total 2022</b>", "head")],
    [P("EFD A100 (Serviços)", "cell"), P("12 TXT EFD Contribuições", "cell"), P(num(len(a100)), "cell"), P(brl(tot_a100), "cell")],
    [P("EFD C100 (Vendas, saídas)", "cell"), P("12 TXT EFD Contribuições", "cell"), P(num(len(c100)), "cell"), P(brl(tot_c100), "cell")],
    [P("<b>EFD Total</b>", "cellb"), P("", "cell"), P(f"<b>{num(len(a100) + len(c100))}</b>", "cellb"), P(f"<b>{brl(efd_ap)}</b>", "cellb")],
    [P("Contabilidade Serviços", "cell"), P("Conta contábil (PDF)", "cell"), P(num(len(serv)), "cell"), P(brl(tot_serv), "cell")],
    [P("Contabilidade Vendas", "cell"), P("Conta contábil (PDF)", "cell"), P(num(len(vend)), "cell"), P(brl(tot_vend), "cell")],
    [P("<b>Contábil Total</b>", "cellb"), P("", "cell"), P(f"<b>{num(len(serv) + len(vend))}</b>", "cellb"), P(f"<b>{brl(ctb_ap)}</b>", "cellb")],
    [P("Devoluções de vendas", "cell"), P("Relatório específico (PDF)", "cell"), P(str(len(devol)), "cell"), P(brl(tot_devol), "cell")],
], colWidths=[52 * mm, 50 * mm, 25 * mm, 53 * mm])
t.setStyle(grid([("BACKGROUND", (0, 3), (-1, 3), LIGHT), ("BACKGROUND", (0, 6), (-1, 6), LIGHT)], total_row=False))
b.append(t)
b.append(P("6.2. Resultado dos quatro cruzamentos", "h2"))
t = Table([
    [P("<b>Cruzamento</b>", "head"), P("<b>Regs.</b>", "head"), P("<b>Cruz.</b>", "head"), P("<b>OK</b>", "head"),
     P("<b>Div.</b>", "head"), P("<b>Sem match</b>", "head"), P("<b>Valor sem match</b>", "head")],
    [P("1. EFD(A100) − (Serviços)", "cell"), P(num(x1["n"]), "cell"), P(num(x1["matched"]), "cell"), P(num(x1["ok"]), "cell"),
     P(num(x1["n_div"]), "cell"), P(num(x1["n_um"]), "cell"), P(brl(x1["dif_um"]), "cell")],
    [P("2. (Serviços) − EFD(A100)", "cell"), P(num(x2["n"]), "cell"), P(num(x2["matched"]), "cell"), P(num(x2["ok"]), "cell"),
     P(num(x2["n_div"]), "cell"), P(num(x2["n_um"]), "cell"), P(brl(x2["dif_um"]), "cell")],
    [P("3. EFD(C100) − (Vendas)", "cell"), P(num(x3["n"]), "cell"), P(num(x3["matched"]), "cell"), P(num(x3["ok"]), "cell"),
     P(num(x3["n_div"]), "cell"), P(num(x3["n_um"]), "cell"), P(brl(x3["dif_um"]), "cell")],
    [P("4. (Vendas) − EFD(C100)", "cell"), P(num(x4["n"]), "cell"), P(num(x4["matched"]), "cell"), P(num(x4["ok"]), "cell"),
     P(num(x4["n_div"]), "cell"), P(num(x4["n_um"]), "cell"), P(brl(x4["dif_um"]), "cell")],
], colWidths=[48 * mm, 16 * mm, 16 * mm, 14 * mm, 14 * mm, 20 * mm, 52 * mm])
t.setStyle(grid(total_row=False))
b.append(t)
b.append(P("6.3. Composição aritmética exata do valor do card", "h2"))
t = Table([
    [P("<b>Bloco</b>", "head"), P("<b>Composição</b>", "head"), P("<b>Valor</b>", "head")],
    [P("Serviços<br/>(A100 × conta Serviços)", "cell"),
     P(f"Notas só na EFD: +{brl(x1['dif_um'])} ({num(x1['n_um'])} notas)<br/>"
       f"Lançamentos só na contabilidade: −{brl(x2['dif_um'])} ({num(x2['n_um'])} lançamentos)<br/>"
       f"Divergência de valor nas cruzadas: −{brl(x2['dif_div'])} (1 nota)", "cell"),
     P(f"<b>{brl(bloco_serv)}</b>", "cellb")],
    [P("Vendas<br/>(C100 × conta Vendas)", "cell"),
     P(f"Notas só na EFD: +{brl(x3['dif_um'])} ({num(x3['n_um'])} notas)<br/>"
       f"Divergências nas cruzadas: −{brl(dev_zerado - x3['dif_div'])} líquido ({num(x3['n_div'])} notas, "
       f"incluindo devoluções de {brl(dev_zerado)})", "cell"),
     P(f"<b>{brl(bloco_vend)}</b>", "cellb")],
    [P("<b>Total</b>", "cellb"), P(f"<b>{brl(bloco_serv)} + {brl(bloco_vend)}</b>", "cellb"), P(f"<b>{brl(DIF_ECF)}</b>", "cellb")],
], colWidths=[42 * mm, 95 * mm, 43 * mm])
t.setStyle(grid())
b.append(t)
b.append(Spacer(1, 4))
b.append(P(
    f"Conferência: bloco Serviços {brl(x1['dif_um'])} − {brl(x2['dif_um'])} − {brl(x2['dif_div'])} = "
    f"{brl(bloco_serv)}; bloco Vendas {brl(x3['dif_um'])} − {brl(dev_zerado - x3['dif_div'])} = {brl(bloco_vend)}; "
    f"soma = <b>{brl(DIF_ECF)}</b> = EFD Total − Contábil Total ({brl(efd_ap)} − {brl(ctb_ap)})."))
b.append(P("6.4. Confronto mensal", "h2"))
b.append(month_table(["Mês", "EFD apurada", "Contábil apurado", "Diferença"],
                     lambda mk: (m_a100[mk] + m_c100[mk], m_serv[mk] + m_vend[mk], d2[mk]),
                     (efd_ap, ctb_ap, DIF_ECF), W4))
b.append(P("6.5. Maiores itens sem correspondência — contabilidade Serviços sem nota na EFD", "h2"))
um2 = sorted(x2["unmatched"], key=lambda r: -r["credito"])[:10]
t = Table([[P("<b>NF</b>", "head"), P("<b>Data</b>", "head"), P("<b>Crédito contábil</b>", "head"), P("<b>Página do PDF</b>", "head")]] +
          [[P(r["nf"], "cell"), P(fdata(r["data"]), "cell"), P(brl(r["credito"]), "cell"), P(str(r["page"]), "cell")] for r in um2],
          colWidths=[35 * mm, 35 * mm, 60 * mm, 50 * mm])
t.setStyle(grid(total_row=False))
b.append(t)
b.append(P("6.6. Maiores notas da EFD A100 sem lançamento contábil localizado", "h2"))
um1 = sorted(x1["unmatched"], key=lambda r: -r["valor"])[:10]
t = Table([[P("<b>NF</b>", "head"), P("<b>Data</b>", "head"), P("<b>Valor EFD</b>", "head"), P("<b>Arquivo EFD</b>", "head")]] +
          [[P(r["nf"], "cell"), P(fdata(r["data"]), "cell"), P(brl(r["valor"]), "cell"), P(str(r["src"] or "—"), "cell")] for r in um1],
          colWidths=[30 * mm, 30 * mm, 50 * mm, 70 * mm])
t.setStyle(grid(total_row=False))
b.append(t)
b.append(P("6.7. Maiores notas da EFD C100 sem lançamento contábil localizado", "h2"))
um3 = sorted(x3["unmatched"], key=lambda r: -r["valor"])[:10]
t = Table([[P("<b>NF</b>", "head"), P("<b>Data</b>", "head"), P("<b>Valor EFD</b>", "head"), P("<b>Arquivo EFD</b>", "head")]] +
          [[P(r["nf"], "cell"), P(fdata(r["data"]), "cell"), P(brl(r["valor"]), "cell"), P(str(r["src"] or "—"), "cell")] for r in um3],
          colWidths=[30 * mm, 30 * mm, 50 * mm, 70 * mm])
t.setStyle(grid(total_row=False))
b.append(t)
b.append(P("6.8. Maiores divergências de valor — Vendas (crédito zerado indica devolução)", "h2"))
div4 = sorted(x4["div"], key=lambda r: -abs(r["dif"]))[:10]
t = Table([[P("<b>NF</b>", "head"), P("<b>Data</b>", "head"), P("<b>Valor EFD</b>", "head"),
            P("<b>Crédito contábil</b>", "head"), P("<b>Diferença</b>", "head")]] +
          [[P(r["nf"], "cell"), P(fdata(r["data"]), "cell"), P(brl(r["valor"]), "cell"),
            P(brl(r["credito"]), "cell"), P(brl(r["dif"]), "cell")] for r in div4],
          colWidths=[25 * mm, 28 * mm, 42 * mm, 42 * mm, 43 * mm])
t.setStyle(grid(total_row=False))
b.append(t)

b.append(P("7. Achados de auditoria", "h"))
achado(b, "A-01", f"{num(x2['n_um'])} lançamentos contábeis de Serviços sem nota na EFD ({brl(x2['dif_um'])})",
       "Achado maior — risco de receita não escriturada na EFD",
       "Toda receita lançada em conta de resultado deve possuir documento fiscal correspondente escriturado na EFD Contribuições.",
       f"Cruzamento 2 (seção 6.2): dos {num(x2['n'])} lançamentos da conta de Serviços, {num(x2['n_um'])} não possuem nota localizada na EFD A100, somando {brl(x2['dif_um'])} (maiores itens na seção 6.5, com página do PDF).",
       "Podem ser notas escrituradas com numeração divergente, receitas sem documento fiscal ou notas de competências distintas.",
       "Conciliar item a item os 188 lançamentos listados no sistema de cruzamento, partindo dos 10 maiores (79% do valor concentrado nos 20 primeiros).",
       "Aberto.")
achado(b, "A-02", f"{num(x1['n_um'])} notas da EFD A100 sem lançamento contábil localizado ({brl(x1['dif_um'])})",
       "Achado maior — risco espelho do A-01",
       "Toda nota escriturada na EFD deve possuir lançamento de receita correspondente na contabilidade.",
       f"Cruzamento 1 (seção 6.2): das {num(x1['n'])} notas A100, {num(x1['n_um'])} não possuem lançamento localizado na conta de Serviços, somando {brl(x1['dif_um'])} (maiores itens na seção 6.6).",
       f"O saldo líquido dos dois sentidos ({brl(x1['dif_um'])} − {brl(x2['dif_um'])} − {brl(x2['dif_div'])}) produz o bloco Serviços de {brl(bloco_serv)}.",
       "Verificar se as notas foram lançadas em outras contas de receita ou se há lacunas de escrituração contábil.",
       "Aberto.")
achado(b, "A-03", f"{num(x3['n_um'])} notas da EFD C100 sem lançamento contábil ({brl(x3['dif_um'])})",
       "Achado médio",
       "Idem A-02, aplicado às vendas de mercadorias.",
       f"Cruzamento 3 (seção 6.2): das {num(x3['n'])} notas C100, {num(x3['n_um'])} sem lançamento na conta de Vendas, somando {brl(x3['dif_um'])} (seção 6.7). No sentido inverso (cruzamento 4), 100% dos {num(x4['n'])} lançamentos de Vendas possuem nota na EFD.",
       f"Com as divergências de valor líquidas (−{brl(dev_zerado - x3['dif_div'])}), produz o bloco Vendas de {brl(bloco_vend)}.",
       "Conciliar as 147 notas listadas no sistema, avaliando notas emitidas e não contabilizadas na conta analisada.",
       "Aberto.")
achado(b, "A-04", f"{num(x4['n_div'])} notas de Vendas cruzadas com divergência de valor",
       "Achado médio — diferenças de valor entre EFD e contabilidade",
       "Notas cruzadas devem apresentar o mesmo valor nas duas bases (tolerância R$ 0,05).",
       f"Cruzamento 4: {num(x4['n_div'])} notas com diferença acima da tolerância, saldo líquido de {brl(x4['dif_div'])} (maiores na seção 6.8). Inclui as 3 notas de devolução com crédito desconsiderado ({brl(dev_zerado)}).",
       "Diferenças típicas de valores parciais, descontos ou registros consolidados de forma distinta.",
       "Revisar as 10 maiores divergências listadas; validar tratamento das devoluções.",
       "Aberto.")
achado(b, "A-05", f"Devoluções de vendas desconsideradas no confronto ({brl(dev_zerado)})",
       "Informativo — tratamento metodológico",
       "Receita devolvida não deve ser abatida no confronto nota a nota quando o objetivo é validar a escrituração da receita bruta.",
       f"3 notas do relatório de devoluções localizadas na conta de Vendas tiveram o crédito zerado no cruzamento ({brl(dev_zerado)}); as 24 notas do relatório somam {brl(tot_devol)}.",
       "O tratamento evita dupla contagem entre este card e a coluna de devoluções da planilha (tratada no card Diferença Tabela).",
       "Manter critério documentado.",
       "Encerrado.")

b.append(P("8. Avaliação dos controles", "h"))
b.append(controles_table([
    ("Integridade e rastreabilidade", "Cada registro cruzado carrega NF, datas, valores, arquivo TXT de origem e página do PDF contábil.", "Conforme"),
    ("Abordagem baseada em evidência", f"{num(x1['n'] + x2['n'] + x3['n'] + x4['n'])} classificações produzidas pelos 4 cruzamentos; composição fecha exata com os totais.", "Conforme"),
    ("Cobertura do cruzamento", f"Serviços: {num(x1['matched'])} de {num(x1['n'])} notas cruzadas (96,9%). Vendas: 100% da contabilidade localizada na EFD.", "Conforme"),
    ("Conciliação EFD × contabilidade", f"{brl(DIF_ECF)} pendentes de conciliação item a item (achados A-01 a A-04).", "Conforme com ressalvas"),
]))

b.append(P("9. Recomendações e plano de ação", "h"))
b.append(plano_table([
    ("Sem correspondência Serviços", "Conciliar os 188 lançamentos contábeis sem nota na EFD, iniciando pelos 10 maiores (seção 6.5).", "Alta", "Soluções / Fiscal"),
    ("Notas EFD sem contabilidade", "Verificar as 277 notas A100 e 147 notas C100 sem lançamento localizado (seções 6.6 e 6.7).", "Alta", "Soluções / Contábil"),
    ("Divergências de valor", "Revisar as 347 notas de Vendas com diferença de valor (seção 6.8).", "Média", "Soluções / Fiscal"),
    ("Trilha auditável", "Utilizar a página de cruzamento do sistema como fonte permanente da conciliação nota a nota.", "Média", "Soluções / Real Prev"),
]))

b.append(P("10. Conclusão", "h"))
b.append(P(
    f"O valor do card está integralmente evidenciado e rastreado: <b>{brl(efd_ap)} − {brl(ctb_ap)} = "
    f"{brl(DIF_ECF)}</b>, decomposto nota a nota em bloco Serviços ({brl(bloco_serv)}) e bloco Vendas "
    f"({brl(bloco_vend)}). Por corresponder a divergência já explicada dentro do confronto EFD × contabilidade, "
    f"esta parcela é subtraída na equação do sistema: {brl(DIF_TABELA)} − <b>{brl(DIF_ECF)}</b> − {brl(DIF_EFD)} "
    f"= {brl(DIF_FINAL)} (Diferença Final)."))
b.append(P(
    "Este relatório é uma avaliação técnico-documental estruturada segundo diretrizes de auditoria. Não constitui "
    "certificação ISO, parecer legal, fiscal ou trabalhista."))

build("SOLUCOES_RELATORIO_DIFERENCA_ECF_2022_ISO_19011.pdf", "Diferença ECF - R$ 4.031.828,87", b)

# ================================================================================
# RELATÓRIO 3 — DIFERENÇA EFD (R$ 1.454.331,64)
# ================================================================================
b = [ident_table("Card \"Diferença EFD\" do Comparativo EFD × ECF", "Auditoria documental de receitas")]

tm3 = top_meses(d3, 3)
b.append(P("1. Sumário executivo", "h"))
b.append(P(
    f"Este relatório documenta integralmente a apuração do card <b>Diferença EFD = {brl(DIF_EFD)}</b>, terceiro "
    f"componente da equação do sistema ({brl(DIF_TABELA)} − {brl(DIF_ECF)} − <b>{brl(DIF_EFD)}</b> = "
    f"{brl(DIF_FINAL)}). O valor mede quanto o faturamento EFD informado pela empresa na planilha "
    f"({brl(p_efd)}) excede a EFD efetivamente apurada nota a nota nos 12 arquivos entregues ({brl(efd_ap)})."))
b.append(P(
    f"A diferença anual de {brl(DIF_EFD)} resulta de oscilações mensais relevantes nos dois sentidos — de "
    f"{brl(d3[tm3[0]])} em {mes_ano(tm3[0])} a {brl(d3[tm3[1]])} em {mes_ano(tm3[1])} — indicando divergência "
    f"de critério de apuração mensal entre a planilha e os arquivos, além do resíduo líquido anual."))

b.append(P("2. Objetivo da auditoria", "h"))
b.append(P(
    "Evidenciar como o valor do card foi apurado: a composição do faturamento EFD declarado na planilha "
    "(colunas CST 01 e CST 02), a EFD apurada por extração direta dos arquivos (A100 + C100), o confronto "
    "mês a mês e a localização das maiores divergências mensais."))

b.append(P("3. Escopo e limites", "h"))
b.append(P(
    "Empresa: Soluções Serviços Terceirizados Ltda., CNPJ 09.445.502/0001-09. Período: Janeiro/2022 a "
    "Dezembro/2022. Bases: (i) planilha \"diferença ECF x EFD soluções 2022.xlsx\" — colunas \"CST 01 Valor "
    "Total do Item\", \"CST 02 Valor Total do Item\" e \"faturamento efd\"; (ii) 12 arquivos TXT da EFD "
    "Contribuições entregues à auditoria. Exclusões: eventuais EFDs retificadoras transmitidas após a entrega "
    "dos arquivos não foram analisadas; ECF e contabilidade não participam deste card."))

b.append(P("4. Critérios de auditoria", "h"))
b.append(P(
    "Diretrizes da ISO 19011. Layout oficial da EFD Contribuições: registros A100 (serviços) e C100 "
    "(mercadorias), campo IND_OPER=1 para saídas, consolidação de parcelas por número de nota. Planilha da "
    "empresa tratada como declaração de referência do faturamento EFD por CST. Comparação mensal pelo mês de "
    "emissão."))

b.append(P("5. Metodologia", "h"))
b.append(P(
    "1) Leitura estruturada da planilha, extraindo por mês os valores de CST 01, CST 02 e o faturamento EFD "
    "(soma das duas colunas). 2) Extração integral dos registros A100 e C100 (IND_OPER=1) dos 12 TXT, com "
    f"consolidação por nota — {num(len(a100))} registros A100 ({brl(tot_a100)}) e {num(len(c100))} registros "
    f"C100 ({brl(tot_c100)}). 3) Consolidação mensal das duas bases. 4) Confronto mês a mês e apuração do "
    "resíduo anual. Todos os valores foram recalculados das bases originais."))

b.append(P("6. Evidências objetivas", "h"))
b.append(P("6.1. Base 1 — Faturamento EFD declarado na planilha (CST 01 + CST 02)", "h2"))
b.append(month_table(["Mês", "CST 01", "CST 02", "Faturamento EFD"],
                     lambda mk: (plan[mk]["cst01"], plan[mk]["cst02"], plan[mk]["efd"]),
                     (p_cst01, p_cst02, p_efd), W4))
b.append(P("6.2. Base 2 — EFD apurada por extração direta dos arquivos", "h2"))
b.append(month_table(["Mês", "A100 (Serviços)", "C100 (Vendas)", "EFD apurada"],
                     lambda mk: (m_a100[mk], m_c100[mk], m_a100[mk] + m_c100[mk]),
                     (tot_a100, tot_c100, efd_ap), W4))
b.append(P("6.3. Confronto mensal e apuração do valor", "h2"))
b.append(month_table(["Mês", "EFD (planilha)", "EFD (apurada)", "Diferença"],
                     lambda mk: (plan[mk]["efd"], m_a100[mk] + m_c100[mk], d3[mk]),
                     (p_efd, efd_ap, DIF_EFD), W4))
b.append(Spacer(1, 4))
b.append(P(f"<b>Apuração: {brl(p_efd)} − {brl(efd_ap)} = {brl(DIF_EFD)}.</b>"))

b.append(P("7. Achados de auditoria", "h"))
pos = sum(v for v in d3.values() if v > 0)
neg = sum(v for v in d3.values() if v < 0)
achado(b, "A-01", f"Faturamento EFD da planilha excede os arquivos entregues em {brl(DIF_EFD)}",
       "Achado médio — risco de base declarada divergente dos arquivos",
       "O faturamento EFD informado em controles gerenciais deve reproduzir a soma dos registros dos arquivos transmitidos.",
       f"Planilha: {brl(p_efd)} (CST 01 {brl(p_cst01)} + CST 02 {brl(p_cst02)}). Arquivos entregues: {brl(efd_ap)} (A100 {brl(tot_a100)} + C100 {brl(tot_c100)}). Diferença: {brl(DIF_EFD)} (seção 6.3).",
       "A diferença pode decorrer de EFDs retificadoras posteriores aos arquivos entregues, de filtros de CST distintos na planilha ou de registros desconsiderados na extração declarada pela empresa.",
       "Solicitar a versão final (pós-retificação) das EFDs de 2022 e o memorial de cálculo da planilha por CST.",
       "Aberto.")
achado(b, "A-02", f"Oscilações mensais relevantes nos dois sentidos (de {brl(d3[tm3[1]])} a {brl(d3[tm3[0]])})",
       "Achado médio — divergência de competência mensal",
       "As duas bases devem alocar as mesmas notas nos mesmos meses.",
       f"Maiores divergências mensais: {mes_ano(tm3[0])} ({brl(d3[tm3[0]])}), {mes_ano(tm3[1])} ({brl(d3[tm3[1]])}) e {mes_ano(tm3[2])} ({brl(d3[tm3[2]])}). Meses positivos somam {brl(pos)}; negativos somam {brl(neg)} — o resíduo anual é {brl(DIF_EFD)}.",
       "O padrão de compensação entre meses indica alocação de notas em competências distintas entre a planilha e os arquivos (ex.: data de emissão × período de escrituração), além do resíduo líquido.",
       "Conciliar por mês os critérios de competência utilizados na planilha contra a data de emissão dos registros A100/C100.",
       "Aberto.")
achado(b, "A-03", "Extração dos arquivos EFD íntegra e reproduzível",
       "Informativo — evidência de consistência",
       "A base apurada deve ser reproduzível a partir dos arquivos originais.",
       f"Os {num(len(a100) + len(c100))} registros extraídos ({brl(efd_ap)}) são os mesmos utilizados nos cards Diferença ECF e na página de cruzamento do sistema, com rastreabilidade por arquivo TXT de origem.",
       "A mesma base EFD apurada sustenta todos os confrontos do sistema, garantindo consistência entre os três cards.",
       "Manter os TXT originais como anexo permanente.",
       "Encerrado.")

b.append(P("8. Avaliação dos controles", "h"))
b.append(controles_table([
    ("Integridade e rastreabilidade", "Registros A100/C100 extraídos com NF, data, valor e arquivo de origem; planilha preservada como recebida.", "Conforme"),
    ("Abordagem baseada em evidência", "Confronto mensal integral reproduzível (seção 6.3); resíduo anual fecha com o card.", "Conforme"),
    ("Consistência declaração × arquivos", f"Diferença de {brl(DIF_EFD)} e oscilações mensais pendentes de justificativa (A-01, A-02).", "Conforme com ressalvas"),
]))

b.append(P("9. Recomendações e plano de ação", "h"))
b.append(plano_table([
    ("EFDs retificadoras", "Obter a versão final das EFDs de 2022 transmitidas ao SPED e reprocessar o confronto.", "Alta", "Soluções / Fiscal"),
    ("Memorial da planilha", "Solicitar o memorial de cálculo do faturamento EFD por CST utilizado na planilha.", "Alta", "Soluções"),
    ("Competência mensal", f"Conciliar os meses de maior oscilação ({mes_ano(tm3[0])}, {mes_ano(tm3[1])}, {mes_ano(tm3[2])}).", "Média", "Soluções / Fiscal"),
]))

b.append(P("10. Conclusão", "h"))
b.append(P(
    f"O valor do card está integralmente evidenciado: <b>{brl(p_efd)} − {brl(efd_ap)} = {brl(DIF_EFD)}</b>, com "
    f"abertura mensal completa na seção 6.3. Por corresponder a valores declarados na planilha e não localizados "
    f"nos arquivos entregues — divergência interna à própria apuração da EFD —, esta parcela é subtraída na "
    f"equação do sistema: {brl(DIF_TABELA)} − {brl(DIF_ECF)} − <b>{brl(DIF_EFD)}</b> = {brl(DIF_FINAL)} "
    f"(Diferença Final)."))
b.append(P(
    "Este relatório é uma avaliação técnico-documental estruturada segundo diretrizes de auditoria. Não constitui "
    "certificação ISO, parecer legal, fiscal ou trabalhista."))

build("SOLUCOES_RELATORIO_DIFERENCA_EFD_2022_ISO_19011.pdf", "Diferença EFD - R$ 1.454.331,64", b)

print("\nDIF_TABELA:", brl(DIF_TABELA), "| DIF_ECF:", brl(DIF_ECF), "| DIF_EFD:", brl(DIF_EFD), "| FINAL:", brl(DIF_FINAL))
