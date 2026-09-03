#!/usr/bin/env python3
"""Gera 1 PDF MEGA-detalhado por cliente deficitario: como chegamos na folha e no faturamento."""
import json, os, re, unicodedata
from datetime import date
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
                                Table, TableStyle, HRFlowable, KeepTogether)

INK = colors.HexColor("#173a3b"); INK2 = colors.HexColor("#0c292a")
CORAL = colors.HexColor("#d66e54"); MINT = colors.HexColor("#9bc8b5")
PAPER = colors.HexColor("#f5f2e9"); LINE = colors.HexColor("#d8d5c9")
GREEN = colors.HexColor("#2e7d54"); RED = colors.HexColor("#c0492f"); AMBER = colors.HexColor("#c07a00")
DATA = r"storage\private\fiscal_auditor\appa\detalhe_clientes_deficit.json"
OUTDIR = r"C:\Users\xandao\Downloads"
MESES = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto",
         "Setembro", "Outubro", "Novembro", "Dezembro"]

def brl(v):
    if v is None:
        return "—"
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().upper()
    s = re.sub(r"[^A-Z0-9]+", "_", s).strip("_")
    return s[:48]

def hf(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(INK); canvas.rect(0, h - 16 * mm, w, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(0, h - 16 * mm, 2.6 * mm, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(18 * mm, h - 12.9 * mm, 6.6 * mm, 6.6 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white); canvas.setFont("Helvetica-Bold", 6.6)
    canvas.drawCentredString(18 * mm + 3.3 * mm, h - 11.0 * mm, "RAT")
    canvas.setFont("Helvetica-Bold", 10)
    canvas.drawString(27.5 * mm, h - 9.8 * mm, "REAL AUDIT TECH")
    canvas.setFont("Helvetica", 5.8); canvas.setFillColor(MINT)
    canvas.drawString(27.7 * mm, h - 13.2 * mm, "TECNOLOGIA TRIBUTÁRIA")
    canvas.setFont("Helvetica", 8); canvas.setFillColor(MINT)
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Detalhe do contrato · APPA 2025 · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento técnico. Memória de cálculo do faturamento e da folha por contrato.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

S = getSampleStyleSheet()
h1 = ParagraphStyle("h1", parent=S["Title"], textColor=INK, fontSize=20, leading=23, alignment=0)
h1s = ParagraphStyle("h1s", parent=S["Title"], textColor=CORAL, fontSize=12, leading=14, alignment=0)
kick = ParagraphStyle("kick", parent=S["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
body = ParagraphStyle("body", parent=S["Normal"], textColor=INK2, fontSize=8.6, leading=13)
sec = ParagraphStyle("sec", parent=S["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)
cell = ParagraphStyle("cell", parent=body, fontSize=7.2, leading=8.6)

def tbl(data, cw, right_from=1, header=True, total=True):
    t = Table(data, colWidths=cw, repeatRows=1 if header else 0)
    st = [
        ("FONTSIZE", (0, 0), (-1, -1), 7.2),
        ("ALIGN", (right_from, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 2.6), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.6),
        ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2 if total else -1), [colors.white, PAPER]),
    ]
    if header:
        st += [("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
               ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold")]
    if total:
        st += [("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
               ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold")]
    t.setStyle(TableStyle(st))
    return t

def build(cc, d, enc):
    fat = sum(d["fat_mes"][mm]["bruto"] for mm in d["fat_mes"])
    ret = sum(d["fat_mes"][mm]["ret"] for mm in d["fat_mes"])
    venc = sum(d["folha_mes_venc"]); desc = sum(d["folha_mes_desc"])
    custo = venc * (1 + enc)
    marg = (fat - custo) / fat * 100 if fat else 0
    sit = "Prejuízo" if marg < 0 else ("Margem magra" if marg < 5 else "Lucrativo")
    sitcolor = RED if marg < 0 else (AMBER if marg < 5 else GREEN)
    nnotas = len(d["notas"])

    el = [Spacer(1, 4)]
    el.append(Paragraph("DETALHE DO CONTRATO · MEMÓRIA DE CÁLCULO", kick))
    el.append(Paragraph(d["cliente"], h1))
    el.append(Paragraph("APPA · Exercício 2025", h1s))
    el.append(HRFlowable(width="100%", thickness=1.5, color=CORAL, spaceBefore=6, spaceAfter=8))
    meta = [["Cliente (tomador)", d["cliente"], "Cód.", cc],
            ["CNPJ", d["cnpj"] or "—", "Competência", "Jan–Dez/2025"]]
    mt = Table(meta, colWidths=[26 * mm, 96 * mm, 22 * mm, 30 * mm])
    mt.setStyle(TableStyle([("FONTSIZE", (0, 0), (-1, -1), 8.2), ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#faf8f1")),
        ("BOX", (0, 0), (-1, -1), 0.7, LINE), ("TEXTCOLOR", (0, 0), (0, -1), CORAL), ("TEXTCOLOR", (2, 0), (2, -1), CORAL),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"), ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
        ("FONTNAME", (1, 0), (1, -1), "Helvetica-Bold"), ("FONTNAME", (3, 0), (3, -1), "Helvetica-Bold"),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4), ("LEFTPADDING", (0, 0), (-1, -1), 7)]))
    el.append(mt)
    el.append(Spacer(1, 8))

    el.append(Paragraph("Resumo do contrato", sec))
    res = [["Indicador", "Valor", "Como é obtido"],
           ["Faturamento (competência 2025)", brl(fat), f"{nnotas} nota(s) fiscal(is) do cliente"],
           ["Folha bruta (vencimentos)", brl(venc), "soma das rubricas de vencimento"],
           ["(−) Descontos", brl(desc), "rubricas de desconto"],
           ["Custo de mão de obra", brl(custo), f"folha + encargos ({enc*100:.1f}%)"],
           ["Margem", f"{marg:.0f}%", "(faturamento − custo) ÷ faturamento"],
           ["Situação", sit, "classificação"]]
    rt = Table(res, colWidths=[54 * mm, 34 * mm, 86 * mm])
    rt.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("ALIGN", (1, 0), (1, -1), "RIGHT"), ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PAPER]),
        ("BOX", (0, 0), (-1, -1), 0.6, LINE), ("INNERGRID", (0, 0), (-1, -1), 0.3, LINE),
        ("TEXTCOLOR", (1, 5), (1, 6), sitcolor), ("FONTNAME", (1, 5), (1, 6), "Helvetica-Bold"),
        ("TOPPADDING", (0, 0), (-1, -1), 3.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 3.5), ("LEFTPADDING", (0, 0), (-1, -1), 5)]))
    el.append(rt)
    el.append(Spacer(1, 4))
    if nnotas <= 4 and fat > 0:
        el.append(Paragraph(f"<b>Atenção:</b> este contrato tem apenas <b>{nnotas} nota(s)</b> com competência em 2025, "
                            f"frente a uma folha de 12 meses. Isso indica que o faturamento por competência do cliente está "
                            "<b>incompleto</b> (notas em outros exercícios/ainda a emitir) ou <b>atribuído a outro código</b> — "
                            "ou seja, o resultado negativo tende a ser <b>distorção de atribuição</b>, não prejuízo efetivo. "
                            "Recomenda-se conciliar o CNPJ do tomador na folha × no faturamento.", body))
    el.append(Spacer(1, 8))

    # Faturamento
    el.append(Paragraph("1. Faturamento — como chegamos", sec))
    fm = [["Competência", "Notas", "Valor bruto", "Retenções", "Líquido"]]
    for i, mkey in enumerate([f"{k:02d}" for k in range(1, 13)]):
        x = d["fat_mes"][mkey]
        if x["n"] == 0:
            continue
        fm.append([MESES[i] + "/2025", str(x["n"]), brl(x["bruto"]), brl(x["ret"]), brl(x["bruto"] - x["ret"])])
    fm.append(["TOTAL", str(nnotas), brl(fat), brl(ret), brl(fat - ret)])
    el.append(tbl(fm, [40 * mm, 18 * mm, 40 * mm, 38 * mm, 38 * mm]))
    el.append(Spacer(1, 5))
    if d["notas"]:
        el.append(Paragraph("Notas fiscais (competência 2025):", body))
        nn = [["Competência", "Nº NF-e", "Emissão", "Valor bruto", "Retenções"]]
        for n in d["notas"][:60]:
            nn.append([f"{n['comp']}/2025", n["nf"] or "—", n["emissao"] or "—", brl(n["bruto"]), brl(n["ret"])])
        if len(d["notas"]) > 60:
            nn.append(["…", f"+{len(d['notas'])-60} notas", "", "", ""])
        el.append(tbl(nn, [30 * mm, 34 * mm, 30 * mm, 36 * mm, 34 * mm], total=False))
    el.append(Spacer(1, 8))

    # Folha
    el.append(Paragraph("2. Folha — como chegamos", sec))
    fmes = [["Mês", "Vencimentos", "Descontos", "Líquido"]]
    for i in range(12):
        v = d["folha_mes_venc"][i]; ds = d["folha_mes_desc"][i]
        if v == 0 and ds == 0:
            continue
        fmes.append([MESES[i], brl(v), brl(ds), brl(v - ds)])
    fmes.append(["TOTAL", brl(venc), brl(desc), brl(venc - desc)])
    el.append(tbl(fmes, [40 * mm, 42 * mm, 42 * mm, 42 * mm]))
    el.append(Spacer(1, 5))
    vrub = [r for r in d["folha_rubricas"] if r["tipo"] == "Vencimento" and r["total"] != 0]
    el.append(Paragraph(f"Composição da folha bruta por rubrica ({len(vrub)} rubricas de vencimento):", body))
    rr = [["Código", "Rubrica (vencimento)", "Total no ano"]]
    for r in vrub:
        rr.append([r["codigo"], Paragraph(r["desc"], cell), brl(r["total"])])
    rr.append(["", Paragraph("<b>TOTAL VENCIMENTOS</b>", cell), brl(venc)])
    el.append(tbl(rr, [20 * mm, 116 * mm, 30 * mm], right_from=2))
    drub = [r for r in d["folha_rubricas"] if r["tipo"] == "Desconto" and r["total"] != 0]
    if drub:
        el.append(Spacer(1, 5))
        el.append(Paragraph(f"Descontos por rubrica ({len(drub)} rubricas):", body))
        dr = [["Código", "Rubrica (desconto)", "Total no ano"]]
        for r in drub:
            dr.append([r["codigo"], Paragraph(r["desc"], cell), brl(r["total"])])
        dr.append(["", Paragraph("<b>TOTAL DESCONTOS</b>", cell), brl(desc)])
        el.append(tbl(dr, [20 * mm, 116 * mm, 30 * mm], right_from=2))
    return el

def main():
    data = json.load(open(DATA, encoding="utf-8"))
    for cc, d in data.items():
        enc = d.get("encargo", 0.238)
        doc = BaseDocTemplate(os.path.join(OUTDIR, f"APPA_DETALHE_{slug(d['cliente'])}_{cc}_2025.pdf"),
                              pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=22 * mm, bottomMargin=16 * mm)
        doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=hf)])
        doc.build(build(cc, d, enc))
        print("OK ->", os.path.basename(doc.filename))

if __name__ == "__main__":
    main()
