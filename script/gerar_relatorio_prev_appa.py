#!/usr/bin/env python3
"""Gera o Relatorio Detalhado da Base Previdenciaria por Lotacao - APPA 2025 (PDF).

Le storage/private/fiscal_auditor/appa/prev_base_calc.json e produz um PDF no padrao
"relatorio detalhado" (capa + metodologia + resumo mes a mes + detalhe por lotacao).
"""
import os, json, argparse
from collections import defaultdict
from datetime import date
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
                                Table, TableStyle, PageBreak, HRFlowable)

INK = colors.HexColor("#173a3b")
INK2 = colors.HexColor("#0c292a")
CORAL = colors.HexColor("#d66e54")
MINT = colors.HexColor("#9bc8b5")
PAPER = colors.HexColor("#f5f2e9")
LINE = colors.HexColor("#d8d5c9")

MESES = {"01": "Janeiro", "02": "Fevereiro", "03": "Março", "04": "Abril", "05": "Maio",
         "06": "Junho", "07": "Julho", "08": "Agosto", "09": "Setembro", "10": "Outubro",
         "11": "Novembro", "12": "Dezembro"}

def brl(v):
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def comp_label(c):
    y, m = c.split("-")
    if m == "13":
        return f"13º Salário/{y}"
    return f"{MESES[m]}/{y}"

def header_footer(canvas, doc):
    canvas.saveState()
    w, h = A4
    # header bar
    canvas.setFillColor(INK)
    canvas.rect(0, h - 16 * mm, w, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(CORAL)
    canvas.rect(0, h - 16 * mm, 2.6 * mm, 16 * mm, fill=1, stroke=0)
    # monograma
    canvas.setFillColor(CORAL)
    canvas.rect(18 * mm, h - 12.9 * mm, 6.6 * mm, 6.6 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white)
    canvas.setFont("Helvetica-Bold", 6.6)
    canvas.drawCentredString(18 * mm + 3.3 * mm, h - 11.0 * mm, "RAT")
    canvas.setFillColor(colors.white)
    canvas.setFont("Helvetica-Bold", 10)
    canvas.drawString(27.5 * mm, h - 9.8 * mm, "REAL AUDIT TECH")
    canvas.setFont("Helvetica", 5.8)
    canvas.setFillColor(MINT)
    canvas.drawString(27.7 * mm, h - 13.2 * mm, "TECNOLOGIA TRIBUTÁRIA")
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MINT)
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm,
                           f"Base Previdenciária · APPA 2025 · Pág. {doc.page}")
    # footer
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5)
    canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080"))
    canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm,
                      "Uso restrito · documento técnico-operacional. Base recomposta dos eventos eSocial da APPA; "
                      "não constitui parecer legal, fiscal ou trabalhista.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

def money_table(headers, rows, col_widths, totals_row=None, highlight_last_col=True):
    data = [headers] + rows
    if totals_row:
        data.append(totals_row)
    t = Table(data, colWidths=col_widths, repeatRows=1)
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), INK),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 7.2),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"),
        ("ALIGN", (0, 0), (0, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 2.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("LINEBELOW", (0, 0), (-1, 0), 0.6, INK),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1 if not totals_row else -2), [colors.white, PAPER]),
        ("LINEABOVE", (0, -1), (-1, -1), 0.6, INK),
    ]
    if highlight_last_col:
        style.append(("TEXTCOLOR", (-1, 1), (-1, -1), CORAL))
        style.append(("FONTNAME", (-1, 1), (-1, -1), "Helvetica-Bold"))
    if totals_row:
        style += [("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
                  ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold")]
    t.setStyle(TableStyle(style))
    return t

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    payload = json.load(open(args.data, encoding="utf-8"))
    rows = payload["rows"]
    tot = payload["totais"]

    por_comp = defaultdict(list)
    for r in rows:
        por_comp[r["competencia"]].append(r)
    comps = sorted(por_comp)

    styles = getSampleStyleSheet()
    h1 = ParagraphStyle("h1", parent=styles["Title"], textColor=INK, fontSize=26, leading=28, spaceAfter=0, alignment=0)
    h1sub = ParagraphStyle("h1sub", parent=styles["Title"], textColor=CORAL, fontSize=13, leading=15,
                           alignment=0, spaceAfter=2)
    kick = ParagraphStyle("kick", parent=styles["Normal"], textColor=CORAL, fontSize=9, leading=11,
                          fontName="Helvetica-Bold", spaceAfter=8)
    sub = ParagraphStyle("sub", parent=styles["Normal"], textColor=colors.HexColor("#36595a"),
                         fontSize=10, leading=14)
    body = ParagraphStyle("body", parent=styles["Normal"], textColor=INK2, fontSize=8.6, leading=13)
    sec = ParagraphStyle("sec", parent=styles["Heading2"], textColor=INK, fontSize=13, leading=16,
                         spaceBefore=10, spaceAfter=5)
    mono = ParagraphStyle("mono", parent=styles["Normal"], textColor=colors.HexColor("#36595a"),
                          fontSize=8, leading=12)

    doc = BaseDocTemplate(args.out, pagesize=A4,
                          leftMargin=18 * mm, rightMargin=18 * mm,
                          topMargin=22 * mm, bottomMargin=16 * mm)
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="f")
    doc.addPageTemplates([PageTemplate(id="main", frames=[frame], onPage=header_footer)])

    el = []
    # ---- capa / metadados ----
    el.append(Spacer(1, 6))
    el.append(Paragraph("RELATÓRIO DETALHADO · AUDITORIA PREVIDENCIÁRIA", kick))
    el.append(Paragraph("Base Previdenciária por Lotação", h1))
    el.append(Paragraph("APPA · Exercício 2025", h1sub))
    el.append(HRFlowable(width="100%", thickness=1.6, color=CORAL, spaceBefore=6, spaceAfter=9))
    el.append(Paragraph("Recomposição da base de contribuição previdenciária a partir dos eventos oficiais "
                        "do eSocial (S-1200 × S-1010) e apuração dos encargos por lotação e competência.", sub))
    el.append(Spacer(1, 12))
    meta = [
        ["Empresa auditada", "APPA Serviços Temporários e Efetivos Ltda.", "CNPJ", "05.969.071/0001-10"],
        ["Período", f"{comp_label(comps[0])} a {comp_label(comps[-1])}", "Emissão", date.today().strftime("%d/%m/%Y")],
        ["Objeto", "Base e encargos previdenciários por lotação", "Versão / Uso", "1.0 / Restrito"],
    ]
    mt = Table(meta, colWidths=[28 * mm, 78 * mm, 24 * mm, 44 * mm])
    mt.setStyle(TableStyle([
        ("FONTSIZE", (0, 0), (-1, -1), 8.4),
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#faf8f1")),
        ("BOX", (0, 0), (-1, -1), 0.7, LINE),
        ("TEXTCOLOR", (0, 0), (0, -1), CORAL), ("TEXTCOLOR", (2, 0), (2, -1), CORAL),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"), ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
        ("TEXTCOLOR", (1, 0), (1, -1), INK2), ("TEXTCOLOR", (3, 0), (3, -1), INK2),
        ("FONTNAME", (1, 0), (1, -1), "Helvetica-Bold"), ("FONTNAME", (3, 0), (3, -1), "Helvetica-Bold"),
        ("TOPPADDING", (0, 0), (-1, -1), 4.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 4.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("LINEBELOW", (0, 0), (-1, -2), 0.4, LINE),
    ]))
    el.append(mt)
    el.append(Spacer(1, 12))

    # ---- metodologia (impessoal / tecnica) ----
    el.append(Paragraph("Metodologia de apuração", sec))
    el.append(Paragraph("A base de cálculo da contribuição previdenciária foi recomposta integralmente a partir "
                        "dos eventos oficiais transmitidos pela APPA ao eSocial, sem utilização dos valores "
                        "totalizados pela administração tributária como fonte primária.", body))
    el.append(Spacer(1, 4))
    passos = [
        "<b>1. Dicionário de rubricas (S-1010, competências de 2018 a 2026).</b> Para cada par (código de "
        "rubrica, tabela de rubrica) determinou-se a incidência de contribuição previdenciária (codIncCP) "
        "vigente em cada competência. Em caso de igualdade de início de validade, prevalece o registro de "
        "transmissão mais recente (alteração sobre inclusão).",
        "<b>2. Folha de pagamento (S-1200, eventos transmitidos em 2025).</b> Para cada trabalhador e "
        "competência considerou-se exclusivamente o recibo mais recente (tratamento de retificação), "
        "somando-se as rubricas com incidência para composição da base por lotação.",
        "<b>3. Apuração dos encargos.</b> Sobre a base incidente aplicou-se a contribuição patronal de 20%, o "
        "RAT ajustado (alíquota RAT de 3% multiplicada pelo FAP de 0,7943 = 2,3829%) e a contribuição de "
        "terceiros de 5,8% (FPAS 515), compondo o total previdenciário.",
        "<b>4. Validação.</b> A base recomposta foi cotejada com os totalizadores oficiais do eSocial (S-5011, "
        "por lotação; S-5001, por trabalhador), apresentando aderência dentro de margem reduzida.",
        "<b>Nota.</b> O FGTS não integra este relatório, sendo apurado por lotação no módulo de Encargos.",
    ]
    for p in passos:
        el.append(Paragraph(p, body))
        el.append(Spacer(1, 3))
    el.append(Spacer(1, 8))

    # ---- resumo mes a mes ----
    el.append(Paragraph("Resumo mês a mês", sec))
    hdr = ["Competência", "Lotações", "Base INSS (R$)", "Patronal 20%", "RAT × FAP", "Terceiros", "Total prev. (R$)"]
    sres = []
    for c in comps:
        rs = por_comp[c]
        sres.append([comp_label(c), str(len(rs)),
                     brl(sum(r["base_inss"] for r in rs)),
                     brl(sum(r["patronal"] for r in rs)),
                     brl(sum(r["rat_fap"] for r in rs)),
                     brl(sum(r["terceiros"] for r in rs)),
                     brl(sum(r["total_prev"] for r in rs))])
    total_row = ["TOTAL 2025", str(len(rows)), brl(tot["base_inss"]), brl(tot["patronal"]),
                 brl(tot["rat_fap"]), brl(tot["terceiros"]), brl(tot["total_prev"])]
    cw = [26 * mm, 15 * mm, 30 * mm, 25 * mm, 22 * mm, 24 * mm, 32 * mm]
    el.append(money_table(hdr, sres, cw, totals_row=total_row))
    el.append(Spacer(1, 4))
    el.append(Paragraph(f"Total previdenciário do período: <b>R$ {brl(tot['total_prev'])}</b> "
                        f"sobre uma base de INSS de R$ {brl(tot['base_inss'])}.", body))

    # ---- detalhe por mes (lotacao a lotacao) ----
    hdr2 = ["Lotação", "Base INSS (R$)", "Patronal 20%", "RAT × FAP", "Terceiros", "Total prev. (R$)"]
    cw2 = [34 * mm, 30 * mm, 26 * mm, 22 * mm, 24 * mm, 32 * mm]
    for c in comps:
        el.append(PageBreak())
        rs = sorted(por_comp[c], key=lambda r: -r["total_prev"])
        el.append(Paragraph(f"{comp_label(c)} — {len(rs)} lotações", sec))
        el.append(Paragraph(f"Total previdenciário do mês: <b>R$ {brl(sum(r['total_prev'] for r in rs))}</b>", mono))
        el.append(Spacer(1, 3))
        drows = [[r["lotacao"], brl(r["base_inss"]), brl(r["patronal"]), brl(r["rat_fap"]),
                  brl(r["terceiros"]), brl(r["total_prev"])] for r in rs]
        trow = ["Subtotal " + comp_label(c),
                brl(sum(r["base_inss"] for r in rs)), brl(sum(r["patronal"] for r in rs)),
                brl(sum(r["rat_fap"] for r in rs)), brl(sum(r["terceiros"] for r in rs)),
                brl(sum(r["total_prev"] for r in rs))]
        el.append(money_table(hdr2, drows, cw2, totals_row=trow))

    doc.build(el)
    print("OK ->", args.out)

if __name__ == "__main__":
    main()
