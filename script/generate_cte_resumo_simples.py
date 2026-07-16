#!/usr/bin/env python3

import csv
import importlib.util
from datetime import datetime
from pathlib import Path


BASE = Path(__file__).with_name("generate_cte_auxilio_doenca_final_report.py")
spec = importlib.util.spec_from_file_location("cte_final", BASE)
final = importlib.util.module_from_spec(spec)
spec.loader.exec_module(final)

RELATED_CSV = Path("tmp/cte_auxilio_doenca_related_report/rubricas_auxilio_doenca_por_codigo.csv")
OUTPUT_DIR = Path("tmp/relatorio_cte_auxilio_doenca_final")
CSV_PATH = OUTPUT_DIR / "resumo_simples_cte.csv"
XLSX_PATH = OUTPUT_DIR / "resumo_simples_cte.xlsx"
PDF_PATH = OUTPUT_DIR / "resumo_simples_cte.pdf"

# Cada codigo da folha da cliente e a(s) rubrica(s) reais no eSocial da CTE.
# Valores somados por linha para nao esconder nenhum ano.
MAPPING = [
    ("3302", "Complement Auxilio Doenca", ["SECTECENT200000000000000000289", "SECTECENT200000000000000000288"]),
    ("3605", "Complement Auxilio Doenca", ["SECTECENT200000000000000000258", "8870", "9505"]),
    ("0218", "Desc adto Auxilio doenca", ["SECTECENT200000000000000000291"]),
    ("0213", "Dias Lic. Medica ate 15d", ["SECTECENT200000000000000000205"]),
    ("0014", "Hrs Atestado ate 15 dias", ["SECTECENT200000000000000000003", "SECTECENT200000000000000000199"]),
]


def read_related():
    with RELATED_CSV.open("r", encoding="utf-8-sig", newline="") as file:
        return {row["code"]: row for row in csv.DictReader(file)}


def money_br(value):
    number = float(str(value or "0"))
    return "R$ " + f"{number:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def short(code):
    return code[:10] + "..." if code.startswith("SECTECENT") else code


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    related = read_related()

    rows = []
    total = 0.0
    for folha_code, descricao, esocial_codes in MAPPING:
        occurrences = 0
        months = set()
        value = 0.0
        used_codes = []
        for esocial_code in esocial_codes:
            data = related.get(esocial_code, {})
            occurrences += int(data.get("occurrences", 0) or 0)
            value += float(data.get("total_vr_rubr", 0) or 0)
            month_list = (data.get("months", "") or "").split(", ")
            months.update(month for month in month_list if month)
            used_codes.append(esocial_code)
        total += value
        rows.append({
            "codigo": folha_code,
            "descricao": descricao,
            "rubrica_esocial": "; ".join(short(code) for code in used_codes),
            "vezes_apareceu": occurrences,
            "qtd_meses": len(months),
            "valor_total": f"{value:.2f}",
            "valor_total_br": money_br(value),
        })

    # CSV simples
    with CSV_PATH.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.writer(file)
        writer.writerow(["Codigo", "Descricao", "Rubrica eSocial CTE", "Vezes que apareceu", "Qtd de meses", "Valor total"])
        for row in rows:
            writer.writerow([row["codigo"], row["descricao"], row["rubrica_esocial"], row["vezes_apareceu"], row["qtd_meses"], row["valor_total_br"]])
        writer.writerow(["", "", "TOTAL", "", "", money_br(total)])

    # XLSX simples (uma aba)
    sheet_rows = [[row["codigo"], row["descricao"], row["rubrica_esocial"], row["vezes_apareceu"], row["qtd_meses"], row["valor_total"]] for row in rows]
    sheet_rows.append(["", "", "TOTAL", "", "", f"{total:.2f}"])
    sheets = [(
        "Resumo",
        ["Codigo", "Descricao", "Rubrica eSocial", "Vezes que apareceu", "Qtd de meses", "Valor total (R$)"],
        sheet_rows,
    )]
    final.make_xlsx(XLSX_PATH, sheets)

    # PDF simples (uma pagina)
    pdf = final.PdfDocument(PDF_PATH)
    pdf.text("Resumo - CTE - Auxilio Doenca / Atestado / Licenca Medica", size=15, bold=True)
    pdf.text(f"Gerado em {datetime.now().strftime('%d/%m/%Y %H:%M')}", size=9)
    pdf.y -= 6
    pdf.paragraph("Observacao: os codigos 3302, 3605, 0218, 0213 e 0014 sao do sistema de folha e nao existem no eSocial (0 ocorrencia em 65.494 XMLs). A coluna 'Rubrica eSocial' e a rubrica real equivalente da CTE, de onde vem os numeros.", size=9)
    pdf.y -= 4

    header = ["Codigo", "Descricao", "Vezes", "Meses", "Valor total"]
    table_rows = [[row["codigo"], row["descricao"], str(row["vezes_apareceu"]), str(row["qtd_meses"]), money_br(float(row["valor_total"]))] for row in rows]
    table_rows.append(["", "TOTAL", "", "", money_br(total)])
    pdf.table(header, table_rows, [8, 34, 7, 7, 18], size=10)
    pdf.save()

    print(f"CSV : {CSV_PATH}")
    print(f"XLSX: {XLSX_PATH}")
    print(f"PDF : {PDF_PATH}")
    print(f"TOTAL: {money_br(total)}")


if __name__ == "__main__":
    main()
