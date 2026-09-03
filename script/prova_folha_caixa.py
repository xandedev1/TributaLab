import json, glob, os, openpyxl, re, unicodedata
BASE = r"storage\private\fiscal_auditor\appa"
d = json.load(open(os.path.join(BASE, "detalhe_clientes_deficit.json"), encoding="utf-8"))["263"]
mn = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
venc = d["folha_mes_venc"]; desc = d["folha_mes_desc"]
print("=== CAIXA (cod 263) folha por mes ===")
for i in range(12):
    if venc[i] or desc[i]:
        print(f"  {mn[i]}: venc={venc[i]:14.2f}  desc={desc[i]:12.2f}")
# rubricas que aparecem em mar e abr-ago
print("\n=== TOP rubricas de MARÇO (idx 2) ===")
vr = [r for r in d["folha_rubricas"] if r["tipo"] == "Vencimento"]
for r in sorted(vr, key=lambda r: -r["mes"][2])[:12]:
    if r["mes"][2]:
        print(f"  {r['codigo']:>5} {r['desc'][:44]:44} mar={r['mes'][2]:12.2f}")
print("\n=== rubricas presentes ABR-AGO (residual pos-contrato) ===")
for r in sorted(vr, key=lambda r: -sum(r['mes'][3:8])):
    resid = sum(r["mes"][3:8])
    if resid > 0:
        meses = ",".join(mn[i] for i in range(3, 8) if r["mes"][i] > 0)
        print(f"  {r['codigo']:>5} {r['desc'][:40]:40} total_abr_ago={resid:11.2f}  ({meses})")
# fonte
def norm(s):
    s = unicodedata.normalize("NFKD", str(s)).encode("ascii", "ignore").decode().lower(); return re.sub(r"[^a-z0-9]+", " ", s).strip()
print("\n=== arquivo(s) fonte com cod 263 ===")
for f in glob.glob(os.path.join(BASE, "payroll", "*.xlsx")):
    wb = openpyxl.load_workbook(f, read_only=True, data_only=True); ws = wb.active
    found = False
    for row in ws.iter_rows(values_only=True):
        if row and len(row) > 4 and str(row[0]).strip().rstrip(".0") == "263" and row[4] in ("Vencimento", "Desconto"):
            found = True; break
    if found:
        print("  ", os.path.basename(f))
    wb.close()
