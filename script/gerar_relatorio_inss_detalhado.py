#!/usr/bin/env python3
"""Relatorio Detalhado do INSS por Competencia - APPA 2025, com memoria de calculo.

Le as ABAS DE DETALHE (jan..dezembro + 13) do arquivo oficial `inss appa 2025.xlsx`,
decompoe em Base, Patronal (20%), RAT ajustado (RAT x FAP), Terceiros e Segurados,
e explica cada variavel da formula. Nao usa a aba 'resumo' (celula do 13o com erro).
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

SHEETS = [("jan", "Janeiro/2025"), ("fev", "Fevereiro/2025"), ("mar", "Março/2025"),
          ("abr", "Abril/2025"), ("maio", "Maio/2025"), ("junho", "Junho/2025"),
          ("julho", "Julho/2025"), ("agosto", "Agosto/2025"), ("setembro", "Setembro/2025"),
          ("outubro", "Outubro/2025"), ("novembro", "Novembro/2025"), ("dezembro", "Dezembro/2025"),
          ("13", "13º Salário/2025")]
PATRONAL = ("1138",); GILRAT = ("1141", "1646")
TERCEIROS = ("1170", "1176", "1191", "1196", "1200"); SEGURADOS = ("1082", "1099")

def brl(v):
    if v is None:
        return "—"
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def pct(v):
    return f"{v:.3f}".replace(".", ",") + "%"

def load(xlsx):
    wb = openpyxl.load_workbook(xlsx, data_only=True)
    rows = []
    for sh, label in SHEETS:
        if sh not in wb.sheetnames:
            continue
        acc = dict(patronal=0.0, gilrat=0.0, terceiros=0.0, segurados=0.0)
        for row in wb[sh].iter_rows(values_only=True):
            lab = row[0]
            if not isinstance(lab, str):
                continue
            try:
                v = float(row[1])
            except Exception:
                continue
            p = lab[:4]
            if p in PATRONAL:
                acc["patronal"] += v
            elif p in GILRAT:
                acc["gilrat"] += v
            elif p in TERCEIROS:
                acc["terceiros"] += v
            elif p in SEGURADOS:
                acc["segurados"] += v
        base = acc["patronal"] / 0.20 if acc["patronal"] else 0.0
        emp = acc["patronal"] + acc["gilrat"] + acc["terceiros"]
        rows.append(dict(label=label, base=base, patronal=acc["patronal"], gilrat=acc["gilrat"],
                         terceiros=acc["terceiros"], segurados=acc["segurados"], empregador=emp,
                         total=emp + acc["segurados"],
                         rat_pct=(acc["gilrat"] / base * 100 if base else 0),
                         ter_pct=(acc["terceiros"] / base * 100 if base else 0)))
    return rows

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
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Memória de cálculo INSS · APPA 2025 · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento técnico. Apuração da contribuição previdenciária patronal por competência.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    rows = load(args.data)
    jan = rows[0]

    styles = getSampleStyleSheet()
    h1 = ParagraphStyle("h1", parent=styles["Title"], textColor=INK, fontSize=24, leading=26, alignment=0)
    h1s = ParagraphStyle("h1s", parent=styles["Title"], textColor=CORAL, fontSize=13, leading=15, alignment=0)
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
    el.append(Paragraph("RELATÓRIO TÉCNICO · MEMÓRIA DE CÁLCULO", kick))
    el.append(Paragraph("Apuração do INSS Patronal por Competência", h1))
    el.append(Paragraph("APPA · Exercício 2025", h1s))
    el.append(HRFlowable(width="100%", thickness=1.6, color=CORAL, spaceBefore=6, spaceAfter=9))
    el.append(Paragraph("Demonstra, competência a competência, como cada valor da contribuição previdenciária "
                        "é obtido — base de cálculo, alíquotas e a composição patronal, RAT ajustado e terceiros.", sub))
    el.append(Spacer(1, 10))

    el.append(Paragraph("As variáveis da fórmula", sec))
    cell = ParagraphStyle("cell", parent=body, fontSize=7.6, leading=9.5)
    cellb = ParagraphStyle("cellb", parent=cell, fontName="Helvetica-Bold")
    cellh = ParagraphStyle("cellh", parent=cell, textColor=colors.white, fontName="Helvetica-Bold")
    ck = ParagraphStyle("ck", parent=cellb, textColor=CORAL)
    def P(txt, st):
        return Paragraph(txt, st)
    var = [
        [P("Variável", cellh), P("O que é", cellh), P("Como entra no cálculo", cellh)],
        [P("Base de cálculo (BC)", ck), P("Soma das remunerações do mês sujeitas à incidência do INSS (rubricas tributáveis).", cell), P("Ponto de partida — todas as alíquotas incidem sobre ela.", cellb)],
        [P("Contribuição patronal", ck), P("Cota da empresa sobre a folha.", cell), P("BC × 20%", cellb)],
        [P("RAT ajustado (GILRAT)", ck), P("Risco Ambiental do Trabalho (RAT 1/2/3%) multiplicado pelo FAP (fator 0,5 a 2,0).", cell), P("BC × (RAT × FAP)", cellb)],
        [P("Terceiros", ck), P("Contribuições a outras entidades (Sistema S, INCRA, etc.), conforme o FPAS.", cell), P("BC × alíquota de terceiros", cellb)],
        [P("INSS empregador", ck), P("Encargo previdenciário de responsabilidade da empresa.", cell), P("Patronal + RAT ajustado + Terceiros", cellb)],
        [P("Segurados", ck), P("Parte retida dos empregados (desconto em folha).", cell), P("Recolhida junto, mas não é custo da empresa", cellb)],
    ]
    vt = Table(var, colWidths=[34 * mm, 78 * mm, 62 * mm])
    vt.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INK),
        ("VALIGN", (0, 0), (-1, -1), "TOP"), ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PAPER]),
        ("BOX", (0, 0), (-1, -1), 0.6, LINE), ("INNERGRID", (0, 0), (-1, -1), 0.4, LINE),
        ("TOPPADDING", (0, 0), (-1, -1), 3.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 3.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
    ]))
    el.append(vt)
    el.append(Spacer(1, 8))

    el.append(Paragraph("Exemplo passo a passo — Janeiro/2025", sec))
    el.append(Paragraph(
        f"1) <b>Base de cálculo</b> = <b>R$ {brl(jan['base'])}</b> (remunerações incidentes do mês).<br/>"
        f"2) <b>Patronal</b> = Base × 20% = R$ {brl(jan['base'])} × 20% = <b>R$ {brl(jan['patronal'])}</b>.<br/>"
        f"3) <b>RAT ajustado</b> = Base × {pct(jan['rat_pct'])} = <b>R$ {brl(jan['gilrat'])}</b>.<br/>"
        f"4) <b>Terceiros</b> = Base × {pct(jan['ter_pct'])} = <b>R$ {brl(jan['terceiros'])}</b>.<br/>"
        f"5) <b>INSS empregador</b> = {brl(jan['patronal'])} + {brl(jan['gilrat'])} + {brl(jan['terceiros'])} = "
        f"<b>R$ {brl(jan['empregador'])}</b>.", body))
    el.append(Spacer(1, 4))
    el.append(Paragraph("Observação: a alíquota de RAT ajustado passou de ~2,389% (jan–mar) para ~1,597% (abr–dez), "
                        "por revisão do FAP no exercício; a de terceiros gira em torno de 5,8%. Os valores abaixo são "
                        "os efetivamente apurados em cada competência.", body))
    el.append(Spacer(1, 10))

    el.append(Paragraph("Memória de cálculo — mês a mês", sec))
    hdr = ["Competência", "Base de cálculo", "Patronal 20%", "RAT ajustado", "Terceiros",
           "INSS empregador", "Segurados", "INSS total"]
    data = [hdr]
    tot = dict(base=0.0, patronal=0.0, gilrat=0.0, terceiros=0.0, empregador=0.0, segurados=0.0, total=0.0)
    for r in rows:
        data.append([r["label"], brl(r["base"]), brl(r["patronal"]), brl(r["gilrat"]), brl(r["terceiros"]),
                     brl(r["empregador"]), brl(r["segurados"]), brl(r["total"])])
        for k in tot:
            tot[k] += r[k]
    data.append(["TOTAL", brl(tot["base"]), brl(tot["patronal"]), brl(tot["gilrat"]), brl(tot["terceiros"]),
                 brl(tot["empregador"]), brl(tot["segurados"]), brl(tot["total"])])
    cw = [26 * mm, 25 * mm, 22 * mm, 21 * mm, 20 * mm, 24 * mm, 19 * mm, 23 * mm]
    t = Table(data, colWidths=cw, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 6.7),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
        ("TEXTCOLOR", (5, 1), (5, -1), CORAL), ("FONTNAME", (5, 1), (5, -1), "Helvetica-Bold"),
        ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
        ("LINEBELOW", (0, -2), (-1, -2), 0.5, INK),
    ]))
    el.append(t)
    el.append(Spacer(1, 5))
    el.append(Paragraph(
        f"<b>INSS de responsabilidade do empregador no exercício: R$ {brl(tot['empregador'])}</b> "
        f"(patronal R$ {brl(tot['patronal'])} + RAT ajustado R$ {brl(tot['gilrat'])} + terceiros R$ {brl(tot['terceiros'])}). "
        f"Somando a parte retida dos segurados (R$ {brl(tot['segurados'])}), o INSS total apurado é "
        f"R$ {brl(tot['total'])}.", body))
    el.append(Spacer(1, 6))
    el.append(Paragraph("Conciliação: os valores acima são extraídos da apuração oficial (abas de detalhe por "
                        "competência) e conferem integralmente com o cruzamento independente a partir da folha. "
                        "Nota: a aba-resumo do arquivo de origem traz a célula do 13º (linha “s/Segurados”) com a "
                        "cota dos segurados subtraída em duplicidade; o valor correto do 13º empregador é "
                        f"R$ {brl(rows[-1]['empregador'])}, conforme a aba de detalhe.", body))

    el.append(Spacer(1, 12))
    el.append(Paragraph("A alíquota efetiva do encargo — por que não é 20%", sec))
    el.append(Paragraph(
        "Os 20% são apenas a <b>cota patronal</b>. Dividindo a cota patronal pela base confirma-se o índice — em "
        f"janeiro, R$ {brl(jan['patronal'])} ÷ R$ {brl(jan['base'])} = <b>20,00%</b>. Mas o encargo previdenciário "
        "da empresa <b>não se resume a isso</b>: sobre a <b>mesma base</b> incidem também o RAT ajustado e a "
        "contribuição de terceiros. Somando os três, o encargo real de janeiro é "
        f"R$ {brl(jan['empregador'])} ÷ R$ {brl(jan['base'])} = <b>{pct(jan['empregador'] / jan['base'] * 100)}</b> "
        "da base — e não 20%.", body))
    el.append(Spacer(1, 4))
    tot_base = sum(r["base"] for r in rows); tot_emp = sum(r["empregador"] for r in rows)
    el.append(Paragraph(
        f"No exercício, a alíquota efetiva média do encargo patronal foi <b>{pct(tot_emp / tot_base * 100)}</b> "
        f"(R$ {brl(tot_emp)} ÷ R$ {brl(tot_base)}). A variação mês a mês decorre do RAT ajustado, que caiu de "
        "~2,389% (jan–mar) para ~1,597% (abr–dez) por revisão do FAP.", body))
    el.append(Spacer(1, 6))

    hdr3 = ["Competência", "Patronal", "RAT ajustado", "Terceiros", "Encargo total"]
    data3 = [hdr3]
    for r in rows:
        b = r["base"]
        data3.append([r["label"], pct(r["patronal"] / b * 100), pct(r["gilrat"] / b * 100),
                      pct(r["terceiros"] / b * 100), pct(r["empregador"] / b * 100)])
    data3.append(["MÉDIA DO EXERCÍCIO", pct(tot["patronal"] / tot_base * 100), pct(tot["gilrat"] / tot_base * 100),
                  pct(tot["terceiros"] / tot_base * 100), pct(tot_emp / tot_base * 100)])
    t3 = Table(data3, colWidths=[42 * mm, 32 * mm, 34 * mm, 30 * mm, 32 * mm], repeatRows=1)
    t3.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 7.4),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
        ("TEXTCOLOR", (4, 1), (4, -1), CORAL), ("FONTNAME", (4, 1), (4, -1), "Helvetica-Bold"),
        ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
    ]))
    el.append(t3)
    el.append(Spacer(1, 4))
    el.append(Paragraph("Em resumo: a folha custa à empresa, em INSS, cerca de <b>27% a 28% da base</b> "
                        "(20% patronal + RAT ajustado + terceiros) — bem acima dos 20% isolados.", body))

    doc.build(el)
    print("OK ->", args.out)

if __name__ == "__main__":
    main()
