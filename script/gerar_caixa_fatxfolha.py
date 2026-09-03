#!/usr/bin/env python3
"""CAIXA — Faturamento (NFS-e) x Folha, com a diferenca real em %.
Separa operacao (jan-fev, meses de servico) do encerramento (mar-ago, rescisao)."""
import glob, os, re, json
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
BASE = r"storage\private\fiscal_auditor\appa"
XMLDIR = r"C:\Users\xandao\Downloads"
OUT = r"C:\Users\xandao\Downloads\APPA_CAIXA_FATURAMENTO_x_FOLHA_263.pdf"
MESES = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]

def brl(v):
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def num(s):
    try:
        return float(str(s).replace(",", "."))
    except Exception:
        return 0.0

def gv(d, t):
    m = re.search(rf"<{t}>(.*?)</{t}>", d, re.S); return m.group(1).strip() if m else ""

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
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"CAIXA · Faturamento × Folha · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento gerencial. Faturamento (NFS-e) × folha por competência de serviço.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

S = getSampleStyleSheet()
h1 = ParagraphStyle("h1", parent=S["Title"], textColor=INK, fontSize=20, leading=23, alignment=0)
h1s = ParagraphStyle("h1s", parent=S["Title"], textColor=CORAL, fontSize=12, leading=14, alignment=0)
kick = ParagraphStyle("kick", parent=S["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
body = ParagraphStyle("body", parent=S["Normal"], textColor=INK2, fontSize=8.6, leading=13)
sec = ParagraphStyle("sec", parent=S["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)

def th(data, cw, colorrows=None):
    t = Table(data, colWidths=cw, repeatRows=1)
    st = [("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
          ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 7.8),
          ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
          ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
          ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
          ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
          ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3), ("LEFTPADDING", (0, 0), (-1, -1), 5)]
    for (r, c) in (colorrows or []):
        st.append(("TEXTCOLOR", (5, r), (6, r), c)); st.append(("FONTNAME", (5, r), (6, r), "Helvetica-Bold"))
    t.setStyle(TableStyle(st)); return t

def main():
    # faturamento NFS-e por mes de servico
    fat = {}
    for f in glob.glob(os.path.join(XMLDIR, "DSPREST_E_10612748_20250201_20250228*.xml")):
        d = open(f, encoding="utf-8", errors="replace").read()
        mes = re.search(r"MES DE (\w+)", d)
        mi = MESES.index(mes.group(1).capitalize()) if mes else None
        fat[mi] = num(gv(d, "ValorServicos"))
    folha = json.load(open(os.path.join(BASE, "detalhe_clientes_deficit.json"), encoding="utf-8"))["263"]
    venc = folha["folha_mes_venc"]
    m = json.load(open(os.path.join(BASE, "cruzamento_resultado.json"), encoding="utf-8"))["rows"]
    md = {r["competencia"]: r for r in m}
    def enc(mm):
        r = md[f"2025-{mm:02d}"]; return (r["inss_empregador"] + r["fgts"]) / r["folha_vencimentos"]
    enc_op = (enc(1) + enc(2)) / 2  # encargo medio jan-fev

    doc = BaseDocTemplate(OUT, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=22 * mm, bottomMargin=16 * mm)
    doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=hf)])
    el = [Spacer(1, 4)]
    el.append(Paragraph("RELATÓRIO GERENCIAL · FATURAMENTO × FOLHA", kick))
    el.append(Paragraph("Caixa Econômica Federal – CEF", h1))
    el.append(Paragraph("APPA · Contrato 1884/2023 · dados atualizados com as NFS-e", h1s))
    el.append(HRFlowable(width="100%", thickness=1.5, color=CORAL, spaceBefore=6, spaceAfter=8))
    el.append(Paragraph("Refeito com o faturamento oficial (NFS-e), inclusive a nota de fevereiro que faltava. "
                        "O faturamento é casado com a folha pelo <b>mês do serviço (competência)</b>. Os encargos "
                        f"(INSS + FGTS) aplicados sobre a folha são de <b>{enc_op*100:.1f}%</b> (média jan–fev).", body))
    el.append(Spacer(1, 8))

    # A) operacao
    el.append(Paragraph("1. Operação — meses de serviço (jan–fev)", sec))
    hdr = ["Competência", "Faturamento", "Folha bruta", "Encargos", "Custo M.O.", "Resultado", "Margem"]
    data = [hdr]
    tf = tfo = tc = 0.0; crow = []
    for i in (0, 1):
        fatm = fat.get(i, 0.0); fol = venc[i]; e = fol * enc_op; custo = fol + e
        res = fatm - custo; marg = res / fatm * 100 if fatm else 0
        tf += fatm; tfo += fol; tc += custo
        data.append([f"{MESES[i]}/2025", brl(fatm), brl(fol), brl(e), brl(custo), brl(res), f"{marg:+.1f}%"])
        crow.append((len(data) - 1, GREEN if res >= 0 else RED))
    res_op = tf - tc; marg_op = res_op / tf * 100 if tf else 0
    data.append(["SUBTOTAL operação", brl(tf), brl(tfo), brl(tc - tfo), brl(tc), brl(res_op), f"{marg_op:+.1f}%"])
    el.append(th(data, [30 * mm, 27 * mm, 26 * mm, 22 * mm, 26 * mm, 24 * mm, 15 * mm], crow))
    el.append(Spacer(1, 4))
    el.append(Paragraph(f"Nos meses de serviço, o faturamento (R$ {brl(tf)}) cobre o custo de mão de obra "
                        f"(R$ {brl(tc)}) com <b>resultado de R$ {brl(res_op)} ({marg_op:+.1f}%)</b> — "
                        "<font color='#2e7d54'><b>contrato saudável na operação</b></font>.", body))
    el.append(Spacer(1, 8))

    # B) encerramento
    el.append(Paragraph("2. Encerramento — rescisão e acertos (mar–ago)", sec))
    enc_folha = sum(venc[2:8])
    eb = [["Competência", "Folha (rescisão/acertos)", "Faturamento", "Observação"],
          ["Março/2025", brl(venc[2]), "—", "rescisão em massa (FGTS multa, férias, aviso)"],
          ["Abril–Agosto/2025", brl(sum(venc[3:8])), "—", "parcelas de rescisão + salário-maternidade + CCT"],
          ["SUBTOTAL encerramento", brl(enc_folha), "R$ 0,00", "custo do fim do contrato, sem serviço novo"]]
    ebt = Table(eb, colWidths=[36 * mm, 42 * mm, 26 * mm, 70 * mm])
    ebt.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 7.6),
        ("ALIGN", (1, 0), (2, -1), "RIGHT"), ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, PAPER]),
        ("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"), ("TEXTCOLOR", (1, 1), (1, -1), CORAL),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3), ("LEFTPADDING", (0, 0), (-1, -1), 5)]))
    el.append(ebt)
    el.append(Spacer(1, 4))
    el.append(Paragraph("A rescisão não é serviço prestado — não gera nota. Falta ainda a NFS-e do <b>serviço de "
                        "março</b> (emitida em abril), que compensaria parte deste mês; recomenda-se obtê-la.", body))
    el.append(Spacer(1, 8))

    # C) diferenca real
    el.append(Paragraph("3. A diferença real (em %)", sec))
    folha_tot = sum(venc)
    dif = [["Visão", "Faturamento", "Folha/Custo", "Diferença", "%"],
           ["Operação (jan–fev, só serviço)", brl(tf), brl(tc), brl(res_op), f"{marg_op:+.1f}%"],
           ["Contrato inteiro (com rescisão)", brl(tf), brl(folha_tot), brl(tf - folha_tot), f"{(tf-folha_tot)/tf*100:+.1f}%"]]
    dt = Table(dif, colWidths=[62 * mm, 30 * mm, 30 * mm, 30 * mm, 22 * mm])
    dt.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PAPER]),
        ("BOX", (0, 0), (-1, -1), 0.6, LINE), ("INNERGRID", (0, 0), (-1, -1), 0.3, LINE),
        ("TEXTCOLOR", (3, 1), (4, 1), GREEN), ("FONTNAME", (3, 1), (4, 1), "Helvetica-Bold"),
        ("TEXTCOLOR", (3, 2), (4, 2), RED), ("FONTNAME", (3, 2), (4, 2), "Helvetica-Bold"),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4), ("LEFTPADDING", (0, 0), (-1, -1), 5)]))
    el.append(dt)
    el.append(Spacer(1, 5))
    el.append(Paragraph(
        f"<b>Leitura:</b> na <b>operação</b> (meses em que houve serviço), a diferença real é <b>{marg_op:+.1f}%</b> "
        "— positiva, o contrato dava margem. Considerando o <b>contrato inteiro</b>, a diferença cai para "
        f"<b>{(tf-folha_tot)/tf*100:+.1f}%</b>, mas isso ocorre porque (i) a folha carrega a <b>rescisão de março</b> "
        "(custo único de encerramento) e (ii) ainda <b>falta a nota do serviço de março</b> na base. "
        "Descontando o encerramento, o contrato foi <b>lucrativo enquanto operou</b>.", body))
    doc.build(el)
    print("OK ->", OUT)

if __name__ == "__main__":
    main()
