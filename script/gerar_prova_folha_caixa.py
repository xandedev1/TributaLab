#!/usr/bin/env python3
"""PDF-prova: por que a folha da CAIXA vai ate agosto e o faturamento para em fevereiro/marco.
Evidencia: rubricas rescisorias (marco) + cauda de acertos (abr-ago), direto da fonte."""
import json, os
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
OUT = r"C:\Users\xandao\Downloads\APPA_PROVA_FOLHA_CAIXA_ATE_AGOSTO_263.pdf"
MESES = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]

def brl(v):
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

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
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Prova · folha CAIXA · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento técnico-probatório. Dados extraídos da folha de pagamento oficial da APPA (2025).")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

S = getSampleStyleSheet()
h1 = ParagraphStyle("h1", parent=S["Title"], textColor=INK, fontSize=19, leading=22, alignment=0)
h1s = ParagraphStyle("h1s", parent=S["Title"], textColor=CORAL, fontSize=12, leading=14, alignment=0)
kick = ParagraphStyle("kick", parent=S["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
body = ParagraphStyle("body", parent=S["Normal"], textColor=INK2, fontSize=8.6, leading=13)
sec = ParagraphStyle("sec", parent=S["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)
cell = ParagraphStyle("cell", parent=body, fontSize=7.4, leading=8.8)

def th(data, cw, right_from=1, total=True):
    t = Table(data, colWidths=cw, repeatRows=1)
    st = [("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
          ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 7.6),
          ("ALIGN", (right_from, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
          ("ROWBACKGROUNDS", (0, 1), (-1, -2 if total else -1), [colors.white, PAPER]),
          ("TOPPADDING", (0, 0), (-1, -1), 2.6), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.6), ("LEFTPADDING", (0, 0), (-1, -1), 4)]
    if total:
        st += [("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
               ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold")]
    t.setStyle(TableStyle(st)); return t

def main():
    d = json.load(open(os.path.join(BASE, "detalhe_clientes_deficit.json"), encoding="utf-8"))["263"]
    venc = d["folha_mes_venc"]; desc = d["folha_mes_desc"]
    vr = [r for r in d["folha_rubricas"] if r["tipo"] == "Vencimento"]
    ult = max(i for i in range(12) if venc[i] or desc[i])

    doc = BaseDocTemplate(OUT, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=22 * mm, bottomMargin=16 * mm)
    doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=hf)])
    el = [Spacer(1, 4)]
    el.append(Paragraph("DOCUMENTO PROBATÓRIO · FOLHA × FATURAMENTO", kick))
    el.append(Paragraph("Por que a folha da CAIXA vai até agosto/2025", h1))
    el.append(Paragraph("APPA · Contrato 1884/2023 (apoio administrativo – RJ)", h1s))
    el.append(HRFlowable(width="100%", thickness=1.5, color=CORAL, spaceBefore=6, spaceAfter=8))
    el.append(Paragraph("<b>Pergunta:</b> se o faturamento (serviço) do contrato vai só até fevereiro, por que a folha "
                        "de pagamento continua até agosto? <b>Resposta:</b> o contrato foi <b>encerrado em março/2025</b>; "
                        "a folha de março em diante é <b>rescisão e acertos trabalhistas</b> — custo obrigatório do "
                        "encerramento, que <b>não gera faturamento</b> (não há novo serviço prestado). Tudo abaixo é "
                        "extraído da folha oficial da APPA (arquivos <b>Empresa 003</b> e <b>Empresa 006 – Folha 2025</b>).", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("1. Linha do tempo — folha mês a mês", sec))
    tl = [["Competência", "Vencimentos", "Descontos", "Líquido", "Natureza"]]
    natur = {0: "Serviço normal", 1: "Serviço normal", 2: "RESCISÃO (encerramento)"}
    for i in range(ult + 1):
        if not (venc[i] or desc[i]):
            continue
        nat = natur.get(i, "Acertos pós-rescisão")
        tl.append([MESES[i] + "/2025", brl(venc[i]), brl(desc[i]), brl(venc[i] - desc[i]), nat])
    tl.append(["TOTAL", brl(sum(venc)), brl(sum(desc)), brl(sum(venc) - sum(desc)), ""])
    t = th(tl, [30 * mm, 32 * mm, 30 * mm, 32 * mm, 50 * mm])
    st = t.getStyle() if False else None
    t.setStyle(TableStyle([("TEXTCOLOR", (4, 3), (4, 3), RED), ("FONTNAME", (4, 3), (4, 3), "Helvetica-Bold")]))
    el.append(t)
    el.append(Spacer(1, 4))
    el.append(Paragraph("Serviço (faturamento) e folha normais em <b>janeiro e fevereiro</b>. Em <b>março</b> a folha "
                        "quase triplica (R$ 4,25 mi) — é a rescisão. De <b>abril a agosto</b> restam apenas acertos "
                        "residuais decrescentes (R$ 67 mil → R$ 4,5 mil).", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("2. Prova da rescisão — rubricas de MARÇO/2025", sec))
    resc = [["Cód.", "Rubrica (verba rescisória)", "Valor em março"]]
    top = sorted(vr, key=lambda r: -r["mes"][2])[:11]
    tot_resc = 0.0
    for r in top:
        if r["mes"][2] <= 0:
            continue
        resc.append([r["codigo"], Paragraph(r["desc"], cell), brl(r["mes"][2])])
        tot_resc += r["mes"][2]
    resc.append(["", Paragraph("<b>Subtotal (11 maiores)</b>", cell), brl(tot_resc)])
    el.append(th(resc, [16 * mm, 128 * mm, 30 * mm], right_from=2))
    el.append(Spacer(1, 3))
    el.append(Paragraph("As rubricas falam por si: <b>F.G.T.S. Multa</b> (os 40% pagos na demissão sem justa causa), "
                        "<b>férias vencidas/proporcionais indenizadas</b>, <b>aviso prévio indenizado</b> e "
                        "<b>13º indenizado</b> — verbas que só existem em <b>rescisão de contrato de trabalho</b>. "
                        "Confirmam o desligamento em massa dos empregados alocados no contrato.", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("3. O que sobra de abril a agosto (cauda do encerramento)", sec))
    tail = [["Cód.", "Rubrica", "Total abr–ago", "Meses"]]
    tv = sorted(vr, key=lambda r: -sum(r["mes"][3:8]))
    tsum = 0.0
    for r in tv:
        s = sum(r["mes"][3:8])
        if s <= 50:
            continue
        meses = ", ".join(["Abr", "Mai", "Jun", "Jul", "Ago"][k] for k in range(5) if r["mes"][3 + k] > 0)
        tail.append([r["codigo"], Paragraph(r["desc"], cell), brl(s), Paragraph(meses, cell)])
        tsum += s
    tail.append(["", Paragraph("<b>Total abr–ago</b>", cell), brl(sum(sum(r["mes"][3:8]) for r in vr)), ""])
    el.append(th(tail, [14 * mm, 96 * mm, 28 * mm, 36 * mm], right_from=2))
    el.append(Spacer(1, 3))
    el.append(Paragraph("Natureza dos resíduos: <b>parcelas de rescisão</b> (férias, aviso, FGTS multa lançados após o "
                        "acerto), <b>diferenças de convenção coletiva (CCT)</b> retroativas, e — o principal item recorrente — "
                        "<b>salário-maternidade</b> de trabalhadora com estabilidade (não pode ser desligada; a folha segue "
                        "durante a licença). São obrigações legais posteriores ao fim do contrato.", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("4. Conclusão", sec))
    el.append(Paragraph(
        "• O descasamento <b>folha até agosto × faturamento até fevereiro</b> é <b>real e esperado</b>: reflete o "
        "<b>encerramento do contrato em março</b>, com rescisão e acertos que se estendem por meses.<br/>"
        "• Esses custos <b>não geram faturamento</b> (não há serviço novo ao cliente) — por isso a folha aparece "
        "“sozinha” após fevereiro.<br/>"
        "• <b>Não é falha de apuração</b>: todos os valores acima estão nos arquivos oficiais de folha da APPA "
        "(Empresa 003 e 006 – Folha 2025), rubrica a rubrica, mês a mês.<br/>"
        "• Portanto, avaliar a rentabilidade do contrato exige olhar os <b>meses de serviço (jan–fev)</b>, onde "
        "faturamento supera a folha; março em diante é <b>custo de encerramento</b>, não operação corrente.", body))
    doc.build(el)
    print("OK ->", OUT)

if __name__ == "__main__":
    main()
