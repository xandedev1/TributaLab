"""Cruza rubricas da folha set/2025 com a tabela de incidencias do portal eSocial."""

import json
import re
import unicodedata
from pathlib import Path

import openpyxl


def norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", str(s))
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", re.sub(r"[^A-Z0-9 ]", "", s.upper())).strip()


def main() -> None:
    # 1. Folha 05/2026 do banco (inss_payroll_entries): codigo + historico + soma
    import subprocess
    out = subprocess.run(
        ["ruby", "bin/rails", "runner",
         "require 'json'; rows = ActiveRecord::Base.connection.select_rows(\"SELECT e.codigo, e.historico, SUM(e.valor) FROM inss_payroll_entries e JOIN inss_payroll_employees emp ON emp.id = e.inss_payroll_employee_id WHERE emp.competencia = '05/2026' GROUP BY e.codigo, e.historico ORDER BY e.codigo\"); puts JSON.generate(rows)"],
        capture_output=True, text=True, cwd=r"C:\Users\xandao\Documents\GitHub\TributaLab",
    )
    rows = json.loads(out.stdout.strip().splitlines()[-1])
    folha = sorted(
        [{"codigo": str(c).strip(), "nome": str(h).strip(), "natureza_folha": "", "soma": float(v or 0)} for c, h, v in rows],
        key=lambda x: x["codigo"],
    )
    print(f"Folha 05/2026: {len(folha)} codigos")

    # 2. Portal: vigentes (fimValid '-') mais recentes por descricao normalizada
    portal = json.loads(Path("storage/private/esocial/appa/rubricas_portal_2026-07-31.json").read_text(encoding="utf-8"))
    vig = [r for r in portal if r["fimValid"] == "-"]
    by_norm: dict[str, dict] = {}
    for r in vig:
        k = norm(r["descricao"])
        if k not in by_norm or str(r["recepcao"]) > str(by_norm[k]["recepcao"]):
            by_norm[k] = r

    # 3. Cruzamento
    cruzado = []
    for f in folha:
        p = by_norm.get(norm(f["nome"]))
        cruzado.append({
            **f,
            "portal_descricao": p.get("descricao") if p else None,
            "natureza": p.get("natureza") if p else None,
            "incCP": p.get("incCP") if p else None,
            "incIR": p.get("incIR") if p else None,
            "incFGTS": p.get("incFGTS") if p else None,
            "idRubrica": p.get("idRubrica") if p else None,
            "matched": p is not None,
        })

    matched = [c for c in cruzado if c["matched"]]
    base = [c for c in matched if c["incCP"] == "11"]
    susp = [c for c in matched if c["incCP"] == "95"]

    Path("tmp/cruzamento_rubricas_set2025.json").write_text(
        json.dumps(cruzado, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"Cruzadas: {len(matched)}/{len(folha)}")
    print(f"incCP=11 (base patronal): {len(base)}")
    print(f"incCP=95 (ja suspensas): {len(susp)}")

    print("\n=== BASE PATRONAL (incCP=11) — candidatas ao vinculo jun/2026 ===")
    for c in base:
        print(f"  {c['codigo']} | {c['nome'][:50]} | nat {c['natureza']} | R$ {c['soma']:.2f}")

    print("\n=== JA SUSPENSAS (incCP=95) — modelo do que foi feito em set/2025 ===")
    for c in susp:
        print(f"  {c['codigo']} | {c['nome'][:50]} | nat {c['natureza']} | R$ {c['soma']:.2f}")

    print("\n=== NAO CRUZADAS ===")
    for c in cruzado:
        if not c["matched"]:
            print(f"  {c['codigo']} | {c['nome'][:60]}")


if __name__ == "__main__":
    main()
