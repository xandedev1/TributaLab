#!/usr/bin/env python3
"""Relatorio Detalhado de Apuracao do INSS por Competencia - APPA 2025 (PDF).

Le a apuracao consolidada do INSS (por competencia) e produz o relatorio mensal
no padrao Real Audit Tech. Dezembro fica marcado como "Em analise".
"""
import argparse, openpyxl
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

MESES = {"01": "Janeiro", "02": "Fevereiro", "03": "Março", "04": "Abril", "05": "Maio",
         "06": "Junho", "07": "Julho", "08": "Agosto", "09": "Setembro", "10": "Outubro",
         "11": "Novembro", "12": "Dezembro"}
S2C = {"jan": "2025-01", "fev": "2025-02", "mar": "2025-03", "abr": "2025-04", "maio": "2025-05",
       "junho": "2025-06", "julho": "2025-07", "agosto": "2025-08", "setembro": "2025-09",
       "outubro": "2025-10", "novembro": "2025-11", "dezembro": "2025-12", "13": "2025-13"}

def brl(v):
    if v is None:
        return "—"
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def clabel(c):
    y, m = c.split("-")
    return "13º Salário/" + y if m == "13" else f"{MESES[m]}/{y}"

def num(v):
    try:
        return float(v)
    except Exception:
        return 0.0

def load_apuracao(xlsx):
    wb = openpyxl.load_workbook(xlsx, data_only=True)
    # resumo -> inss_total, inss_empregador, inss_liquido por competencia
    resumo = {}
    ws = wb["resumo"]
    cols = {}
    for row in ws.iter_rows(values_only=True):
        if row[0] == "Descritivo":
            for i, c in enumerate(row):
                if hasattr(c, "year"):
                    cols[i] = f"{c.year}-{c.month:02d}"
                elif str(c) == "13":
                    cols[i] = "2025-13"
            continue
        key = str(row[0] or "")
        for i, comp in cols.items():
            resumo.setdefault(comp, {})[key] = num(row[i])
    # por mes -> componentes patronal/gilrat/terceiros
    comps = {}
    for sh, comp in S2C.items():
        d = {"patronal": 0.0, "gilrat": 0.0, "terceiros": 0.0}
        if sh in wb.sheetnames:
            for row in wb[sh].iter_rows(values_only=True):
                lab = row[0]
                if not isinstance(lab, str):
                    continue
                v = num(row[1]) if len(row) > 1 else 0.0
                p = lab[:4]
                if p == "1138":
                    d["patronal"] += v
                elif p in ("1141", "1646"):
                    d["gilrat"] += v
                elif p in ("1170", "1176", "1191", "1196", "1200"):
                    d["terceiros"] += v
        r = resumo.get(comp, {})
        total = r.get("Inss Total", 0.0)
        emp = r.get("Inss s/Segurados", 0.0)
        liq = r.get("Inss s/Segurados (-) Crédito", 0.0)
        d.update({
            "competencia": comp,
            "base": d["patronal"] / 0.20 if d["patronal"] else 0.0,
            "empregador": emp,
            "total": total,
            "segurados": total - emp,
            "liquido": liq if liq else None,
            "credito": (emp - liq) if liq else None,
        })
        comps[comp] = d
    return comps

def header_footer(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(INK); canvas.rect(0, h - 16 * mm, w, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(0, h - 16 * mm, 2.6 * mm, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL); canvas.rect(18 * mm, h - 12.9 * mm, 6.6 * mm, 6.6 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white); canvas.setFont("Helvetica-Bold", 6.6)
    canvas.drawCentredString(18 * mm + 3.3 * mm, h - 11.0 * mm, "RAT")
    canvas.setFillColor(colors.white); canvas.setFont("Helvetica-Bold", 10)
    canvas.drawString(27.5 * mm, h - 9.8 * mm, "REAL AUDIT TECH")
    canvas.setFont("Helvetica", 5.8); canvas.setFillColor(MINT)
    canvas.drawString(27.7 * mm, h - 13.2 * mm, "TECNOLOGIA TRIBUTÁRIA")
    canvas.setFont("Helvetica", 8); canvas.setFillColor(MINT)
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Apuração do INSS · APPA 2025 · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento técnico-operacional. Apuração previdenciária a partir dos eventos eSocial da APPA.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    ap_data = load_apuracao(args.data)
    ordem = [f"2025-{m:02d}" for m in range(1, 12)] + ["2025-13"]  # Jan..Nov + 13o

    styles = getSampleStyleSheet()
    h1 = ParagraphStyle("h1", parent=styles["Title"], textColor=INK, fontSize=26, leading=28, spaceAfter=0, alignment=0)
    h1s = ParagraphStyle("h1s", parent=styles["Title"], textColor=CORAL, fontSize=13, leading=15, alignment=0, spaceAfter=2)
    kick = ParagraphStyle("kick", parent=styles["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
    sub = ParagraphStyle("sub", parent=styles["Normal"], textColor=colors.HexColor("#36595a"), fontSize=10, leading=14)
    body = ParagraphStyle("body", parent=styles["Normal"], textColor=INK2, fontSize=8.6, leading=13)
    sec = ParagraphStyle("sec", parent=styles["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)

    doc = BaseDocTemplate(args.out, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm,
                          topMargin=22 * mm, bottomMargin=16 * mm)
    doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)],
                                       onPage=header_footer)])
    el = []
    el.append(Spacer(1, 6))
    el.append(Paragraph("RELATÓRIO DETALHADO · APURAÇÃO PREVIDENCIÁRIA", kick))
    el.append(Paragraph("INSS por Competência", h1))
    el.append(Paragraph("APPA · Exercício 2025", h1s))
    el.append(HRFlowable(width="100%", thickness=1.6, color=CORAL, spaceBefore=6, spaceAfter=9))
    el.append(Paragraph("Apuração da contribuição previdenciária (patronal, RAT ajustado e terceiros) mês a mês, "
                        "recomposta a partir dos eventos oficiais do eSocial.", sub))
    el.append(Spacer(1, 12))
    meta = [
        ["Empresa", "APPA Serviços Temporários e Efetivos Ltda.", "CNPJ", "05.969.071/0001-10"],
        ["Período", "Janeiro a Novembro/2025 + 13º salário", "Emissão", date.today().strftime("%d/%m/%Y")],
        ["Objeto", "Apuração do INSS por competência", "Versão / Uso", "1.0 / Restrito"],
    ]
    mt = Table(meta, colWidths=[24 * mm, 82 * mm, 24 * mm, 44 * mm])
    mt.setStyle(TableStyle([
        ("FONTSIZE", (0, 0), (-1, -1), 8.4), ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#faf8f1")),
        ("BOX", (0, 0), (-1, -1), 0.7, LINE),
        ("TEXTCOLOR", (0, 0), (0, -1), CORAL), ("TEXTCOLOR", (2, 0), (2, -1), CORAL),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"), ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
        ("FONTNAME", (1, 0), (1, -1), "Helvetica-Bold"), ("FONTNAME", (3, 0), (3, -1), "Helvetica-Bold"),
        ("TEXTCOLOR", (1, 0), (1, -1), INK2), ("TEXTCOLOR", (3, 0), (3, -1), INK2),
        ("TOPPADDING", (0, 0), (-1, -1), 4.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 4.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 8), ("LINEBELOW", (0, 0), (-1, -2), 0.4, LINE),
    ]))
    el.append(mt)
    el.append(Spacer(1, 12))

    el.append(Paragraph("Metodologia de apuração", sec))
    el.append(Paragraph("A contribuição previdenciária foi apurada a partir dos eventos oficiais transmitidos ao "
                        "eSocial. Para cada competência determinou-se a base de cálculo incidente (a partir das "
                        "rubricas da folha, S-1200, classificadas pela tabela de rubricas, S-1010) e sobre ela "
                        "aplicaram-se a contribuição patronal de 20%, o RAT ajustado (alíquota RAT multiplicada pelo "
                        "FAP) e a contribuição de terceiros. O relatório apresenta o INSS total, a parcela retida dos "
                        "segurados e o INSS de responsabilidade do empregador, por competência.", body))
    el.append(Spacer(1, 6))
    el.append(Paragraph("A competência de <b>dezembro/2025 encontra-se em análise</b> e será incorporada em versão "
                        "posterior deste relatório.", body))
    el.append(Spacer(1, 10))

    el.append(Paragraph("Apuração mês a mês", sec))
    hdr = ["Competência", "Base de cálculo", "Patronal 20%", "RAT × FAP", "Terceiros",
           "INSS empregador", "Segurados", "INSS total"]
    rows = []
    tot = {k: 0.0 for k in ("base", "patronal", "gilrat", "terceiros", "empregador", "segurados", "total")}
    for comp in ordem:
        d = ap_data.get(comp, {})
        rows.append([clabel(comp), brl(d.get("base")), brl(d.get("patronal")), brl(d.get("gilrat")),
                     brl(d.get("terceiros")), brl(d.get("empregador")), brl(d.get("segurados")), brl(d.get("total"))])
        for k in tot:
            tot[k] += d.get(k, 0.0) or 0.0
    # dezembro em analise
    rows.append(["Dezembro/2025", "Em análise", "Em análise", "Em análise", "Em análise",
                 "Em análise", "Em análise", "Em análise"])
    total_row = ["TOTAL", brl(tot["base"]), brl(tot["patronal"]), brl(tot["gilrat"]), brl(tot["terceiros"]),
                 brl(tot["empregador"]), brl(tot["segurados"]), brl(tot["total"])]

    cw = [26 * mm, 25 * mm, 22 * mm, 19 * mm, 20 * mm, 24 * mm, 20 * mm, 24 * mm]
    data = [hdr] + rows + [total_row]
    t = Table(data, colWidths=cw, repeatRows=1)
    n = len(data)
    dez_idx = 1 + len(ordem)  # linha do dezembro
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 6.8),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
        ("TEXTCOLOR", (5, 1), (5, -1), CORAL), ("FONTNAME", (5, 1), (5, -1), "Helvetica-Bold"),
        ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
        ("BACKGROUND", (0, dez_idx), (-1, dez_idx), colors.HexColor("#f4ead5")),
        ("TEXTCOLOR", (0, dez_idx), (-1, dez_idx), colors.HexColor("#795b28")),
        ("ALIGN", (1, dez_idx), (-1, dez_idx), "CENTER"),
    ]))
    el.append(t)
    el.append(Spacer(1, 6))
    el.append(Paragraph(f"INSS de responsabilidade do empregador (Jan–Nov + 13º): <b>R$ {brl(tot['empregador'])}</b>. "
                        f"Dezembro/2025 em análise.", body))

    doc.build(el)
    print("OK ->", args.out)

if __name__ == "__main__":
    main()
