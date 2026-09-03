#!/usr/bin/env python3
"""Procura nomes (nmTrab) dos CPFs com base especial, varrendo os eventos de cadastro."""
import zipfile, re, glob, os, json

CPFS = {"00857079700", "14884150724", "67314244715", "16155166706", "20947557709", "07049597805"}
BASE = r"C:\Users\xandao\Downloads\appa tabela gerais\todos eventos APPA 2025"
nm_re = re.compile(r"<cpfTrab>(\d+)</cpfTrab>.*?<nmTrab>([^<]+)</nmTrab>", re.S)
nm_re2 = re.compile(r"<nmTrab>([^<]+)</nmTrab>.*?<cpfTrab>(\d+)</cpfTrab>", re.S)
found = {}
for zp in glob.glob(os.path.join(BASE, "*.zip")):
    if len(found) == len(CPFS):
        break
    with zipfile.ZipFile(zp) as zf:
        for name in zf.namelist():
            if not name.lower().endswith(".xml"):
                continue
            d = zf.read(name).decode("utf-8", "replace")
            if "nmTrab" not in d:
                continue
            for cpf, nm in nm_re.findall(d):
                if cpf in CPFS and cpf not in found:
                    found[cpf] = nm.strip()
            for nm, cpf in nm_re2.findall(d):
                if cpf in CPFS and cpf not in found:
                    found[cpf] = nm.strip()
for c in sorted(CPFS):
    print(c, "->", found.get(c, "(nao encontrado)"))
json.dump(found, open(r"storage\private\fiscal_auditor\appa\nomes_especial.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)
