# -*- coding: utf-8 -*-
"""Relatório Detalhado de Notas e Divergências — SOLUÇÕES 2022.
Lista TODAS as notas PDF (contabilidade) × TXT (EFD) em 5 seções:
1) OK por período  2) Divergentes PDF>TXT  3) Divergentes TXT>PDF
4) Só no PDF  5) Só no TXT. Contagens e somas validadas por assert."""
import json
from datetime import date
from decimal import Decimal

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, Table, TableStyle,
)

BASE = r"C:\Users\xandao\Documents\GitHub\TributaLab\tmp"
OUT = r"C:\Users\xandao\Downloads\SOLUCOES_RELATORIO_DETALHADO_NOTAS_E_DIVERGENCIAS_2022.pdf"

NAVY = colors.HexColor("#16202e")
ORANGE = colors.HexColor("#d2572b")
GREY = colors.HexColor("#4a4a4a")
LIGHT = colors.HexColor("#faf3ee")
BORDER = colors.HexColor("#d9d9d9")
OKBG = colors.HexColor("#eef7ee")
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
    return f"{'-' if neg else ''}R$ {s}"


def moeda(v):  # célula compacta
    neg = v < 0
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return f"{'-' if neg else ''}{s}"


def num(n):
    return f"{n:,}".replace(",", ".")


def fdata(iso):
    if not iso:
        return "—"
    y, m, d = iso.split("-")
    return f"{d}/{m}/{y}"


# ================================================================ dados e cruzamento
efd = load("efd_razao.json")
a100, c100 = efd["a100"], efd["c100"]
serv = load("razao_servicos.json")["records"]
vend = load("razao_vendas.json")["records"]
devol_nfs = {r["num_nf"] for r in load("devolucao.json")["records"]}


def cross_pdf_txt(pdf_recs, txt_recs, origem):
    """Base = PDF (contabilidade). Retorna (pares, so_pdf) na lógica exata do site."""
    by_nf = {}
    for r in txt_recs:
        by_nf.setdefault(r["num_nf"], []).append(r)
    pares, so_pdf = [], []
    for b in pdf_recs:
        ms = by_nf.get(b["num_nf"])
        is_dev = b["num_nf"] in devol_nfs
        if ms:
            m = ms[0]
            credito = Decimal(0) if is_dev else dec(b["credito"])
            pares.append({"origem": origem, "nf": b["num_nf"], "data": b["data_emissao"],
                          "pdf": credito, "txt": dec(m["valor_nf"]), "dif": credito - dec(m["valor_nf"]),
                          "dev": is_dev})
        else:
            so_pdf.append({"origem": origem, "nf": b["num_nf"], "data": b["data_emissao"],
                           "pdf": dec(b["credito"]), "txt": Decimal("0.00"), "dif": dec(b["credito"]),
                           "dev": is_dev})
    return pares, so_pdf


def so_txt_list(txt_recs, pdf_recs, origem):
    nfs_pdf = {r["num_nf"] for r in pdf_recs}
    out = []
    for r in txt_recs:
        if r["num_nf"] not in nfs_pdf:
            out.append({"origem": origem, "nf": r["num_nf"], "data": r["data_emissao"],
                        "pdf": Decimal("0.00"), "txt": dec(r["valor_nf"]), "dif": -dec(r["valor_nf"]),
                        "dev": r["num_nf"] in devol_nfs})
    return out


pares_s, so_pdf_s = cross_pdf_txt(serv, a100, "Serviços")
pares_v, so_pdf_v = cross_pdf_txt(vend, c100, "Vendas")
so_txt_s = so_txt_list(a100, serv, "Serviços")
so_txt_v = so_txt_list(c100, vend, "Vendas")

pares = pares_s + pares_v
so_pdf = so_pdf_s + so_pdf_v
so_txt = so_txt_s + so_txt_v

TOL = Decimal("0.05")
oks = sorted([r for r in pares if abs(r["dif"]) <= TOL], key=lambda r: (r["data"] or "", r["nf"]))
div_pdf = sorted([r for r in pares if r["dif"] > TOL], key=lambda r: (r["data"] or "", r["nf"]))
div_txt = sorted([r for r in pares if r["dif"] < -TOL], key=lambda r: (r["data"] or "", r["nf"]))
so_pdf = sorted(so_pdf, key=lambda r: (r["data"] or "", r["nf"]))
so_txt = sorted(so_txt, key=lambda r: (r["data"] or "", r["nf"]))

# validação contra os números conhecidos do sistema
assert len(pares) == 8618 + 1650 == 10268
assert len(oks) == 8617 + 1303 == 9920
assert len(div_pdf) + len(div_txt) == 348
assert len(so_pdf) == 188 and len(so_pdf_v) == 0
assert len(so_txt) == 277 + 147 == 424
assert len(serv) + len(vend) == len(pares) + len(so_pdf) == 10456
assert len(a100) + len(c100) == len(pares) + len(so_txt) == 10692
soma_dif_div = sum(r["dif"] for r in div_pdf) + sum(r["dif"] for r in div_txt)
assert soma_dif_div == Decimal("3787.22") + Decimal("266516.09"), soma_dif_div
assert sum(r["pdf"] for r in so_pdf) == Decimal("12727088.05")
assert sum(r["txt"] for r in so_txt) == Decimal("13627974.25") + Decimal("3802140.59")

TOTAL_LINHAS = len(pares) + len(so_pdf) + len(so_txt)
hoje = date.today().strftime("%d/%m/%Y")

# ================================================================ layout
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
    canvas.drawString(15 * mm, h - 10 * mm, "REAL PREV | Relatório Detalhado de Notas e Divergências")
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(w - 15 * mm, h - 10 * mm, f"2022 | Pág. {doc.page}")
    canvas.setFillColor(ORANGE)
    canvas.rect(0, h - 16.8 * mm, w, 0.8 * mm, stroke=0, fill=1)
    canvas.setFillColor(GREY)
    canvas.setFont("Helvetica", 7)
    canvas.drawString(15 * mm, 8 * mm, "Uso restrito - documento técnico-operacional. Não constitui certificação ISO, parecer legal, fiscal ou trabalhista.")
    canvas.drawRightString(w - 15 * mm, 8 * mm, hoje)
    canvas.restoreState()


HEADERS = ["Origem", "NF (PDF)", "Valor PDF (R$)", "NF (TXT)", "Valor TXT (R$)", "Diferença (R$)", "Status"]
CW = [22 * mm, 22 * mm, 30 * mm, 22 * mm, 30 * mm, 30 * mm, 24 * mm]

DATA_STYLE = TableStyle([
    ("GRID", (0, 0), (-1, -1), 0.4, BORDER),
    ("BACKGROUND", (0, 0), (-1, 0), NAVY),
    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
    ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 7.5),
    ("FONT", (0, 1), (-1, -1), "Helvetica", 7),
    ("ALIGN", (2, 1), (2, -1), "RIGHT"),
    ("ALIGN", (4, 1), (5, -1), "RIGHT"),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("LEFTPADDING", (0, 0), (-1, -1), 3),
    ("RIGHTPADDING", (0, 0), (-1, -1), 3),
    ("TOPPADDING", (0, 0), (-1, -1), 1),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 1),
])


def rows_table(regs, status, pdf_nf=True, txt_nf=True):
    """Tabela com altura de linha fixa (rápida para milhares de linhas)."""
    data = [HEADERS]
    for r in regs:
        data.append([
            r["origem"], r["nf"] if pdf_nf else "—", moeda(r["pdf"]),
            r["nf"] if txt_nf else "—", moeda(r["txt"]), moeda(r["dif"]), status,
        ])
    t = Table(data, colWidths=CW, rowHeights=[13] + [11] * len(regs), repeatRows=1)
    t.setStyle(DATA_STYLE)
    return t


def section_totals(regs, label):
    tp, tt = sum(r["pdf"] for r in regs), sum(r["txt"] for r in regs)
    td = sum(r["dif"] for r in regs)
    t = Table([[f"Total da seção — {label}", f"{num(len(regs))} notas",
                f"PDF: {brl(tp)}", f"TXT: {brl(tt)}", f"Diferença: {brl(td)}"]],
              colWidths=[52 * mm, 26 * mm, 34 * mm, 34 * mm, 34 * mm])
    t.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.4, BORDER),
        ("BACKGROUND", (0, 0), (-1, -1), LIGHT),
        ("FONT", (0, 0), (-1, -1), "Helvetica-Bold", 7.5),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    return t


story = []
story.append(P("REAL PREV", "title"))
story.append(P("Relatório Detalhado de Notas e Divergências - 2022", "subtitle"))
story.append(P("Listagem integral do cruzamento PDF (contabilidade) × TXT (EFD Contribuições)", "version"))

ident = Table([
    [P("<b>Empresa auditada</b>", "cell"), P("Soluções Serviços Terceirizados Ltda.", "cell"),
     P("<b>CNPJ</b>", "cell"), P("09.445.502/0001-09", "cell")],
    [P("<b>Período auditado</b>", "cell"), P("Janeiro/2022 a Dezembro/2022", "cell"),
     P("<b>Data de emissão</b>", "cell"), P(hoje, "cell")],
    [P("<b>Objeto</b>", "cell"), P("Todas as notas das bases PDF e TXT, nota a nota", "cell"),
     P("<b>Versão / Uso</b>", "cell"), P("1.0 / Restrito", "cell")],
], colWidths=[32 * mm, 66 * mm, 30 * mm, 52 * mm])
ident.setStyle(TableStyle([
    ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
    ("BACKGROUND", (0, 0), (0, -1), LIGHT),
    ("BACKGROUND", (2, 0), (2, -1), LIGHT),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("TOPPADDING", (0, 0), (-1, -1), 4),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
]))
story.append(ident)

story.append(P("Como ler este relatório", "h"))
story.append(P(
    "Este documento lista, sem exceção, todas as notas das duas bases do cruzamento: <b>PDF</b> = lançamentos "
    "das contas contábeis de receita (Serviços e Vendas) e <b>TXT</b> = registros A100/C100 da EFD "
    "Contribuições. Cada linha traz o número da nota e o valor em cada base, a diferença e o status. O "
    "relatório está dividido em cinco seções, nesta ordem: (1) notas OK — valores idênticos nas duas bases, "
    "organizadas por período; (2) divergências em que o valor do PDF é maior que o do TXT; (3) divergências em "
    "que o valor do TXT é maior que o do PDF; (4) notas que existem no PDF e não existem no TXT (valor TXT "
    "zerado); (5) notas que existem no TXT e não existem no PDF (valor PDF zerado). Tolerância de R$ 0,05 para "
    "status OK. Valor PDF zerado em nota cruzada indica nota de devolução (crédito desconsiderado)."))

resumo = Table([
    [P("<b>Seção</b>", "head"), P("<b>Conteúdo</b>", "head"), P("<b>Notas</b>", "head")],
    [P("1", "cell"), P("Notas OK (PDF = TXT), por período", "cell"), P(num(len(oks)), "cell")],
    [P("2", "cell"), P("Divergentes — PDF maior que TXT", "cell"), P(num(len(div_pdf)), "cell")],
    [P("3", "cell"), P("Divergentes — TXT maior que PDF", "cell"), P(num(len(div_txt)), "cell")],
    [P("4", "cell"), P("Existem no PDF e não no TXT", "cell"), P(num(len(so_pdf)), "cell")],
    [P("5", "cell"), P("Existem no TXT e não no PDF", "cell"), P(num(len(so_txt)), "cell")],
    [P("<b>Total de linhas</b>", "cellb"), P("<b>10.456 notas no PDF + 10.692 no TXT (10.268 cruzadas)</b>", "cellb"),
     P(f"<b>{num(TOTAL_LINHAS)}</b>", "cellb")],
], colWidths=[15 * mm, 130 * mm, 35 * mm])
resumo.setStyle(TableStyle([
    ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
    ("BACKGROUND", (0, 0), (-1, 0), NAVY),
    ("BACKGROUND", (0, -1), (-1, -1), LIGHT),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("TOPPADDING", (0, 0), (-1, -1), 3),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
]))
story.append(resumo)

# ---------------------------------------------------------------- Seção 1: OK por período
story.append(P("Seção 1 — Notas OK (PDF = TXT), por período", "h"))
story.append(P(
    f"As {num(len(oks))} notas abaixo cruzaram com valor idêntico nas duas bases (diferença ≤ R$ 0,05). Estão "
    f"organizadas por mês de emissão; dentro de cada mês, por número de nota."))
for mk in MKEYS:
    regs = [r for r in oks if (r["data"] or "")[:7] == mk]
    if not regs:
        continue
    story.append(P(f"{MNOME[mk]}/2022 — {num(len(regs))} notas OK", "h2"))
    story.append(rows_table(regs, "OK"))
story.append(Spacer(1, 4))
story.append(section_totals(oks, "Notas OK"))

# ---------------------------------------------------------------- Seção 2: PDF > TXT
story.append(P("Seção 2 — Divergências: valor do PDF maior que o do TXT", "h"))
story.append(P(
    f"Nova tabela, independente da anterior: as {num(len(div_pdf))} notas abaixo existem nas duas bases, mas o "
    f"valor lançado na contabilidade (PDF) é maior que o escriturado na EFD (TXT). A coluna Diferença mostra o "
    f"excesso do PDF sobre o TXT (sempre positiva nesta seção)."))
story.append(rows_table(div_pdf, "Divergente"))
story.append(Spacer(1, 4))
story.append(section_totals(div_pdf, "PDF maior que TXT"))

# ---------------------------------------------------------------- Seção 3: TXT > PDF
story.append(P("Seção 3 — Divergências: valor do TXT maior que o do PDF", "h"))
story.append(P(
    f"Situação inversa da Seção 2: nas {num(len(div_txt))} notas abaixo, o valor escriturado na EFD (TXT) é "
    f"maior que o lançado na contabilidade (PDF). A coluna Diferença é negativa (PDF − TXT). Valor PDF 0,00 "
    f"indica nota de devolução com crédito desconsiderado."))
story.append(rows_table(div_txt, "Divergente"))
story.append(Spacer(1, 4))
story.append(section_totals(div_txt, "TXT maior que PDF"))

# ---------------------------------------------------------------- Seção 4: só no PDF
story.append(P("Seção 4 — Notas que existem no PDF e não existem no TXT", "h"))
story.append(P(
    f"As {num(len(so_pdf))} notas abaixo possuem lançamento na contabilidade (PDF), mas nenhum registro "
    f"correspondente foi localizado na EFD (TXT). As colunas do TXT vêm zeradas; o status é Sem match. Todas "
    f"pertencem à conta de Serviços — 100% da conta de Vendas foi localizada na EFD."))
story.append(rows_table(so_pdf, "Sem match", txt_nf=False))
story.append(Spacer(1, 4))
story.append(section_totals(so_pdf, "Só no PDF"))

# ---------------------------------------------------------------- Seção 5: só no TXT
story.append(P("Seção 5 — Notas que existem no TXT e não existem no PDF", "h"))
story.append(P(
    f"As {num(len(so_txt))} notas abaixo estão escrituradas na EFD (TXT), mas nenhum lançamento correspondente "
    f"foi localizado na contabilidade (PDF). As colunas do PDF vêm zeradas; o status é Sem match "
    f"({num(len(so_txt_s))} de Serviços e {num(len(so_txt_v))} de Vendas)."))
story.append(rows_table(so_txt, "Sem match", pdf_nf=False))
story.append(Spacer(1, 4))
story.append(section_totals(so_txt, "Só no TXT"))

# ---------------------------------------------------------------- Fechamento
story.append(P("Fechamento e conferência", "h"))
fech = Table([
    [P("<b>Conferência</b>", "head"), P("<b>Contas</b>", "head"), P("<b>Resultado</b>", "head")],
    [P("Notas no PDF (contabilidade)", "cell"), P(f"{num(len(pares))} cruzadas + {num(len(so_pdf))} só no PDF", "cell"), P(f"{num(len(serv) + len(vend))}", "cellb")],
    [P("Notas no TXT (EFD)", "cell"), P(f"{num(len(pares))} cruzadas + {num(len(so_txt))} só no TXT", "cell"), P(f"{num(len(a100) + len(c100))}", "cellb")],
    [P("Linhas listadas neste relatório", "cell"), P(f"{num(len(oks))} OK + {num(len(div_pdf) + len(div_txt))} divergentes + {num(len(so_pdf) + len(so_txt))} sem match", "cell"), P(f"{num(TOTAL_LINHAS)}", "cellb")],
], colWidths=[55 * mm, 90 * mm, 35 * mm])
fech.setStyle(TableStyle([
    ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
    ("BACKGROUND", (0, 0), (-1, 0), NAVY),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("TOPPADDING", (0, 0), (-1, -1), 3),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
]))
story.append(fech)
story.append(P(
    "Nenhuma nota das duas bases ficou fora desta listagem. Os totais das seções conciliam com os cards do "
    "sistema: as notas sem match e as divergências compõem a Diferença ECF de R$ 4.031.828,87 detalhada no "
    "relatório específico. Este relatório é uma avaliação técnico-documental; não constitui certificação ISO, "
    "parecer legal, fiscal ou trabalhista."))

doc = BaseDocTemplate(OUT, pagesize=A4, leftMargin=15 * mm, rightMargin=15 * mm,
                      topMargin=22 * mm, bottomMargin=15 * mm)
doc.addPageTemplates([PageTemplate(id="all", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="f")], onPage=header_footer)])
doc.build(story)
print("OK:", OUT)
print(f"Linhas: {num(TOTAL_LINHAS)} | OK: {num(len(oks))} | PDF>TXT: {len(div_pdf)} | TXT>PDF: {len(div_txt)} | so PDF: {len(so_pdf)} | so TXT: {len(so_txt)}")
