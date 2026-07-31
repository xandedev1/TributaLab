"""Casamento aproximado (fuzzy) das rubricas da folha 05/2026 com a tabela do portal."""

import json
import re
import subprocess
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path


def norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", str(s))
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", re.sub(r"[^A-Z0-9 ]", "", s.upper())).strip()


def sim(a: str, b: str) -> float:
    return SequenceMatcher(None, a, b).ratio()


def main() -> None:
    out = subprocess.run(
        ["ruby", "bin/rails", "runner",
         "require 'json'; rows = ActiveRecord::Base.connection.select_rows(\"SELECT e.codigo, e.historico, SUM(e.valor) FROM inss_payroll_entries e JOIN inss_payroll_employees emp ON emp.id = e.inss_payroll_employee_id WHERE emp.competencia = '05/2026' GROUP BY e.codigo, e.historico ORDER BY e.codigo\"); puts JSON.generate(rows)"],
        capture_output=True, text=True, cwd=r"C:\Users\xandao\Documents\GitHub\TributaLab",
    )
    rows = json.loads(out.stdout.strip().splitlines()[-1])
    folha = [{"codigo": str(c).strip(), "nome": str(h).strip(), "soma": float(v or 0)} for c, h, v in rows]

    portal = json.loads(Path("storage/private/esocial/appa/rubricas_portal_2026-07-31.json").read_text(encoding="utf-8"))
    vig = {}
    for r in portal:
        if r["fimValid"] != "-":
            continue
        k = norm(r["descricao"])
        if k not in vig or str(r["recepcao"]) > str(vig[k]["recepcao"]):
            vig[k] = r
    portal_keys = list(vig.keys())

    result = []
    for f in folha:
        fn = norm(f["nome"])
        best, best_score = None, 0.0
        if fn in vig:
            best, best_score = vig[fn], 1.0
        else:
            for k in portal_keys:
                s = sim(fn, k)
                if s > best_score:
                    best_score, best = s, vig[k]
        matched = best_score >= 0.80
        result.append({
            **f,
            "incCP": best["incCP"] if matched else None,
            "incIR": best["incIR"] if matched else None,
            "incFGTS": best["incFGTS"] if matched else None,
            "natureza": best["natureza"] if matched else None,
            "portal_descricao": best["descricao"] if matched else None,
            "score": round(best_score, 2),
            "matched": matched,
        })

    Path("tmp/cruzamento_fuzzy_052026.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    matched = [r for r in result if r["matched"]]
    base = [r for r in matched if r["incCP"] == "11"]
    susp = [r for r in matched if r["incCP"] == "95"]
    print(f"Folha: {len(folha)} | casadas(>=0.80): {len(matched)} | incCP=11: {len(base)} | incCP=95: {len(susp)}")

    print("\n=== BASE PATRONAL (incCP=11) — candidatas ao vinculo jun/2026 ===")
    for r in sorted(base, key=lambda x: -x["soma"]):
        print(f"  {r['codigo']:>6} | {r['nome'][:45]:45} | R$ {r['soma']:>12,.2f} | score {r['score']}")

    print("\n=== JA SUSPENSAS (incCP=95) ===")
    for r in susp:
        print(f"  {r['codigo']:>6} | {r['nome'][:45]:45} | R$ {r['soma']:>12,.2f}")

    print("\n=== BAIXA CONFIANCA / NAO CASADAS (revisar) ===")
    for r in result:
        if not r["matched"] or r["score"] < 0.90:
            print(f"  {r['codigo']:>6} | {r['nome'][:40]:40} | ~{r['portal_descricao'] or '—'} | score {r['score']}")


if __name__ == "__main__":
    main()
