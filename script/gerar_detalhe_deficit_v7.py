#!/usr/bin/env python3
"""1 PDF por cliente deficitario (>100% no modelo v7): memoria de calculo completa —
faturamento nota a nota, folha, beneficios, uniformes/limpeza e como chegamos no %.
"""
import json, os, re, unicodedata
from datetime import date
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
                                Table, TableStyle, HRFlowable)

INK = colors.HexColor("#173a3b"); INK2 = colors.HexColor("#0c292a")
CORAL = colors.HexColor("#d66e54"); MINT = colors.HexColor("#9bc8b5")
PAPER = colors.HexColor("#f5f2e9"); LINE = colors.HexColor("#d8d5c9")
GREEN = colors.HexColor("#2e7d54"); RED = colors.HexColor("#c0492f"); AMBER = colors.HexColor("#c07a00")
DATA = r"storage\private\fiscal_auditor\appa\detalhe_deficit_v7.json"
OUTDIR = r"storage\private\fiscal_auditor\appa\DEFICIT_5_CLIENTES"
MESES = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto",
         "Setembro", "Outubro", "Novembro", "Dezembro"]

def brl(v):
    if v is None:
        return "—"
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().upper()
    return re.sub(r"[^A-Z0-9]+", "_", s).strip("_")[:44]

def hf(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(INK); canvas.rect(0, h - 16 * mm, w, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(0, h - 16 * mm, 2.6 * mm, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(18 * mm, h - 12.9 * mm, 6.6 * mm, 6.6 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white); canvas.setFont("Helvetica-Bold", 6.6)
    canvas.drawCentredString(18 * mm + 3.3 * mm, h - 11.0 * mm, "RAT")
    canvas.setFont("Helvetica-Bold", 10); canvas.drawString(27.5 * mm, h - 9.8 * mm, "REAL AUDIT TECH")
    canvas.setFont("Helvetica", 5.8); canvas.setFillColor(MINT); canvas.drawString(27.7 * mm, h - 13.2 * mm, "TECNOLOGIA TRIBUTÁRIA")
    canvas.setFont("Helvetica", 8); canvas.setFillColor(MINT)
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Detalhe do contrato · APPA 2025 · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · memória de cálculo do resultado por contrato (modelo v7).")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

S = getSampleStyleSheet()
h1 = ParagraphStyle("h1", parent=S["Title"], textColor=INK, fontSize=19, leading=22, alignment=0)
h1s = ParagraphStyle("h1s", parent=S["Title"], textColor=CORAL, fontSize=12, leading=14, alignment=0)
kick = ParagraphStyle("kick", parent=S["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
body = ParagraphStyle("body", parent=S["Normal"], textColor=INK2, fontSize=8.6, leading=13)
sec = ParagraphStyle("sec", parent=S["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)
cell = ParagraphStyle("cell", parent=body, fontSize=7.2, leading=8.6)

def tbl(data, cw, right_from=1, header=True, total=True, fs=7.2):
    t = Table(data, colWidths=cw, repeatRows=1 if header else 0)
    st = [("FONTSIZE", (0, 0), (-1, -1), fs), ("ALIGN", (right_from, 0), (-1, -1), "RIGHT"),
          ("ALIGN", (0, 0), (0, -1), "LEFT"), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
          ("TOPPADDING", (0, 0), (-1, -1), 2.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5),
          ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
          ("ROWBACKGROUNDS", (0, 1), (-1, -2 if total else -1), [colors.white, PAPER])]
    if header:
        st += [("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
               ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold")]
    if total:
        st += [("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
               ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold")]
    t.setStyle(TableStyle(st))
    return t

def build(cc, d):
    fat = d["faturamento"]; fol = d["folha_sem_beneficio"]; ben = d["beneficio_liquido"]
    encv = d["encargo_valor"]; uni = d["uniformes_total"]; res = d["resultado"]; marg = d["margem"]
    venc = sum(d["folha_mes_venc"]); desc = sum(d["folha_mes_desc"])
    nnotas = len(d["notas"])
    sitcolor = RED if marg < 0 else (AMBER if marg < 5 else GREEN)

    el = [Spacer(1, 4)]
    el.append(Paragraph("DETALHE DO CONTRATO · MEMÓRIA DE CÁLCULO (modelo v7)", kick))
    el.append(Paragraph(d["cliente"], h1))
    el.append(Paragraph("APPA · Exercício 2025", h1s))
    el.append(HRFlowable(width="100%", thickness=1.5, color=CORAL, spaceBefore=6, spaceAfter=8))
    meta = [["Cliente (tomador)", d["cliente"], "Cód.", cc],
            ["CNPJ", d["cnpj"] or "—", "Competência", "Jan–Dez/2025"]]
    mt = Table(meta, colWidths=[26 * mm, 96 * mm, 20 * mm, 32 * mm])
    mt.setStyle(TableStyle([("FONTSIZE", (0, 0), (-1, -1), 8.2), ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#faf8f1")),
        ("BOX", (0, 0), (-1, -1), 0.7, LINE), ("TEXTCOLOR", (0, 0), (0, -1), CORAL), ("TEXTCOLOR", (2, 0), (2, -1), CORAL),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"), ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
        ("FONTNAME", (1, 0), (1, -1), "Helvetica-Bold"), ("FONTNAME", (3, 0), (3, -1), "Helvetica-Bold"),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4), ("LEFTPADDING", (0, 0), (-1, -1), 7)]))
    el.append(mt); el.append(Spacer(1, 8))

    # Resumo v7 — a equacao
    el.append(Paragraph("Resultado do contrato — a conta", sec))
    eq = [["Componente", "Valor", "Como é obtido"],
          ["Faturamento (competência 2025)", brl(fat), f"{nnotas} nota(s) fiscal(is) do cliente"],
          ["(−) Folha (sem benefícios)", brl(fol), "vencimentos − benefícios"],
          ["(−) Encargos", brl(encv), f"INSS + FGTS = {d['encargo']*100:.1f}% da folha"],
          ["(−) Benefícios (líquido)", brl(ben), "VT/refeição/saúde (empresa − empregado)"],
          ["(−) Mat./Uniformes", brl(uni), f"direto {brl(d['uniformes_direto'])} + rateio {brl(d['uniformes_rateio'])}"],
          ["= Resultado", brl(res), "faturamento − custos"],
          ["Margem", f"{marg:.0f}%", "resultado ÷ faturamento"]]
    et = Table(eq, colWidths=[52 * mm, 34 * mm, 88 * mm])
    et.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("ALIGN", (1, 0), (1, -1), "RIGHT"), ("ROWBACKGROUNDS", (0, 1), (-1, -3), [colors.white, PAPER]),
        ("BOX", (0, 0), (-1, -1), 0.6, LINE), ("INNERGRID", (0, 0), (-1, -1), 0.3, LINE),
        ("LINEABOVE", (0, 6), (-1, 6), 0.7, INK), ("BACKGROUND", (0, 6), (-1, 6), colors.HexColor("#eef3ef")),
        ("FONTNAME", (0, 6), (-1, 6), "Helvetica-Bold"),
        ("TEXTCOLOR", (1, 6), (1, 7), sitcolor), ("FONTNAME", (1, 7), (1, 7), "Helvetica-Bold"),
        ("TOPPADDING", (0, 0), (-1, -1), 3.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 3.5), ("LEFTPADDING", (0, 0), (-1, -1), 5)]))
    el.append(et); el.append(Spacer(1, 6))

    # Diagnostico
    causa = []
    if nnotas <= 4:
        causa.append(f"o faturamento tem apenas <b>{nnotas} nota(s)</b> de competência 2025 frente a uma folha de vários meses "
                     "— indica <b>faturamento incompleto</b> (notas em outro exercício/ainda a emitir) ou <b>atribuído a outro código</b>")
    if uni > fat * 0.5:
        causa.append(f"a despesa de <b>uniformes/material (R$ {brl(uni)})</b> é muito alta frente ao faturamento — "
                     "conferir se essas compras são realmente deste contrato")
    if venc > fat:
        causa.append("a <b>folha anual</b> supera o faturamento do contrato (pode carregar rescisão/meses sem nota correspondente)")
    diag = "<b>Por que fica deficitário:</b> " + ("; ".join(causa) if causa else
           "custos (folha + encargos + benefícios + materiais) superam o faturamento apurado") + \
           ". O resultado negativo tende a ser <b>distorção de atribuição/competência</b>, não prejuízo efetivo — recomenda-se conciliar o CNPJ do tomador na folha × no faturamento × nas despesas."
    el.append(Paragraph(diag, body)); el.append(Spacer(1, 8))

    # 1. Faturamento
    el.append(Paragraph("1. Faturamento — nota a nota", sec))
    fm = [["Competência", "Notas", "Valor bruto", "Retenções", "Líquido"]]
    for i, mname in enumerate(MESES):
        x = d["fat_mes"][f"{i+1:02d}"]
        if x["n"] == 0:
            continue
        fm.append([mname + "/2025", str(x["n"]), brl(x["bruto"]), brl(x["ret"]), brl(x["bruto"] - x["ret"])])
    fret = sum(d["fat_mes"][f"{i+1:02d}"]["ret"] for i in range(12))
    fm.append(["TOTAL", str(nnotas), brl(fat), brl(fret), brl(fat - fret)])
    el.append(tbl(fm, [38 * mm, 18 * mm, 40 * mm, 38 * mm, 40 * mm]))
    if d["notas"]:
        el.append(Spacer(1, 5))
        el.append(Paragraph("Notas fiscais (competência 2025):", body))
        nn = [["Comp.", "Nº NF-e", "Emissão", "Valor bruto", "Retenções", "Fonte"]]
        for n in d["notas"][:70]:
            nn.append([f"{n['comp']}/25", n["nf"] or "—", n["emissao"] or "—", brl(n["bruto"]), brl(n["ret"]),
                       Paragraph(n.get("fonte", ""), cell)])
        el.append(tbl(nn, [16 * mm, 30 * mm, 22 * mm, 32 * mm, 28 * mm, 46 * mm], right_from=3, total=False))
    el.append(Spacer(1, 8))

    # 2. Folha
    el.append(Paragraph("2. Folha — mês a mês e por rubrica", sec))
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
    el.append(Paragraph(f"Rubricas de vencimento ({len(vrub)}) — <b>B</b> = benefício (sai da folha e entra na linha Benefícios):", body))
    rr = [["Código", "Rubrica", "B", "Total ano"]]
    for r in vrub:
        rr.append([r["codigo"], Paragraph(r["desc"], cell), "B" if r["benef"] else "", brl(r["total"])])
    rr.append(["", Paragraph("<b>TOTAL VENCIMENTOS (folha bruta)</b>", cell), "", brl(venc)])
    el.append(tbl(rr, [18 * mm, 116 * mm, 8 * mm, 30 * mm], right_from=3))
    drub = [r for r in d["folha_rubricas"] if r["tipo"] == "Desconto" and r["total"] != 0]
    if drub:
        el.append(Spacer(1, 5))
        el.append(Paragraph(f"Descontos ({len(drub)}):", body))
        dr = [["Código", "Rubrica (desconto)", "B", "Total ano"]]
        for r in drub:
            dr.append([r["codigo"], Paragraph(r["desc"], cell), "B" if r["benef"] else "", brl(r["total"])])
        dr.append(["", Paragraph("<b>TOTAL DESCONTOS</b>", cell), "", brl(desc)])
        el.append(tbl(dr, [18 * mm, 116 * mm, 8 * mm, 30 * mm], right_from=3))
    el.append(Spacer(1, 8))

    # 3. Beneficios
    el.append(Paragraph("3. Benefícios — como saem da folha", sec))
    bb = [["Componente", "Valor", "Como é obtido"],
          ["Benefícios (parte da empresa)", brl(d["beneficio_add"]), "rubricas de benefício no vencimento"],
          ["(−) Benefícios (descontado do empregado)", brl(d["beneficio_sub"]), "rubricas de benefício no desconto"],
          ["= Benefícios (líquido)", brl(ben), "custo líquido dos benefícios"]]
    el.append(tbl(bb, [76 * mm, 34 * mm, 64 * mm], right_from=1))
    el.append(Spacer(1, 8))

    # 4. Uniformes
    el.append(Paragraph("4. Uniformes e material de limpeza", sec))
    uu = [["Componente", "Valor", "Como é obtido"],
          ["Despesa direta do cliente", brl(d["uniformes_direto"]), "notas com o código do cliente"],
          ["(+) Rateio do 'sem empresa'", brl(d["uniformes_rateio"]), "parcela interna/matriz proporcional ao faturamento"],
          ["= Mat./Uniformes", brl(uni), "total alocado ao contrato"]]
    el.append(tbl(uu, [76 * mm, 34 * mm, 64 * mm], right_from=1))
    if d["uniformes_notas"]:
        el.append(Spacer(1, 5))
        el.append(Paragraph("Notas de despesa (uniformes/limpeza) com o código do cliente:", body))
        un = [["Categoria", "Fornecedor", "Descrição (col. G)", "Valor"]]
        for n in d["uniformes_notas"][:40]:
            un.append([n["cat"], Paragraph(n["fornecedor"], cell), Paragraph(n["desc"], cell), brl(n["valor"])])
        un.append(["", "", Paragraph("<b>TOTAL DIRETO</b>", cell), brl(d["uniformes_direto"])])
        el.append(tbl(un, [20 * mm, 52 * mm, 66 * mm, 28 * mm], right_from=3))
    return el

def main():
    data = json.load(open(DATA, encoding="utf-8"))
    os.makedirs(OUTDIR, exist_ok=True)
    for cc, d in data.items():
        out = os.path.join(OUTDIR, f"APPA_DETALHE_DEFICIT_{slug(d['cliente'])}_{cc}_2025.pdf")
        doc = BaseDocTemplate(out, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=22 * mm, bottomMargin=16 * mm)
        doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=hf)])
        doc.build(build(cc, d))
        print("OK ->", os.path.basename(out))

if __name__ == "__main__":
    main()
