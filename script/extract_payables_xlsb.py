import json
import sys
import unicodedata
from decimal import Decimal

from pyxlsb import convert_date, open_workbook


COMPETENCE_IDENTIFICATIONS = {
    "FUNCIONARIOS": {"despesas folha"},
    "FORNECEDORES": {
        "despesas financeiras",
        "despesas folha",
        "despesas gerais",
        "tributos",
    },
}

SHEET_COLUMNS = {
    "FUNCIONARIOS": {
        "due_date": 0,
        "party": 2,
        "description": 4,
        "amount": 6,
        "payment_date": 7,
        "identification": 8,
        "client": 1,
        "document": None,
    },
    "FORNECEDORES": {
        "due_date": 0,
        "party": 4,
        "description": 6,
        "amount": 7,
        "payment_date": 8,
        "identification": 9,
        "client": None,
        "document": 3,
    },
}


def normalize(value):
    text = unicodedata.normalize("NFKD", str(value or ""))
    return " ".join(
        "".join(char for char in text if not unicodedata.combining(char)).lower().split()
    )


def text(value):
    if value is None:
        return ""
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value).strip()


def excel_date(value):
    if not isinstance(value, (int, float)) or value <= 20_000:
        return None
    return convert_date(value).date().isoformat()


def decimal(value):
    if not isinstance(value, (int, float)):
        return None
    return format(Decimal(str(value)), "f")


def cell(values, index):
    return values[index] if index is not None and index < len(values) else None


def extract(path):
    records = []
    with open_workbook(path) as workbook:
        for sheet_name, columns in SHEET_COLUMNS.items():
            with workbook.get_sheet(sheet_name) as sheet:
                for source_row, row in enumerate(sheet.rows(), start=1):
                    if source_row == 1:
                        continue

                    values = [item.v for item in row]
                    amount = decimal(cell(values, columns["amount"]))
                    payment_date = excel_date(cell(values, columns["payment_date"]))
                    identification = text(cell(values, columns["identification"]))
                    if amount is None or Decimal(amount) == 0 or not payment_date or not identification:
                        continue

                    normalized_identification = normalize(identification)
                    records.append(
                        {
                            "source_sheet": sheet_name,
                            "source_row": source_row,
                            "due_date": excel_date(cell(values, columns["due_date"])),
                            "payment_date": payment_date,
                            "party": text(cell(values, columns["party"])),
                            "client": text(cell(values, columns["client"])),
                            "document": text(cell(values, columns["document"])),
                            "description": text(cell(values, columns["description"])),
                            "identification": identification,
                            "competence_expense": normalized_identification
                            in COMPETENCE_IDENTIFICATIONS[sheet_name],
                            "amount": amount,
                        }
                    )
    return records


json.dump(extract(sys.argv[1]), sys.stdout, ensure_ascii=False, separators=(",", ":"))