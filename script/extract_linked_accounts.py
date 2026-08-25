"""Extract EXTRATO CONTA VINCULADA to JSON for the Fiscal Auditor dashboard."""

import json
import sys
from pathlib import Path

import openpyxl


def extract(source: Path) -> list[dict]:
    wb = openpyxl.load_workbook(str(source), data_only=True)
    ws = wb["Planilha3"]
    rows = []
    for r in ws.iter_rows(min_row=3, values_only=True):
        if r[0] is None:
            continue
        rows.append({
            "codigo": r[0],
            "uf": str(r[1]).strip() if r[1] else None,
            "cliente": str(r[2]).strip() if r[2] else None,
            "contrato": str(r[3]).strip() if r[3] else None,
            "banco": str(r[4]).strip() if r[4] else None,
            "conta": str(r[5]).strip() if r[5] else None,
            "saldo_jan": r[6] if isinstance(r[6], (int, float)) else None,
            "saldo_mai": r[7] if isinstance(r[7], (int, float)) else None,
            "status": str(r[8]).strip() if r[8] else None,
            "obs": str(r[9]).strip() if r[9] else None,
        })
    return rows


def summarize(rows: list[dict]) -> None:
    ativos = [r for r in rows if r["status"] and "ATIVO" in r["status"].upper()]
    encerrados = [r for r in rows if r["status"] and "ENCERRADO" in r["status"].upper()]
    saldos_mai = [r["saldo_mai"] for r in rows if r["saldo_mai"]]
    saldos_jan = [r["saldo_jan"] for r in rows if r["saldo_jan"]]
    enc_saldo = [r for r in encerrados if r["saldo_mai"] and r["saldo_mai"] > 0]
    sem_conta = [r for r in rows if not r["conta"]]
    sem_saldo = [r for r in rows if not r["saldo_mai"]]

    print(f"Total contratos: {len(rows)}")
    print(f"Ativos: {len(ativos)} | Encerrados: {len(encerrados)}")
    print(f"Saldo jan/2026: R$ {sum(saldos_jan):,.2f} ({len(saldos_jan)} com valor)")
    print(f"Saldo mai/2026: R$ {sum(saldos_mai):,.2f} ({len(saldos_mai)} com valor)")
    print(f"Encerrados com saldo: {len(enc_saldo)} contratos, R$ {sum(r['saldo_mai'] for r in enc_saldo):,.2f}")
    print(f"Sem conta vinculada: {len(sem_conta)}")
    print(f"Sem saldo mai: {len(sem_saldo)}")

    sorted_rows = sorted([r for r in rows if r["saldo_mai"]], key=lambda x: -(x["saldo_mai"] or 0))
    print("--- Top 10 maiores saldos mai ---")
    for r in sorted_rows[:10]:
        saldo = r["saldo_mai"] or 0
        print(f"  {r['codigo']} {r['cliente'][:55]} [{r['status']}] R$ {saldo:,.2f}")

    print("--- Sem conta vinculada ---")
    for r in sem_conta:
        print(f"  {r['codigo']} {r['cliente'][:55]} [{r['status']}] saldo_mai={r['saldo_mai']}")


def main() -> None:
    # Windows stdout defaults to cp1252 and crashes on chars like U+2713 present in the data.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / "Downloads" / "EXTRATO CONTA VINCULADA.xlsx"
    output = Path("tmp/extrato_conta_vinculada.json")
    output.parent.mkdir(parents=True, exist_ok=True)

    rows = extract(source)
    with open(output, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)

    print(f"{len(rows)} linhas extraidas para {output}")
    summarize(rows)


if __name__ == "__main__":
    main()
