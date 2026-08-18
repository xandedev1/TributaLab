# -*- coding: utf-8 -*-
"""Gera 3 relatórios ISO (Diferença Tabela, Diferença ECF, Diferença EFD) — SOLUÇÕES 2022.
Planilha lida direto do xlsx; EFD/contabilidade dos JSONs; tudo validado por assert."""
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


def load(name):
    with open(f"{BASE}\\{name}", encoding="utf-8") as f:
        return json.load(f)


def dec(v):
    return Decimal(str(v)).quantize(Decimal("0.01"))


def brl(v):
    s = f"{v:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return f"R$ {s}"


def num(n):
    return f"{n:,}".replace(",", ".")


# ------------------------------------------------------------------ planilha (xlsx)
df = pd.read_excel(XLSX, header=None)
plan = {}
for i, mk in enumerate(MKEYS):
    row = df.iloc[i + 2]
    plan[mk] = {
        "cst01": dec(row[0]), "cst02": dec(row[1]), "efd": dec(row[2]),
        "ecf_bruto": dec(row[3]), "dev": dec(row[4]) if pd.notna(row[4]) else Decimal("0.00"),
        "ecf_liq": dec(row[5]),
    }
p_efd = sum(p["efd"] for p in plan.values())
p_ecf_bruto = sum(p["ecf_bruto"] for p in plan.values())
p_dev = sum(p["dev"] for p in plan.values())
p_ecf_liq = sum(p["ecf_liq"] for p in plan.values())
assert p_efd == Decimal("927910661.06") and p_ecf_liq == Decimal("945131931.92")
assert p_ecf_bruto == Decimal("949047070.79") and p_dev == Decimal("3915138.87")

# ------------------------------------------------------------------ bases apuradas (JSONs)
efd = load("efd_razao.json")
a100, c100 = efd["a100"], efd["c100"]
serv = load("razao_servicos.json")["records"]
vend = load("razao_vendas.json")["records"]
devol = load("devolucao.json")["records"]
devol_nfs = {r["num_nf"] for r in devol}


def monthly(records, field):
    out = {mk: Decimal("0.00") for mk in MKEYS}
    for r in records:
        mk = (r.get("data_emissao") or "")[:7]
        if mk in out:
            out[mk] += dec(r[field])
    return out


m_a100 = monthly(a100, "valor_nf")
m_c100 = monthly(c100, "valor_nf")
m_serv = monthly(serv, "credito")
m_vend = monthly(vend, "credito")

tot_a100, tot_c100 = sum(m_a100.values()), sum(m_c100.values())
tot_serv, tot_vend = sum(m_serv.values()), sum(m_vend.values())
efd_ap = tot_a100 + tot_c100
ctb_ap = tot_serv + tot_vend
assert tot_a100 == Decimal("712818493.94") and tot_c100 == Decimal("213637835.48")
assert tot_serv == Decimal("711921394.96") and tot_vend == Decimal("210503105.59")
assert efd_ap == Decimal("926456329.42") and ctb_ap == Decimal("922424500.55")

DIF_TABELA = p_ecf_liq - ctb_ap
DIF_ECF = efd_ap - ctb_ap
DIF_EFD = p_efd - efd_ap
assert DIF_TABELA == Decimal("22707431.37")
assert DIF_ECF == Decimal("4031828.87")
assert DIF_EFD == Decimal("1454331.64")
assert DIF_TABELA - DIF_ECF - DIF_EFD == Decimal("17221270.86")

# cruzamento (mesma lógica do site) para o relatório Diferença ECF
def cross_stats(base, match, direction, vfield_base, vfield_match):
    by_nf = {}
    for r in match:
        by_nf.setdefault(r["num_nf"], []).append(r)
    n = len(base); matched = 0; ok = 0; ndiv = 0; unmatched = 0
    dif_div = Decimal("0.00"); dif_um = Decimal("0.00"); dev_raw = Decimal("0.00")
    for b in base:
        ms = by_nf.get(b["num_nf"])
        is_dev = b["num_nf"] in devol_nfs
        if ms:
            m = ms[0]
            matched += 1
            if direction == "txt_to_pdf":
                credito = Decimal(0) if is_dev else dec(m[vfield_match])
                d = dec(b[vfield_base]) - credito
            else:
                credito = Decimal(0) if is_dev else dec(b[vfield_base])
                d = credito - dec(m[vfield_match])
                if is_dev:
                    dev_raw += dec(b[vfield_base])
            if abs(d) <= Decimal("0.05"):
                ok += 1
            else:
                ndiv += 1; dif_div += d
        else:
            unmatched += 1
            dif_um += dec(b[vfield_base])
    return {"n": n, "matched": matched, "ok": ok, "ndiv": ndiv, "unmatched": unmatched,
            "dif_div": dif_div, "dif_um": dif_um, "dev_raw": dev_raw}


r1 = cross_stats(a100, serv, "txt_to_pdf", "valor_nf", "credito")
r2 = cross_stats(serv, a100, "pdf_to_txt", "credito", "valor_nf")
r3 = cross_stats(c100, vend, "txt_to_pdf", "valor_nf", "credito")
r4 = cross_stats(vend, c100, "pdf_to_txt", "credito", "valor_nf")
dev_zerado = r4["dev_raw"]
bloco_serv = tot_a100 - tot_serv
bloco_vend = tot_c100 - tot_vend
assert r1["dif_um"] == Decimal("13627974.25") and r2["dif_um"] == Decimal("12727088.05")
assert r2["dif_div"] == Decimal("3787.22") and bloco_serv == Decimal("897098.98")
assert r3["dif_um"] == Decimal("3802140.59") and bloco_vend == Decimal("3134729.89")
assert dev_zerado == Decimal("400894.61")
assert bloco_serv + bloco_vend == DIF_ECF

hoje = date.today().strftime("%d/%m/%Y")

# ------------------------------------------------------------------ layout comum
S = {
    "title": ParagraphStyle("t", fontName="Helvetica-Bold", fontSize=22, leading=26, alignment=1, textColor=NAVY, spaceAfter=4),
    "subtitle": ParagraphStyle("st", fontName="Helvetica-Bold", fontSize=15, leading=19, alignment=1, textColor=NAVY, spaceAfter=4),
    "version": ParagraphStyle("v", fontName="Helvetica", fontSize=10, alignment=1, textColor=GREY, spaceAfter=12),
    "h": ParagraphStyle("h", fontName="Helvetica-Bold", fontSize=13, textColor=ORANGE, spaceBefore=14, spaceAfter=6),
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


def grid(extra=None):
    return TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("BACKGROUND", (0, -1), (-1, -1), LIGHT),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 2.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5),
    ] + (extra or []))


def ident_table(objeto):
    t = Table([
        [P("<b>Empresa auditada</b>", "cell"), P("Soluções Serviços Terceirizados Ltda.", "cell"),
         P("<b>CNPJ</b>", "cell"), P("09.445.502/0001-09", "cell")],
        [P("<b>Período auditado</b>", "cell"), P("Janeiro/2022 a Dezembro/2022", "cell"),
         P("<b>Data de emissão</b>", "cell"), P(hoje, "cell")],
        [P("<b>Objeto</b>", "cell"), P(objeto, "cell"), P("<b>Versão</b>", "cell"), P("1.0", "cell")],
        [P("<b>Referência</b>", "cell"), P("ISO 19011", "cell"), P("<b>Uso</b>", "cell"), P("Restrito", "cell")],
    ], colWidths=[32 * mm, 62 * mm, 32 * mm, 54 * mm])
    t.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
        ("BACKGROUND", (0, 0), (0, -1), LIGHT),
        ("BACKGROUND", (2, 0), (2, -1), LIGHT),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return t


def month_table(headers, rowfn, totals, widths):
    rows = [[P(f"<b>{h}</b>", "head") for h in headers]]
    for i, mk in enumerate(MKEYS):
        rows.append([P(f"{MESES[i]}/2022", "cell")] + [P(brl(v), "cell") for v in rowfn(mk)])
    rows.append([P("<b>Total</b>", "cellb")] + [P(f"<b>{brl(t)}</b>", "cellb") for t in totals])
    t = Table(rows, colWidths=widths)
    t.setStyle(grid())
    return t


def build(filename, subtitle, story_body):
    out = f"{OUTDIR}\\{filename}"
    doc = BaseDocTemplate(out, pagesize=A4, leftMargin=15 * mm, rightMargin=15 * mm,
                          topMargin=22 * mm, bottomMargin=15 * mm)
    doc.addPageTemplates([PageTemplate(id="all", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="f")], onPage=header_footer)])
    story = [P("REAL PREV", "title"), P(subtitle, "subtitle"),
             P("Versão estruturada conforme diretrizes de auditoria da ISO 19011", "version")] + story_body
    doc.build(story)
    print("OK:", out)


W4 = [30 * mm, 50 * mm, 50 * mm, 50 * mm]

# ================================================================== R1: DIFERENÇA TABELA
body = [ident_table("Card \"Diferença Tabela\" — R$ 22.707.431,37")]
body.append(P("1. O valor em análise", "h"))
body.append(P(
    f"<b>Diferença Tabela = ECF da planilha (líquida de devoluções) − Contábil apurado = "
    f"{brl(p_ecf_liq)} − {brl(ctb_ap)} = {brl(DIF_TABELA)}.</b> Mede quanto a receita declarada na ECF pela "
    f"empresa excede a receita efetivamente escriturada nas contas contábeis de receita analisadas."))
body.append(P("2. Base 1 — ECF da planilha enviada pela empresa", "h"))
body.append(P(
    "Fonte: planilha \"diferença ECF x EFD soluções 2022.xlsx\" enviada pela empresa. A coluna \"faturamento "
    "ecf\" líquida resulta do faturamento ECF bruto menos as devoluções de vendas informadas na própria "
    "planilha (o total de devoluções coincide, centavo a centavo, com as 24 notas do relatório de devoluções "
    "entregue). Dados mês a mês:"))
body.append(month_table(
    ["Mês", "ECF bruto", "Devoluções", "ECF líquido"],
    lambda mk: (plan[mk]["ecf_bruto"], plan[mk]["dev"], plan[mk]["ecf_liq"]),
    (p_ecf_bruto, p_dev, p_ecf_liq), W4))
body.append(P("3. Base 2 — Contabilidade apurada nesta auditoria", "h"))
body.append(P(
    f"Fonte: PDFs das contas contábeis de receita de Serviços ({num(len(serv))} lançamentos) e de Vendas "
    f"({num(len(vend))} lançamentos), extraídos lançamento a lançamento com número de nota, data, valor de "
    f"crédito e página de origem. Dados mês a mês:"))
body.append(month_table(
    ["Mês", "Serviços", "Vendas", "Contábil total"],
    lambda mk: (m_serv[mk], m_vend[mk], m_serv[mk] + m_vend[mk]),
    (tot_serv, tot_vend, ctb_ap), W4))
body.append(P("4. Confronto e resultado", "h"))
body.append(month_table(
    ["Mês", "ECF líquido (planilha)", "Contábil apurado", "Diferença"],
    lambda mk: (plan[mk]["ecf_liq"], m_serv[mk] + m_vend[mk], plan[mk]["ecf_liq"] - m_serv[mk] - m_vend[mk]),
    (p_ecf_liq, ctb_ap, DIF_TABELA), W4))
body.append(Spacer(1, 4))
body.append(P(
    f"<b>Resultado: {brl(p_ecf_liq)} − {brl(ctb_ap)} = {brl(DIF_TABELA)}.</b>"))
body.append(P("5. Conclusão", "h"))
body.append(P(
    f"A receita declarada na ECF excede em {brl(DIF_TABELA)} a receita escriturada nas contas de Serviços e "
    f"Vendas analisadas. É a divergência bruta entre declaração fiscal e contabilidade — ponto de partida da "
    f"decomposição que, subtraídas a Diferença ECF ({brl(DIF_ECF)}) e a Diferença EFD ({brl(DIF_EFD)}), chega à "
    f"Diferença Final de R$ 17.221.270,86. Recomenda-se identificar as demais contas de receita ou ajustes que "
    f"compõem a ECF, documentando a conciliação."))
build("SOLUCOES_RELATORIO_DIFERENCA_TABELA_2022_ISO_19011.pdf",
      "Diferença Tabela - R$ 22.707.431,37", body)

# ================================================================== R2: DIFERENÇA ECF
body = [ident_table("Card \"Diferença ECF\" — R$ 4.031.828,87")]
body.append(P("1. O valor em análise", "h"))
body.append(P(
    f"<b>Diferença ECF = EFD apurada − Contábil apurado = {brl(efd_ap)} − {brl(ctb_ap)} = {brl(DIF_ECF)}.</b> "
    f"Mede quanto a receita escriturada na EFD Contribuições excede a receita lançada nas contas contábeis. "
    f"Esta parcela está 100% identificada nota a nota na página de cruzamento do sistema."))
body.append(P("2. Bases utilizadas", "h"))
t = Table([
    [P("<b>Base</b>", "head"), P("<b>Origem</b>", "head"), P("<b>Registros</b>", "head"), P("<b>Total 2022</b>", "head")],
    [P("EFD A100 (Serviços)", "cell"), P("12 TXT da EFD Contribuições", "cell"), P(num(len(a100)), "cell"), P(brl(tot_a100), "cell")],
    [P("EFD C100 (Vendas, saídas IND_OPER=1)", "cell"), P("12 TXT da EFD Contribuições", "cell"), P(num(len(c100)), "cell"), P(brl(tot_c100), "cell")],
    [P("Contabilidade Serviços", "cell"), P("Conta contábil (PDF)", "cell"), P(num(len(serv)), "cell"), P(brl(tot_serv), "cell")],
    [P("Contabilidade Vendas", "cell"), P("Conta contábil (PDF)", "cell"), P(num(len(vend)), "cell"), P(brl(tot_vend), "cell")],
    [P("Devoluções de vendas", "cell"), P("Relatório de devoluções (PDF)", "cell"), P(str(len(devol)), "cell"), P(brl(sum(dec(r['valor']) for r in devol)), "cell")],
    [P("<b>EFD Total / Contábil Total</b>", "cellb"), P("", "cell"), P("", "cell"), P(f"<b>{brl(efd_ap)} / {brl(ctb_ap)}</b>", "cellb")],
], colWidths=[55 * mm, 50 * mm, 22 * mm, 53 * mm])
t.setStyle(grid())
body.append(t)
body.append(P("3. Lógica do cruzamento", "h"))
body.append(P(
    "O número de cada nota fiscal foi normalizado (últimos 5 dígitos significativos) e usado como chave nas duas "
    "pontas. Cada registro é classificado como <b>OK</b> (localizado na outra base, diferença ≤ R$ 0,05), "
    "<b>Divergência</b> (localizado, diferença > R$ 0,05) ou <b>Sem match</b> (não localizado). As notas de "
    "devolução têm o crédito contábil desconsiderado nas notas cruzadas. Quatro relatórios foram executados — "
    "dois partindo da EFD e dois partindo da contabilidade:"))
t = Table([
    [P("<b>Relatório</b>", "head"), P("<b>Regs.</b>", "head"), P("<b>Cruz.</b>", "head"), P("<b>OK</b>", "head"),
     P("<b>Div.</b>", "head"), P("<b>Sem match</b>", "head"), P("<b>Valor sem match</b>", "head")],
    [P("1. EFD(A100) − (Serviços)", "cell"), P(num(r1["n"]), "cell"), P(num(r1["matched"]), "cell"),
     P(num(r1["ok"]), "cell"), P(num(r1["ndiv"]), "cell"), P(num(r1["unmatched"]), "cell"), P(brl(r1["dif_um"]), "cell")],
    [P("2. (Serviços) − EFD(A100)", "cell"), P(num(r2["n"]), "cell"), P(num(r2["matched"]), "cell"),
     P(num(r2["ok"]), "cell"), P(num(r2["ndiv"]), "cell"), P(num(r2["unmatched"]), "cell"), P(brl(r2["dif_um"]), "cell")],
    [P("3. EFD(C100) − (Vendas)", "cell"), P(num(r3["n"]), "cell"), P(num(r3["matched"]), "cell"),
     P(num(r3["ok"]), "cell"), P(num(r3["ndiv"]), "cell"), P(num(r3["unmatched"]), "cell"), P(brl(r3["dif_um"]), "cell")],
    [P("4. (Vendas) − EFD(C100)", "cell"), P(num(r4["n"]), "cell"), P(num(r4["matched"]), "cell"),
     P(num(r4["ok"]), "cell"), P(num(r4["ndiv"]), "cell"), P(num(r4["unmatched"]), "cell"), P(brl(r4["dif_um"]), "cell")],
], colWidths=[48 * mm, 16 * mm, 16 * mm, 14 * mm, 14 * mm, 20 * mm, 52 * mm])
t.setStyle(grid([("BACKGROUND", (0, -1), (-1, -1), colors.white)]))
body.append(t)
body.append(P("4. Composição exata do valor", "h"))
t = Table([
    [P("<b>Bloco</b>", "head"), P("<b>Composição</b>", "head"), P("<b>Valor</b>", "head")],
    [P("Serviços<br/>(A100 × conta Serviços)", "cell"),
     P(f"Notas só na EFD: +{brl(r1['dif_um'])} ({num(r1['unmatched'])} notas)<br/>"
       f"Lançamentos só na contabilidade: −{brl(r2['dif_um'])} ({num(r2['unmatched'])} lançamentos)<br/>"
       f"Divergência de valor nas cruzadas: −{brl(r2['dif_div'])} (1 nota)", "cell"),
     P(f"<b>{brl(bloco_serv)}</b>", "cellb")],
    [P("Vendas<br/>(C100 × conta Vendas)", "cell"),
     P(f"Notas só na EFD: +{brl(r3['dif_um'])} ({num(r3['unmatched'])} notas)<br/>"
       f"Divergências nas cruzadas: −{brl(dev_zerado - r3['dif_div'])} líquido ({num(r3['ndiv'])} notas, "
       f"incluindo devoluções de {brl(dev_zerado)})", "cell"),
     P(f"<b>{brl(bloco_vend)}</b>", "cellb")],
    [P("<b>Total</b>", "cellb"), P(f"<b>{brl(bloco_serv)} + {brl(bloco_vend)}</b>", "cellb"),
     P(f"<b>{brl(DIF_ECF)}</b>", "cellb")],
], colWidths=[42 * mm, 95 * mm, 43 * mm])
t.setStyle(grid())
body.append(t)
body.append(P("5. Confronto mensal", "h"))
body.append(month_table(
    ["Mês", "EFD apurada", "Contábil apurado", "Diferença"],
    lambda mk: (m_a100[mk] + m_c100[mk], m_serv[mk] + m_vend[mk],
                m_a100[mk] + m_c100[mk] - m_serv[mk] - m_vend[mk]),
    (efd_ap, ctb_ap, DIF_ECF), W4))
body.append(P("6. Conclusão", "h"))
body.append(P(
    f"A EFD excede a contabilidade em <b>{brl(DIF_ECF)}</b>, valor integralmente rastreado nota a nota "
    f"(bloco Serviços {brl(bloco_serv)} + bloco Vendas {brl(bloco_vend)}). Por já estar explicada dentro do "
    f"confronto EFD × contabilidade, esta parcela é subtraída da Diferença Tabela na apuração da Diferença "
    f"Final de R$ 17.221.270,86. Cada nota é verificável na página de cruzamento do sistema, com arquivo de "
    f"origem e página do PDF contábil."))
build("SOLUCOES_RELATORIO_DIFERENCA_ECF_2022_ISO_19011.pdf",
      "Diferença ECF - R$ 4.031.828,87", body)

# ================================================================== R3: DIFERENÇA EFD
body = [ident_table("Card \"Diferença EFD\" — R$ 1.454.331,64")]
body.append(P("1. O valor em análise", "h"))
body.append(P(
    f"<b>Diferença EFD = EFD da planilha − EFD apurada = {brl(p_efd)} − {brl(efd_ap)} = {brl(DIF_EFD)}.</b> "
    f"Mede quanto o faturamento EFD informado pela empresa na planilha excede a soma dos registros A100/C100 "
    f"efetivamente localizados nos 12 arquivos da EFD Contribuições entregues."))
body.append(P("2. Base 1 — EFD da planilha enviada pela empresa", "h"))
body.append(P(
    "Fonte: planilha \"diferença ECF x EFD soluções 2022.xlsx\". O faturamento EFD da planilha é a soma das "
    "colunas \"CST 01\" e \"CST 02\" (Valor Total do Item). Dados mês a mês:"))
body.append(month_table(
    ["Mês", "CST 01", "CST 02", "Faturamento EFD"],
    lambda mk: (plan[mk]["cst01"], plan[mk]["cst02"], plan[mk]["efd"]),
    (sum(p["cst01"] for p in plan.values()), sum(p["cst02"] for p in plan.values()), p_efd), W4))
body.append(P("3. Base 2 — EFD apurada nesta auditoria", "h"))
body.append(P(
    f"Fonte: 12 arquivos TXT da EFD Contribuições de 2022. Extração integral dos registros A100 (serviços, "
    f"{num(len(a100))} registros) e C100 (vendas, somente saídas IND_OPER=1, {num(len(c100))} registros após "
    f"consolidação de parcelas da mesma nota). Dados mês a mês:"))
body.append(month_table(
    ["Mês", "A100 (Serviços)", "C100 (Vendas)", "EFD apurada"],
    lambda mk: (m_a100[mk], m_c100[mk], m_a100[mk] + m_c100[mk]),
    (tot_a100, tot_c100, efd_ap), W4))
body.append(P("4. Confronto e resultado", "h"))
body.append(month_table(
    ["Mês", "EFD (planilha)", "EFD (apurada)", "Diferença"],
    lambda mk: (plan[mk]["efd"], m_a100[mk] + m_c100[mk], plan[mk]["efd"] - m_a100[mk] - m_c100[mk]),
    (p_efd, efd_ap, DIF_EFD), W4))
body.append(Spacer(1, 4))
body.append(P(f"<b>Resultado: {brl(p_efd)} − {brl(efd_ap)} = {brl(DIF_EFD)}.</b>"))
body.append(P("5. Conclusão", "h"))
body.append(P(
    f"A planilha da empresa considera {brl(DIF_EFD)} a mais de faturamento EFD do que consta nos arquivos "
    f"entregues. Por já estar explicada na conciliação da própria EFD, esta parcela é subtraída da Diferença "
    f"Tabela na apuração da Diferença Final de R$ 17.221.270,86. Recomenda-se verificar se houve retificações "
    f"da EFD posteriores aos arquivos disponibilizados e conferir os meses com maior diferença no confronto "
    f"da seção 4."))
build("SOLUCOES_RELATORIO_DIFERENCA_EFD_2022_ISO_19011.pdf",
      "Diferença EFD - R$ 1.454.331,64", body)

print("\nDIF_TABELA:", brl(DIF_TABELA))
print("DIF_ECF:   ", brl(DIF_ECF))
print("DIF_EFD:   ", brl(DIF_EFD))
print("FINAL:     ", brl(DIF_TABELA - DIF_ECF - DIF_EFD))
