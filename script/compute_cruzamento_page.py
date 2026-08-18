# -*- coding: utf-8 -*-
"""Replica exatamente a lógica de EfdRazaoDashboard#cross e imprime todos os números da página."""
import json
from decimal import Decimal

BASE = r"C:\Users\xandao\Documents\GitHub\TributaLab\tmp"


def load(name):
    with open(f"{BASE}\\{name}", encoding="utf-8") as f:
        return json.load(f)


def dec(v):
    return Decimal(str(v)).quantize(Decimal("0.01"))


efd = load("efd_razao.json")
a100 = efd["a100"]
c100 = efd["c100"]
serv = load("razao_servicos.json")["records"]
vend = load("razao_vendas.json")["records"]
devol_nfs = {r["num_nf"] for r in load("devolucao.json")["records"]}


def cross(base, match, direction):
    """direction: 'txt_to_pdf' (base=EFD) ou 'pdf_to_txt' (base=Razao). Retorna lista de dicts."""
    by_nf = {}
    for r in match:
        by_nf.setdefault(r["num_nf"], []).append(r)

    out = []
    for b in base:
        matches = by_nf.get(b["num_nf"])
        is_dev = b["num_nf"] in devol_nfs
        if matches:
            m = matches[0]
            if direction == "txt_to_pdf":
                credito = Decimal(0) if is_dev else dec(m["credito"])
                dif = dec(b["valor_nf"]) - credito
                out.append({"nf": b["num_nf"], "valor": dec(b["valor_nf"]), "credito": credito,
                            "dif": dif, "matched": True, "page_pdf": m["page"], "data": b["data_emissao"]})
            else:
                credito = Decimal(0) if is_dev else dec(b["credito"])
                dif = credito - dec(m["valor_nf"])
                out.append({"nf": b["num_nf"], "valor": dec(m["valor_nf"]), "credito": credito,
                            "dif": dif, "matched": True, "page_pdf": b["page"], "data": b["data_emissao"]})
        else:
            if direction == "txt_to_pdf":
                out.append({"nf": b["num_nf"], "valor": dec(b["valor_nf"]), "credito": Decimal(0),
                            "dif": dec(b["valor_nf"]), "matched": False, "page_pdf": None, "data": b["data_emissao"]})
            else:
                out.append({"nf": b["num_nf"], "valor": Decimal(0), "credito": dec(b["credito"]),
                            "dif": dec(b["credito"]), "matched": False, "page_pdf": b["page"], "data": b["data_emissao"]})
    return out


def summarize(name, recs):
    matched = [r for r in recs if r["matched"]]
    unmatched = [r for r in recs if not r["matched"]]
    ok = [r for r in matched if abs(r["dif"]) <= Decimal("0.05")]
    div = [r for r in matched if abs(r["dif"]) > Decimal("0.05")]
    total_dif = sum(r["dif"] for r in recs)
    print(f"\n== {name} ==")
    print(f"registros: {len(recs)}")
    print(f"cruzados: {len(matched)}  sem correspondencia: {len(unmatched)}")
    print(f"OK: {len(ok)}  divergencia: {len(div)}  sem match: {len(unmatched)}")
    print(f"diferenca total: {total_dif}")
    print(f"  soma dif dos divergentes: {sum(r['dif'] for r in div)}")
    print(f"  soma dif dos sem match:   {sum(r['dif'] for r in unmatched)}")
    return recs


# KPIs e totais da página
tot_a100 = sum(dec(r["valor_nf"]) for r in a100)
tot_c100 = sum(dec(r["valor_nf"]) for r in c100)
tot_serv = sum(dec(r["credito"]) for r in serv)
tot_vend = sum(dec(r["credito"]) for r in vend)
efd_total = tot_a100 + tot_c100
razao_total = tot_serv + tot_vend

print("=== KPIs ===")
print(f"EFD A100: {len(a100)} regs, total {tot_a100}")
print(f"EFD C100: {len(c100)} regs, total {tot_c100}")
print(f"Contabil Servicos: {len(serv)} regs, total {tot_serv}")
print(f"Contabil Vendas: {len(vend)} regs, total {tot_vend}")
print(f"EFD Total: {efd_total}")
print(f"Contabil Total: {razao_total}")
print(f"Diferenca (Razao - EFD): {razao_total - efd_total}")
print(f"Diferenca (EFD - Razao): {efd_total - razao_total}")
print(f"NFs de devolucao: {len(devol_nfs)}")

r1 = summarize("R1: EFD(A100) - Servicos [txt->pdf]", cross(a100, serv, "txt_to_pdf"))
r2 = summarize("R2: Servicos - EFD(A100) [pdf->txt]", cross(serv, a100, "pdf_to_txt"))
r3 = summarize("R3: EFD(C100) - Vendas [txt->pdf]", cross(c100, vend, "txt_to_pdf"))
r4 = summarize("R4: Vendas - EFD(C100) [pdf->txt]", cross(vend, c100, "pdf_to_txt"))

# Top 10 sem match dos relatorios 2 e 4 (maiores creditos)
for name, recs in [("R2", r2), ("R4", r4)]:
    um = sorted([r for r in recs if not r["matched"]], key=lambda r: -r["credito"])
    print(f"\n=== {name} top 10 sem match ===")
    for r in um[:10]:
        print(f"NF {r['nf']}  {r['data']}  credito {r['credito']}  pag {r['page_pdf']}")
    print(f"total sem match: {len(um)}, soma: {sum(r['credito'] for r in um)}")
