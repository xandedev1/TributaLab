#!/usr/bin/env python3
"""Extrai TODOS os campos da(s) nota(s) de um cliente/competencia para detalhamento linha a linha."""
import openpyxl, glob, os, re, json, unicodedata, sys

BASE = r"storage\private\fiscal_auditor\appa"
COD = sys.argv[1] if len(sys.argv) > 1 else "263"
ANO = 2025

def ident(v):
    if v is None:
        return None
    s = str(v).strip()
    return s[:-2] if s.endswith(".0") else (s or None)

def norm(s):
    s = unicodedata.normalize("NFKD", str(s)).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", s).strip()

notas = []
for f in glob.glob(os.path.join(BASE, "source", "**", "*.xlsx"), recursive=True):
    if "RETEN" not in os.path.basename(f).upper():
        continue
    wb = openpyxl.load_workbook(f, read_only=True, data_only=True); ws = wb.active
    header = None; ccidx = None; compidx = None
    for row in ws.iter_rows(values_only=True):
        if header is None:
            if row and any(isinstance(c, str) and norm(c) == "cnpj cliente" for c in row):
                header = [str(c).strip() if c is not None else "" for c in row]
                for i, c in enumerate(header):
                    n = norm(c)
                    if n in ("cod cliente", "cd cliente", "cleinte"): ccidx = i
                    if "competencia" in n: compidx = i
            continue
        if ccidx is None:
            continue
        cc = ident(row[ccidx]) if ccidx < len(row) else None
        if cc != COD:
            continue
        comp = row[compidx] if compidx is not None and compidx < len(row) else None
        if not (hasattr(comp, "year") and comp.year == ANO):
            continue
        fields = []
        for i, name in enumerate(header):
            if not name:
                continue
            v = row[i] if i < len(row) else None
            if hasattr(v, "strftime"):
                v = v.strftime("%d/%m/%Y")
            fields.append([name, "" if v is None else (str(v).strip())])
        notas.append({"arquivo": os.path.basename(f), "campos": fields})
    wb.close()

json.dump({"cod": COD, "notas": notas}, open(os.path.join(BASE, f"nota_detalhe_{COD}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"notas encontradas para cod {COD}: {len(notas)}")
for n in notas:
    print("--- arquivo:", n["arquivo"])
    for k, v in n["campos"]:
        print(f"   {k:32} = {v}")
