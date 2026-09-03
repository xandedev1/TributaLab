#!/usr/bin/env python3
"""Reanalise do contrato CAIXA a partir das NFS-e (DSPREST) — reconciliacao com a base."""
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
GREEN = colors.HexColor("#2e7d54"); RED = colors.HexColor("#c0492f")
XMLDIR = r"C:\Users\xandao\Downloads"
OUT = r"C:\Users\xandao\Downloads\APPA_REANALISE_CAIXA_NFSE_263_2025.pdf"

def brl(v):
    s = f"{abs(v):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-" if v < 0 else "") + s

def gv(d, tag):
    m = re.search(rf"<{tag}>(.*?)</{tag}>", d, re.S)
    return m.group(1).strip() if m else ""

def num(s):
    try:
        return float(str(s).replace(",", "."))
    except Exception:
        return 0.0

def parse_xml(f):
    d = open(f, encoding="utf-8", errors="replace").read()
    mes = re.search(r"MES DE (\w+)", d)
    contrato = re.search(r"CONTRATO\s+([\d/]+)", d)
    rps = re.search(r"<IdentificacaoRps><Numero>(\d+)", d)
    tom = re.search(r"<TomadorServico>.*?<Cnpj>(\d+)</Cnpj>", d, re.S)
    return {
        "numero": gv(d, "Numero"), "rps": rps.group(1) if rps else "",
        "emissao": gv(d, "DataEmissao")[:10], "mes_servico": (mes.group(1) if mes else "").capitalize(),
        "servicos": num(gv(d, "ValorServicos")), "pis": num(gv(d, "ValorPis")), "cofins": num(gv(d, "ValorCofins")),
        "inss": num(gv(d, "ValorInss")), "ir": num(gv(d, "ValorIr")), "csll": num(gv(d, "ValorCsll")),
        "iss": num(gv(d, "ValorIss")), "liquido": num(gv(d, "ValorLiquidoNfse")),
        "prestador": gv(d, "Cnpj"), "tomador": tom.group(1) if tom else "", "contrato": contrato.group(1) if contrato else "",
    }

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
    canvas.drawRightString(w - 18 * mm, h - 10.5 * mm, f"Reanálise CAIXA · NFS-e · Pág. {doc.page}")
    canvas.setStrokeColor(LINE); canvas.setLineWidth(0.5); canvas.line(18 * mm, 12 * mm, w - 18 * mm, 12 * mm)
    canvas.setFillColor(colors.HexColor("#738080")); canvas.setFont("Helvetica", 6.5)
    canvas.drawString(18 * mm, 8.5 * mm, "Uso restrito · documento técnico. Reconciliação do faturamento com as notas fiscais de serviço oficiais.")
    canvas.drawRightString(w - 18 * mm, 8.5 * mm, date.today().strftime("%d/%m/%Y"))
    canvas.restoreState()

S = getSampleStyleSheet()
h1 = ParagraphStyle("h1", parent=S["Title"], textColor=INK, fontSize=20, leading=23, alignment=0)
h1s = ParagraphStyle("h1s", parent=S["Title"], textColor=CORAL, fontSize=12, leading=14, alignment=0)
kick = ParagraphStyle("kick", parent=S["Normal"], textColor=CORAL, fontSize=9, fontName="Helvetica-Bold", spaceAfter=8)
body = ParagraphStyle("body", parent=S["Normal"], textColor=INK2, fontSize=8.6, leading=13)
sec = ParagraphStyle("sec", parent=S["Heading2"], textColor=INK, fontSize=13, leading=16, spaceBefore=10, spaceAfter=5)

def tblhead(data, cw, total=True):
    t = Table(data, colWidths=cw, repeatRows=1)
    st = [("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
          ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 7.8),
          ("ALIGN", (1, 0), (-1, -1), "RIGHT"), ("ALIGN", (0, 0), (0, -1), "LEFT"),
          ("ROWBACKGROUNDS", (0, 1), (-1, -2 if total else -1), [colors.white, PAPER]),
          ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3), ("LEFTPADDING", (0, 0), (-1, -1), 5)]
    if total:
        st += [("LINEABOVE", (0, -1), (-1, -1), 0.7, INK), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#eef3ef")),
               ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold")]
    t.setStyle(TableStyle(st)); return t

def main():
    notas = sorted([parse_xml(f) for f in glob.glob(os.path.join(XMLDIR, "DSPREST_E_10612748_20250201_20250228*.xml"))],
                   key=lambda n: n["numero"])
    # base (nossa) NF 141
    base = json.load(open(r"storage\private\fiscal_auditor\appa\nota_detalhe_263.json", encoding="utf-8"))["notas"]
    base141 = None
    for nt in base:
        m = {k: v for k, v in nt["campos"]}
        if m.get("Nº NF-e") == "141":
            base141 = {"bruto": num(m.get("Valor Fatura")), "liquido": num(m.get("Vl. Líquido") or m.get("Valor Líquido")),
                       "iss": num(m.get("Valor ISS"))}
    folha = json.load(open(r"storage\private\fiscal_auditor\appa\detalhe_clientes_deficit.json", encoding="utf-8"))["263"]
    fj, ff, fm = folha["folha_mes_venc"][0], folha["folha_mes_venc"][1], folha["folha_mes_venc"][2]

    fat_nfse = sum(n["servicos"] for n in notas)
    nf141 = next((n for n in notas if n["numero"] == "141"), None)
    nf142 = next((n for n in notas if n["numero"] == "142"), None)

    doc = BaseDocTemplate(OUT, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=22 * mm, bottomMargin=16 * mm)
    doc.addPageTemplates([PageTemplate(id="m", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=hf)])
    el = [Spacer(1, 4)]
    el.append(Paragraph("REANÁLISE DE CONTRATO · NOTAS FISCAIS DE SERVIÇO (NFS-e)", kick))
    el.append(Paragraph("Caixa Econômica Federal – CEF", h1))
    el.append(Paragraph("APPA · Contrato 1884/2023 · Rio de Janeiro", h1s))
    el.append(HRFlowable(width="100%", thickness=1.5, color=CORAL, spaceBefore=6, spaceAfter=8))
    el.append(Paragraph("A partir das notas fiscais de serviço oficiais (NFS-e/ABRASF), refizemos o faturamento do "
                        "contrato e reconciliamos com a base anterior, identificando o que faltava e por quê.", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("1. As notas fiscais recebidas", sec))
    nn = [["NF-e", "RPS", "Emissão", "Mês do serviço", "Valor serviços", "Total retido", "Líquido NFS-e"]]
    for n in notas:
        ret = n["inss"] + n["ir"] + n["pis"] + n["cofins"] + n["csll"]
        nn.append([n["numero"], n["rps"], n["emissao"], f"{n['mes_servico']}/2025", brl(n["servicos"]), brl(ret), brl(n["liquido"])])
    nn.append(["TOTAL", "", "", "jan+fev", brl(fat_nfse), "", brl(sum(n["liquido"] for n in notas))])
    el.append(tblhead(nn, [16 * mm, 14 * mm, 22 * mm, 28 * mm, 32 * mm, 30 * mm, 32 * mm]))
    el.append(Spacer(1, 4))
    el.append(Paragraph("<b>Atenção às datas (duas dimensões):</b> pela <b>emissão</b>, a NF 141 saiu em "
                        "<b>fevereiro</b> (06/02/2025) e a NF 142 em <b>março</b> (05/03/2025) — é assim que o portal "
                        "as lista (filtro “Emissão DSPREST”). Já o <b>mês do serviço (competência)</b>, informado na "
                        "discriminação da própria nota, é <b>janeiro</b> (NF 141) e <b>fevereiro</b> (NF 142). "
                        "A análise casa cada nota com o <b>mês do serviço</b> (regime de competência).", body))
    el.append(Spacer(1, 3))
    el.append(Paragraph(f"Prestador: APPA — CNPJ {nf141['prestador'] if nf141 else ''} (estab. 0005-44 “Emprego Certo”, RJ). "
                        f"Tomador: Caixa Econômica Federal — CNPJ {nf141['tomador'] if nf141 else ''}. "
                        "Retenções na NFS-e = INSS + IRRF + PIS + COFINS + CSLL (o <b>ISS não é retido na fonte</b> neste contrato).", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("2. Reconciliação com a base anterior", sec))
    rc = [["Nota", "Situação na base", "Valor (bruto)", "Observação"],
          ["NF-e 141 (jan)", "Presente", brl(nf141["servicos"]),
           f"bruto confere; líquido divergiu no ISS"],
          ["NF-e 142 (fev)", "AUSENTE", brl(nf142["servicos"]),
           "não constava em nenhuma planilha de retenção"]]
    rt = Table(rc, colWidths=[26 * mm, 30 * mm, 30 * mm, 88 * mm])
    rt.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), INK), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 7.8),
        ("ALIGN", (2, 0), (2, -1), "RIGHT"), ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PAPER]),
        ("BOX", (0, 0), (-1, -1), 0.6, LINE), ("INNERGRID", (0, 0), (-1, -1), 0.3, LINE),
        ("TEXTCOLOR", (1, 2), (1, 2), RED), ("FONTNAME", (1, 2), (1, 2), "Helvetica-Bold"),
        ("TEXTCOLOR", (1, 1), (1, 1), GREEN),
        ("TOPPADDING", (0, 0), (-1, -1), 3.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 3.5), ("LEFTPADDING", (0, 0), (-1, -1), 5)]))
    el.append(rt)
    el.append(Spacer(1, 4))
    if base141:
        el.append(Paragraph(
            f"<b>NF-e 141</b> — o valor bruto da base (R$ {brl(base141['bruto'])}) é idêntico ao da NFS-e "
            f"(R$ {brl(nf141['servicos'])}). O líquido diferiu: a base registrou R$ {brl(base141['liquido'])} "
            f"(subtraindo o ISS de R$ {brl(base141['iss'])}), enquanto a NFS-e traz R$ {brl(nf141['liquido'])} "
            f"— pois o <b>ISS não é retido na fonte</b> (fica a recolher pela empresa). Diferença = o próprio ISS.", body))
    el.append(Spacer(1, 3))
    el.append(Paragraph(
        f"<b>NF-e 142</b> — valor de R$ {brl(nf142['servicos'])} (serviço de fevereiro), <b>totalmente ausente</b> "
        "da base de retenção que recebemos (0 ocorrências em todos os arquivos). É o faturamento que “faltava”.", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("3. Impacto: faturamento × folha (jan + fev)", sec))
    imp = [["Competência", "Faturamento (NFS-e)", "Folha (vencimentos)", "Cobertura"],
           ["Janeiro/2025", brl(nf141["servicos"]), brl(fj), f"{nf141['servicos']/fj*100:.0f}%"],
           ["Fevereiro/2025", brl(nf142["servicos"]), brl(ff), f"{nf142['servicos']/ff*100:.0f}%"],
           ["TOTAL jan+fev", brl(fat_nfse), brl(fj + ff), f"{fat_nfse/(fj+ff)*100:.0f}%"]]
    el.append(tblhead(imp, [40 * mm, 46 * mm, 46 * mm, 30 * mm]))
    el.append(Spacer(1, 4))
    el.append(Paragraph(
        f"Com as duas notas, o faturamento de jan+fev (R$ {brl(fat_nfse)}) <b>supera a folha</b> do período "
        f"(R$ {brl(fj + ff)}) — o contrato é saudável nos meses normais. Antes, com apenas a NF 141 na base, "
        "ele aparecia como deficitário, o que era <b>distorção por faturamento incompleto</b>, não prejuízo real.", body))
    el.append(Spacer(1, 3))
    el.append(Paragraph(
        f"<b>Atenção — março:</b> a folha de março salta para R$ {brl(fm)} (provável rescisão/verbas do encerramento "
        "do contrato). Não há NFS-e de março neste conjunto; recomenda-se obter a nota do serviço de março para "
        "fechar o contrato integralmente.", body))
    el.append(Spacer(1, 8))

    el.append(Paragraph("4. Por que não achamos esses valores", sec))
    el.append(Paragraph(
        "• <b>Fonte incompleta</b>: as planilhas de retenção (nossa origem de faturamento) não continham a NF-e 142 — "
        "faturamento emitido pelo estabelecimento <b>0005-44 (“Emprego Certo”, RJ)</b>, que não entrou integralmente "
        "no arquivo recebido.<br/>"
        "• <b>Competência × emissão</b>: a NFS-e traz no campo “Competência” a data de emissão (05/03 para a nota de "
        "fevereiro); o mês do serviço só aparece na discriminação — o que dificulta o casamento automático se a "
        "planilha não normalizar isso.<br/>"
        "• <b>Tratamento do ISS</b>: o líquido da base subtraiu o ISS; na NFS-e o ISS não é retido na fonte, gerando "
        "a diferença de líquido observada na NF 141.", body))
    el.append(Spacer(1, 6))
    el.append(Paragraph(
        "<b>Conclusão:</b> a fonte definitiva do faturamento é a <b>NFS-e</b>. Recomenda-se importar as NFS-e por "
        "estabelecimento (inclusive 0005-44) e reconciliar contra a folha por competência do serviço — assim os "
        "“prejuízos” aparentes de contratos como a CAIXA se resolvem.", body))
    doc.build(el)
    print("OK ->", OUT)

if __name__ == "__main__":
    main()
