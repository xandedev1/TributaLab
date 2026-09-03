#!/usr/bin/env python3
"""Cruzamento APPA 2025 — Faturamento x Custo de Mao de Obra (PDF, Real Audit Tech).

Le storage/private/fiscal_auditor/appa/cruzamento_resultado.json e produz o relatorio
mensal: Faturamento (emitido) menos Folha, INSS e FGTS = resultado/margem.
"""
import argparse, json
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
GREEN = colors.HexColor("#2e7d54"); RED = colors.HexColor("#c0492f")

MESES = {"01": "Janeiro", "02": "Fevereiro", "03": "Março", "04": "Abril", "05": "Maio",
         "06": "Junho", "07": "Julho", "08": "Agosto", "09": "Setembro", "10": "Outubro",
         "11": "Novembro", "12": "Dezembro"}

def brl(v):
    if v is None:
        return "—"
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def clabel(c):
    return f"{MESES[c.split('-')[1]]}/{c.split('-')[0]}"

def header_footer(canvas, doc):
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
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Cruzamento · APPA 2025 · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento gerencial. Faturamento × custo de mão de obra a partir de faturamento, folha e encargos da APPA.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--escopo", default="")
    ap.add_argument("--nota", default="")
    ap.add_argument("--base", default="faturamento", choices=["faturamento", "emissao"])
    args = ap.parse_args()
    rows = json.load(open(args.data, encoding="utf-8"))["rows"]
    B = args.base  # prefixo dos campos de faturamento (faturamento=competencia)

    styles = getSampleStyleSheet()
    h1 = ParagraphStyle("h1", parent=styles["Title"], textColor=INK, fontSize=25, leading=27, alignment=0)
    h1s = ParagraphStyle("h1s", parent=styles["Title"], textColor=CORAL, fontSize=13, leading=15, alignment=0)
    kick = ParagraphStyle("kick", parent=styles["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
    sub = ParagraphStyle("sub", parent=styles["Normal"], textColor=colors.HexColor("#36595a"), fontSize=10, leading=14)
    body = ParagraphStyle("body", parent=styles["Normal"], textColor=INK2, fontSize=8.4, leading=12.5)
    sec = ParagraphStyle("sec", parent=styles["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)

    doc = BaseDocTemplate(args.out, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm,
                          topMargin=22 * mm, bottomMargin=16 * mm)
    doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)],
                                       onPage=header_footer)])
    el = []
    el.append(Spacer(1, 6))
    el.append(Paragraph("RELATÓRIO GERENCIAL · CRUZAMENTO", kick))
    el.append(Paragraph("Faturamento × Custo de Mão de Obra", h1))
    el.append(Paragraph(f"APPA · Exercício 2025{(' · ' + args.escopo) if args.escopo else ''}", h1s))
    el.append(HRFlowable(width="100%", thickness=1.6, color=CORAL, spaceBefore=6, spaceAfter=9))
    el.append(Paragraph("Confronto mês a mês entre o faturamento (regime de competência) e o custo direto de mão de obra "
                        "(folha, INSS patronal e FGTS), com o resultado e a margem apurados.", sub))
    el.append(Spacer(1, 10))
    meta = [
        ["Empresa", "APPA Serviços Temporários e Efetivos Ltda.", "CNPJ", "05.969.071/0001-10"],
        ["Período", "Janeiro a Dezembro/2025", "Emissão", date.today().strftime("%d/%m/%Y")],
        ["Objeto", args.escopo or "Cruzamento faturamento × custo de M.O.", "Versão / Uso", "1.0 / Restrito"],
    ]
    mt = Table(meta, colWidths=[22 * mm, 84 * mm, 24 * mm, 44 * mm])
    mt.setStyle(TableStyle([
        ("FONTSIZE", (0, 0), (-1, -1), 8.2), ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#faf8f1")),
        ("BOX", (0, 0), (-1, -1), 0.7, LINE),
        ("TEXTCOLOR", (0, 0), (0, -1), CORAL), ("TEXTCOLOR", (2, 0), (2, -1), CORAL),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"), ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
        ("FONTNAME", (1, 0), (1, -1), "Helvetica-Bold"), ("FONTNAME", (3, 0), (3, -1), "Helvetica-Bold"),
        ("TEXTCOLOR", (1, 0), (1, -1), INK2), ("TEXTCOLOR", (3, 0), (3, -1), INK2),
        ("TOPPADDING", (0, 0), (-1, -1), 4.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 4.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 8), ("LINEBELOW", (0, 0), (-1, -2), 0.4, LINE),
    ]))
    el.append(mt)
    el.append(Spacer(1, 10))

    el.append(Paragraph("Critérios e fontes", sec))
    el.append(Paragraph(
        "<b>Faturamento</b>: valor bruto das notas fiscais reconhecido por <b>competência</b> "
        "(mês de referência do serviço, independentemente do mês de emissão ou de pagamento), a partir dos "
        "relatórios de retenção. "
        "<b>Folha</b>: total de vencimentos (folha bruta) apurado por competência. "
        "<b>INSS</b>: contribuição patronal (20% + RAT ajustado + terceiros) de responsabilidade do empregador. "
        "<b>FGTS</b>: depósito apurado por lotação. "
        "O <b>custo de mão de obra</b> soma folha, INSS e FGTS; o <b>resultado</b> é o faturamento menos esse custo.", body))
    el.append(Spacer(1, 4))
    el.append(Paragraph(
        "Notas: (i) dezembro concentra o 13º salário na folha, no INSS e no FGTS, sem faturamento correspondente, "
        "o que reduz o resultado do mês; (ii) o faturamento líquido de retenções (INSS/IRRF/ISS/PIS/COFINS/CSLL) "
        "é apresentado no quadro complementar — parte das retenções (INSS e IRRF) é recuperável, por isso a margem "
        "é medida sobre o faturamento bruto; (iii) as competências mais recentes podem ser provisórias, pois notas "
        "referentes a esses meses ainda podem ser emitidas; (iv) benefícios estão em levantamento e serão "
        "incorporados em versão posterior.", body))
    if args.nota:
        el.append(Spacer(1, 4))
        el.append(Paragraph(args.nota, body))
    el.append(Spacer(1, 10))

    el.append(Paragraph("Resultado mês a mês", sec))
    hdr = ["Competência", "Faturamento", "Folha", "INSS", "FGTS", "Custo M.O.", "Resultado", "Margem"]
    data = [hdr]
    tf = tfo = ti = tg = 0.0
    for r in rows:
        fat = r[f"{B}_bruto"]; folha = r["folha_vencimentos"]; inss = r["inss_empregador"]; fg = r["fgts"]
        custo = folha + inss + fg; res = fat - custo
        marg = res / fat * 100 if fat else 0
        tf += fat; tfo += folha; ti += inss; tg += fg
        data.append([clabel(r["competencia"]), brl(fat), brl(folha), brl(inss), brl(fg),
                     brl(custo), brl(res), f"{marg:+.1f}%"])
    tc = tfo + ti + tg; tr = tf - tc
    data.append(["TOTAL", brl(tf), brl(tfo), brl(ti), brl(tg), brl(tc), brl(tr),
                 f"{(tr/tf*100 if tf else 0):+.1f}%"])

    cw = [24 * mm, 25 * mm, 25 * mm, 22 * mm, 20 * mm, 25 * mm, 24 * mm, 15 * mm]
    t = Table(data, colWidths=cw, repeatRows=1)
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 6.9),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
        ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
    ]
    for i in range(1, len(data)):
        res_txt = data[i][6]
        neg = res_txt.startswith("-")
        style.append(("TEXTCOLOR", (6, i), (7, i), RED if neg else GREEN))
        style.append(("FONTNAME", (6, i), (6, i), "Helvetica-Bold"))
    t.setStyle(TableStyle(style))
    el.append(t)
    el.append(Spacer(1, 4))
    el.append(Paragraph(
        f"No acumulado do exercício, o faturamento de <b>R$ {brl(tf)}</b> cobre o custo de mão de obra de "
        f"<b>R$ {brl(tc)}</b>, resultando em <b>R$ {brl(tr)}</b> ({(tr/tf*100 if tf else 0):+.1f}%) antes de "
        "tributos sobre a receita, despesas administrativas e benefícios.", body))
    el.append(Spacer(1, 12))

    el.append(Paragraph("Quadro complementar — faturamento e retenções", sec))
    hdr2 = ["Competência", "Faturamento bruto", "Retenções", "Faturamento líquido"]
    data2 = [hdr2]
    tb = trr = tl = 0.0
    for r in rows:
        b = r[f"{B}_bruto"]; ret = r[f"{B}_retencoes"]; liq = r[f"{B}_liquido"]
        tb += b; trr += ret; tl += liq
        data2.append([clabel(r["competencia"]), brl(b), brl(ret), brl(liq)])
    data2.append(["TOTAL", brl(tb), brl(trr), brl(tl)])
    t2 = Table(data2, colWidths=[34 * mm, 46 * mm, 44 * mm, 46 * mm], repeatRows=1)
    t2.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 7.2),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
        ("TEXTCOLOR", (2, 1), (2, -1), CORAL),
        ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
    ]))
    el.append(t2)
    el.append(Spacer(1, 4))
    el.append(Paragraph(
        "As retenções incluem INSS (11%) e IRRF, que constituem antecipação recuperável pela empresa; "
        "por isso não representam custo efetivo e a análise de margem toma o faturamento bruto como base.", body))

    doc.build(el)
    print("OK ->", args.out)

if __name__ == "__main__":
    main()
