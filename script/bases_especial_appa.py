#!/usr/bin/env python3
"""Extrai, do S-5001 (evtBasesTrab) da competencia 2025-01, as bases por LOTACAO:
base normal (tpValor 11) e base de aposentadoria especial (tpValor 12), com dedup
por trabalhador (ultimo recibo). Escreve JSON para o relatorio analitico.
"""
import zipfile, re, json, os
from collections import defaultdict

ZIP = r"C:\Users\xandao\Downloads\appa tabela gerais\todos eventos APPA 2025\fevereiro.zip"
PER = "2025-01"
OUT = r"storage\private\fiscal_auditor\appa\bases_especial_2025-01.json"

evt_re = re.compile(r'<evtBasesTrab Id="([^"]+)">(.*?)</evtBasesTrab>', re.S)
per_re = re.compile(r"<perApur>(.*?)</perApur>")
cpf_re = re.compile(r"<cpfTrab>(\d+)</cpfTrab>")
lot_re = re.compile(r"<ideEstabLot>(.*?)</ideEstabLot>", re.S)
cod_re = re.compile(r"<codLotacao>(.*?)</codLotacao>")
bcs_re = re.compile(r"<infoBaseCS><ind13>(\d)</ind13><tpValor>(\d+)</tpValor><valor>([\d.]+)</valor>")

# Passo 1: dedup por cpf (ultimo Id) na competencia
winners = {}  # cpf -> (id, body)
with zipfile.ZipFile(ZIP) as zf:
    for name in zf.namelist():
        if not name.lower().endswith(".xml"):
            continue
        d = zf.read(name).decode("utf-8", "replace")
        if "evtBasesTrab" not in d:
            continue
        for mid, body in evt_re.findall(d):
            pm = per_re.search(body)
            if not pm or pm.group(1) != PER:
                continue
            cm = cpf_re.search(body)
            if not cm:
                continue
            cpf = cm.group(1)
            if cpf not in winners or mid > winners[cpf][0]:
                winners[cpf] = (mid, body)

# Passo 2: agrega por lotacao base 11 e 12 (ind13=0)
lot = defaultdict(lambda: {"base11": 0.0, "base12": 0.0, "cpfs": set(), "cpfs12": set()})
for cpf, (mid, body) in winners.items():
    for lb in lot_re.findall(body):
        cm = cod_re.search(lb)
        if not cm:
            continue
        cod = cm.group(1)
        for ind13, tp, val in bcs_re.findall(lb):
            if ind13 != "0":
                continue
            v = float(val)
            if tp == "11":
                lot[cod]["base11"] += v
                lot[cod]["cpfs"].add(cpf)
            elif tp == "12":
                lot[cod]["base12"] += v
                lot[cod]["cpfs12"].add(cpf)

rows = []
for cod, x in lot.items():
    rows.append({
        "lotacao": cod,
        "base_normal": round(x["base11"], 2),
        "base_especial": round(x["base12"], 2),
        "adicional_12pct": round(x["base12"] * 0.12, 2),
        "trabalhadores": len(x["cpfs"]),
        "trabalhadores_especial": len(x["cpfs12"]),
    })
rows.sort(key=lambda r: r["base_especial"], reverse=True)
tot11 = sum(r["base_normal"] for r in rows)
tot12 = sum(r["base_especial"] for r in rows)
json.dump({"competencia": PER, "rows": rows,
           "total_base_normal": round(tot11, 2),
           "total_base_especial": round(tot12, 2),
           "total_adicional": round(tot12 * 0.12, 2)},
          open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

print(f"trabalhadores (dedup): {len(winners)}  | lotacoes: {len(rows)}")
print(f"TOTAL base normal (11)   = {tot11:,.2f}   (oficial 23.562.439,69)")
print(f"TOTAL base especial (12) = {tot12:,.2f}   (oficial 16.553,19)")
print(f"TOTAL adicional 12%      = {tot12*0.12:,.2f}   (oficial cod 1141 = 1.986,38)")
print()
print("Lotacoes COM base de aposentadoria especial (tipo 12):")
print("%-20s %16s %14s %12s %5s"%("lotacao","base normal","base especial","adic.12%","trab"))
for r in rows:
    if r["base_especial"] > 0:
        print("%-20s %16.2f %14.2f %12.2f %5d"%(r["lotacao"],r["base_normal"],r["base_especial"],r["adicional_12pct"],r["trabalhadores_especial"]))
