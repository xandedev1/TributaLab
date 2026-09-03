#!/usr/bin/env python3
"""PDF detalhado de nota(s) fiscal(is) — composicao e retencoes linha a linha."""
import argparse, json, os, unicodedata, re
from datetime import date
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
                                Table, TableStyle, HRFlowable)

INK = colors.HexColor("#173a3b"); INK2 = colors.HexColor("#0c292a")
CORAL = colors.HexColor("#d66e54"); MINT = colors.HexColor("#9bc8b5")
PAPER = colors.HexColor("#f5f2e9"); LINE = colors.HexColor("#d8d5c9"); GREEN = colors.HexColor("#2e7d54")

def brl(v):
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def num(s):
    try:
        return float(str(s).replace(",", "."))
    except Exception:
        return 0.0

def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().upper()
    return re.sub(r"[^A-Z0-9]+", "_", s).strip("_")[:44]

def hf(canvas, doc):
    canvas.saveState(); w, h = A4
    canvas.setFillColor(INK); canvas.rect(0, h - 16 * mm, w, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(0, h - 16 * mm, 2.6 * mm, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(18 * mm, h - 12.9 * mm, 6.6 * mm, 6.6 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white); canvas.setFont("Helvetica-Bold", 6.6)
    canvas.drawCentredString(18 * mm + 3.3 * mm, h - 11.0 * mm, "RAT")
    canvas.setFont("Helvetica-Bold", 10); canvas.drawString(27.5 * mm, h - 9.8 * mm, "REAL AUDIT TECH")
    canvas.setFont("Helvetica", 5.8); canvas.setFillColor(MINT); canvas.drawString(27.7 * mm, h - 13.2 * mm, "TECNOLOGIA TRIBUTÁRIA")
    canvas.setFont("Helvetica", 8); canvas.setFillColor(MINT)
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Detalhe da NF · APPA 2025 · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento técnico. Composição e retenções da nota fiscal, valor a valor.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

S = getSampleStyleSheet()
h1 = ParagraphStyle("h1", parent=S["Title"], textColor=INK, fontSize=20, leading=23, alignment=0)
h1s = ParagraphStyle("h1s", parent=S["Title"], textColor=CORAL, fontSize=12, leading=14, alignment=0)
kick = ParagraphStyle("kick", parent=S["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
body = ParagraphStyle("body", parent=S["Normal"], textColor=INK2, fontSize=8.6, leading=13)
secst = ParagraphStyle("sec", parent=S["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)

def get(campos, *names):
    m = {k: v for k, v in campos}
    for n in names:
        if n in m:
            return m[n]
    return ""

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    j = json.load(open(args.data, encoding="utf-8"))
    notas = j["notas"]

    doc = BaseDocTemplate(args.out, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=22 * mm, bottomMargin=16 * mm)
    doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=hf)])
    el = []
    cliente = get(notas[0]["campos"], "Cliente") if notas else ""
    for idx, nt in enumerate(notas):
        c = nt["campos"]
        fatura = num(get(c, "Valor Fatura"))
        cv = num(get(c, "VALOR CONTA VINCULADA"))
        scv = num(get(c, "VALOR NFS SEM CONTA VINCULADA"))
        rets = [("INSS (retenção 11% cessão de M.O.)", num(get(c, "Valor INSS"))),
                ("IRRF", num(get(c, "Valor IRRF"))),
                ("PIS", num(get(c, "Valor PIS"))),
                ("COFINS", num(get(c, "Valor COFINS"))),
                ("CSLL", num(get(c, "Valor CSLL"))),
                ("ISS", num(get(c, "Valor ISS")))]
        tot_ret = sum(v for _, v in rets)
        liq = num(get(c, "Vl. Líquido", "Valor Líquido")) or (fatura - tot_ret)

        if idx == 0:
            el.append(Spacer(1, 4))
            el.append(Paragraph("DETALHE DA NOTA FISCAL · VALOR A VALOR", kick))
            el.append(Paragraph(cliente, h1))
            el.append(Paragraph("APPA · Exercício 2025", h1s))
            el.append(HRFlowable(width="100%", thickness=1.5, color=CORAL, spaceBefore=6, spaceAfter=8))
        else:
            el.append(Spacer(1, 10))
        el.append(Paragraph(f"Nota fiscal nº {get(c,'Nº NF-e') or '—'} · competência {get(c,'Competência')}", secst))

        ident = [
            ["Cliente (tomador)", get(c, "Cliente"), "Cód.", get(c, "Cód.Cliente")],
            ["CNPJ", get(c, "CNPJ Cliente"), "Filial", get(c, "Filial")],
            ["Nº NF-e", get(c, "Nº NF-e"), "RPS", get(c, "RPS")],
            ["Data de emissão", get(c, "Dt Emissao"), "Competência", get(c, "Competência")],
        ]
        it = Table(ident, colWidths=[28 * mm, 78 * mm, 22 * mm, 46 * mm])
        it.setStyle(TableStyle([("FONTSIZE", (0, 0), (-1, -1), 8.2), ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#faf8f1")),
            ("BOX", (0, 0), (-1, -1), 0.7, LINE), ("INNERGRID", (0, 0), (-1, -1), 0.3, LINE),
            ("TEXTCOLOR", (0, 0), (0, -1), CORAL), ("TEXTCOLOR", (2, 0), (2, -1), CORAL),
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"), ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
            ("FONTNAME", (1, 0), (1, -1), "Helvetica-Bold"), ("FONTNAME", (3, 0), (3, -1), "Helvetica-Bold"),
            ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4), ("LEFTPADDING", (0, 0), (-1, -1), 6)]))
        el.append(it)
        el.append(Spacer(1, 8))

        el.append(Paragraph("Composição do valor da fatura", body))
        comp = [["Componente", "Valor", "% da fatura"],
                ["Valor com conta vinculada", brl(cv), f"{cv/fatura*100:.1f}%" if fatura else "—"],
                ["Valor NFS sem conta vinculada", brl(scv), f"{scv/fatura*100:.1f}%" if fatura else "—"],
                ["VALOR DA FATURA (bruto)", brl(fatura), "100,0%"]]
        ct = Table(comp, colWidths=[96 * mm, 44 * mm, 34 * mm])
        ct.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 8),
            ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
            ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
            ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
            ("TOPPADDING", (0, 0), (-1, -1), 3.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 3.5), ("LEFTPADDING", (0, 0), (-1, -1), 6)]))
        el.append(ct)
        el.append(Spacer(1, 8))

        el.append(Paragraph("Retenções sobre a nota (valor a valor)", body))
        rt = [["Tributo retido", "Valor", "% da fatura"]]
        for nome, v in rets:
            rt.append([nome, brl(v), f"{v/fatura*100:.2f}%" if fatura else "—"])
        rt.append(["TOTAL RETIDO", brl(tot_ret), f"{tot_ret/fatura*100:.2f}%" if fatura else "—"])
        rtb = Table(rt, colWidths=[96 * mm, 44 * mm, 34 * mm])
        rtb.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 8),
            ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
            ("TEXTCOLOR", (1, 1), (1, -2), CORAL),
            ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
            ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
            ("TOPPADDING", (0, 0), (-1, -1), 3.3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3.3), ("LEFTPADDING", (0, 0), (-1, -1), 6)]))
        el.append(rtb)
        el.append(Spacer(1, 8))

        el.append(Paragraph("Resultado da nota", body))
        rr = [["Valor da fatura (bruto)", brl(fatura)],
              ["(−) Total de retenções", brl(-tot_ret)],
              ["(=) VALOR LÍQUIDO RECEBIDO", brl(liq)]]
        rrt = Table(rr, colWidths=[140 * mm, 34 * mm])
        rrt.setStyle(TableStyle([("FONTSIZE", (0, 0), (-1, -1), 9), ("ALIGN", (1, 0), (1, -1), "RIGHT"),
            ("ROWBACKGROUNDS", (0, 0), (-1, -2), [colors.white, PAPER]),
            ("LINEABOVE", (0, -1), (-1, -1), 0.8, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
            ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"), ("TEXTCOLOR", (1, -1), (1, -1), GREEN),
            ("BOX", (0, 0), (-1, -1), 0.6, LINE),
            ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4), ("LEFTPADDING", (0, 0), (-1, -1), 6)]))
        el.append(rrt)
        el.append(Spacer(1, 5))
        el.append(Paragraph(
            "O <b>INSS retido (11% sobre cessão de mão de obra)</b> e o <b>IRRF</b> são antecipações que a empresa "
            "compensa/recupera; ISS, PIS, COFINS e CSLL são tributos sobre a receita. O valor líquido é o efetivamente "
            "creditado; a receita reconhecida (competência) é o valor bruto da fatura.", body))
    doc.build(el)
    print("OK ->", args.out)

if __name__ == "__main__":
    main()
