import json
import re
import sys
import unicodedata
from decimal import Decimal

from pyxlsb import convert_date, open_workbook


def normalize(value):
    text = unicodedata.normalize("NFKD", str(value or ""))
    return " ".join("".join(char for char in text if not unicodedata.combining(char)).lower().split())


def excel_date(value):
    if not isinstance(value, (int, float)) or value <= 20_000:
        return None
    return convert_date(value).date().isoformat()


def identifier(value):
    if value is None:
        return None
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    text = str(value).strip()
    return text or None


def decimal(value):
    if not isinstance(value, (int, float)):
        return "0"
    return format(Decimal(str(value)), "f")


def client_code(client, fallback):
    match = re.match(r"\s*(\d+)", str(client or ""))
    return match.group(1) if match else identifier(fallback)


def extract(path):
    records = []
    with open_workbook(path) as workbook:
        with workbook.get_sheet("APPA") as sheet:
            rows = sheet.rows()
            headers = None
            for row in rows:
                values = [cell.v for cell in row]
                normalized = [normalize(value) for value in values]
                if "dt de emissao" in normalized and "valor real pago" in normalized:
                    headers = {name: index for index, name in enumerate(normalized) if name}
                    break

            required = {
                "cod.", "cliente", "centro de custo", "nf", "rps", "dt de emissao",
                "banco", "comp.", "status", "valor bruto", "valor contigenciamento",
                "valor a receber", "valor real pago", "data"
            }
            if headers is None or not required.issubset(headers):
                missing = sorted(required - set(headers or {}))
                raise ValueError(f"Required APPA headers not found: {', '.join(missing)}")

            def value(values, name):
                index = headers[name]
                return values[index] if index < len(values) else None

            for source_row, row in enumerate(rows, start=3):
                values = [cell.v for cell in row]
                emission_date = excel_date(value(values, "dt de emissao"))
                invoice_number = identifier(value(values, "nf"))
                client = str(value(values, "cliente") or "").strip()
                if not emission_date or not invoice_number or not client:
                    continue

                raw_outstanding = value(values, "valor a receber")
                records.append({
                    "source_row": source_row,
                    "client_code": client_code(client, value(values, "cod.")),
                    "client": client,
                    "cost_center": str(value(values, "centro de custo") or "").strip(),
                    "invoice_number": invoice_number,
                    "rps": identifier(value(values, "rps")),
                    "emission_date": emission_date,
                    "bank": str(value(values, "banco") or "").strip(),
                    "competence": excel_date(value(values, "comp.")),
                    "competence_text": identifier(value(values, "comp.")),
                    "status": str(value(values, "status") or "").strip(),
                    "gross": decimal(value(values, "valor bruto")),
                    "contingency": decimal(value(values, "valor contigenciamento")),
                    "outstanding": decimal(raw_outstanding),
                    "reconciliation_status": str(raw_outstanding).strip() if isinstance(raw_outstanding, str) else "",
                    "paid": decimal(value(values, "valor real pago")),
                    "payment_date": excel_date(value(values, "data"))
                })
    return records


json.dump(extract(sys.argv[1]), sys.stdout, ensure_ascii=False, separators=(",", ":"))