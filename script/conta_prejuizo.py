import json
d = json.load(open(r"storage\private\fiscal_auditor\appa\cruzamento_cliente.json", encoding="utf-8"))["rows"]
m = json.load(open(r"storage\private\fiscal_auditor\appa\cruzamento_resultado.json", encoding="utf-8"))["rows"]
enc = (sum(r["inss_empregador"] for r in m) + sum(r["fgts"] for r in m)) / sum(r["folha_vencimentos"] for r in m)
piores = []
for r in d:
    fat = r["faturamento"]; fol = r["folha"]
    if fat <= 0:
        continue
    marg = (fat - fol * (1 + enc)) / fat * 100
    piores.append((marg, r))
piores.sort(key=lambda x: x[0])
abaixo = [p for p in piores if p[0] < -100]
abaixo_rel = [p for p in abaixo if p[1]["faturamento"] >= 50000]
print(f"encargo aplicado = {enc*100:.1f}%")
print(f"contratos com prejuizo > 100% (margem < -100%): {len(abaixo)} de {len(piores)} com faturamento")
print(f"  destes, com faturamento >= 50 mil: {len(abaixo_rel)}")
print()
print("%-40s %13s %13s %8s" % ("cliente", "faturamento", "folha", "margem"))
for marg, r in abaixo:
    print("%-40s %13.0f %13.0f %7.0f%%" % (r["cliente"][:40] or r["client_code"], r["faturamento"], r["folha"], marg))
