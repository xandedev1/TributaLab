#!/usr/bin/env python3
"""Lista os CPFs com base de aposentadoria especial (tipo 12) na competencia 2025-01."""
import zipfile, re

Z = r"C:\Users\xandao\Downloads\appa tabela gerais\todos eventos APPA 2025\fevereiro.zip"
PER = "2025-01"
evt_re = re.compile(r'<evtBasesTrab Id="([^"]+)">(.*?)</evtBasesTrab>', re.S)
per_re = re.compile(r"<perApur>(.*?)</perApur>")
cpf_re = re.compile(r"<cpfTrab>(\d+)</cpfTrab>")
lot_re = re.compile(r"<ideEstabLot>(.*?)</ideEstabLot>", re.S)
cod_re = re.compile(r"<codLotacao>(.*?)</codLotacao>")
mat_re = re.compile(r"<matricula>(.*?)</matricula>")
bcs_re = re.compile(r"<infoBaseCS><ind13>(\d)</ind13><tpValor>(\d+)</tpValor><valor>([\d.]+)</valor>")

winners = {}
with zipfile.ZipFile(Z) as zf:
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

regs = []
for cpf, (mid, body) in winners.items():
    for lb in lot_re.findall(body):
        cod = cod_re.search(lb); mat = mat_re.search(lb)
        b11 = b12 = 0.0
        for ind13, tp, val in bcs_re.findall(lb):
            if ind13 != "0":
                continue
            if tp == "12":
                b12 += float(val)
            elif tp == "11":
                b11 += float(val)
        if b12 > 0:
            regs.append((cod.group(1) if cod else "?", cpf, mat.group(1) if mat else "", b11, b12, b12 * 0.12))

regs.sort(key=lambda r: -r[4])
mask = lambda c: f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:]}"
print("%-18s %-16s %-20s %13s %10s %8s" % ("lotacao", "CPF", "matricula", "base normal", "base esp.", "adic12%"))
for cod, cpf, mat, b11, b12, ad in regs:
    print("%-18s %-16s %-20s %13.2f %10.2f %8.2f" % (cod, mask(cpf), mat, b11, b12, ad))
print()
print("trabalhadores com base especial:", len(regs))
print("total base especial:", round(sum(r[4] for r in regs), 2), "| total adicional 12%:", round(sum(r[5] for r in regs), 2))

import json
out = [{"lotacao": cod, "cpf": mask(cpf), "matricula": mat, "base_especial": round(b12, 2),
        "adicional_12pct": round(ad, 2)} for cod, cpf, mat, b11, b12, ad in regs]
json.dump({"competencia": PER, "trabalhadores": out}, open(r"storage\private\fiscal_auditor\appa\cpfs_especial_2025-01.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)
