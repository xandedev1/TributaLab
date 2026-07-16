#!/usr/bin/env python3

import csv
import importlib.util
import io
import json
import re
import sys
import unicodedata
import zipfile
from collections import defaultdict
from decimal import Decimal
from pathlib import Path
from xml.etree import ElementTree as ET


BASE_SCRIPT = Path(__file__).with_name("analyze_cte_auxilio_doenca_zip.py")
spec = importlib.util.spec_from_file_location("cte_auxilio_base", BASE_SCRIPT)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

DEFAULT_ZIP = base.DEFAULT_ZIP
OUTPUT_DIR = Path("tmp/cte_inventario_rubricas")

EXACT_CODES = ["3302", "3605", "0218", "0213", "0014"]

HEALTH_TERMS = [
    "doenc",
    "atest",
    "licenc",
    "afast",
    "medic",
    "inss",
    "auxilio",
    "aux ",
    "13 aux",
    "13o aux",
    "acidente",
    "previd",
    "saude",
]


def normalize(value):
    value = value or ""
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    return re.sub(r"\s+", " ", value).strip().lower()


def money(value):
    return f"{value.quantize(Decimal('0.01'))}"


def scan(zip_path):
    # code -> aggregation
    agg = defaultdict(lambda: {
        "occurrences": 0,
        "value": Decimal("0"),
        "cpfs": set(),
        "months": set(),
        "years": set(),
        "event_types": set(),
        "descriptions": set(),
    })
    definitions = {}  # code -> set of descriptions from S-1010
    exact_raw_counts = {code: 0 for code in EXACT_CODES}
    exact_variants = {code: defaultdict(int) for code in EXACT_CODES}
    total_rubric_lines = 0
    xml_count = 0

    exact_code_set = set(EXACT_CODES)
    # Also consider non-padded variants like "14" for "0014"
    stripped_map = defaultdict(set)
    for code in EXACT_CODES:
        stripped_map[code].add(code)
        stripped_map[code].add(code.lstrip("0") or "0")

    with zipfile.ZipFile(zip_path) as outer:
        for outer_entry in outer.infolist():
            if not outer_entry.filename.lower().endswith(".zip"):
                continue
            month_zip = base.month_from_zip_name(outer_entry.filename)
            with outer.open(outer_entry) as outer_file:
                inner_bytes = outer_file.read()
            with zipfile.ZipFile(io.BytesIO(inner_bytes)) as inner:
                for xml_entry in inner.infolist():
                    if not xml_entry.filename.lower().endswith(".xml"):
                        continue
                    xml_count += 1
                    event_type = base.event_type_from_name(xml_entry.filename)
                    raw = inner.read(xml_entry)

                    # raw string search for exact codes (any codRubr form)
                    text = raw.decode("utf-8", "ignore")
                    for match in re.findall(r"<[^>]*codRubr[^>]*>([^<]+)<", text):
                        canon = base.canonical_code(match.strip())
                        raw_stripped = match.strip().lstrip("0") or "0"
                        for code in EXACT_CODES:
                            if canon == code or raw_stripped == (code.lstrip("0") or "0"):
                                exact_raw_counts[code] += 1
                                exact_variants[code][match.strip()] += 1

                    try:
                        root = ET.fromstring(raw)
                    except ET.ParseError:
                        continue

                    if event_type == "S-1010":
                        source = {
                            "source_zip": outer_entry.filename,
                            "xml_name": xml_entry.filename,
                            "month_zip": month_zip,
                            "event_type": event_type,
                            "event_node": "",
                            "event_id": "",
                        }
                        for definition in base.collect_rubric_definitions(root, source):
                            if definition["description"]:
                                definitions.setdefault(definition["code"], set()).add(definition["description"])
                        continue

                    if event_type not in ("S-1200", "S-1210", "S-2299", "S-2399"):
                        continue

                    per_apur = base.first_text(root, ["perApur"]) or month_zip
                    year = (per_apur or month_zip or "")[:4]
                    cpf = base.first_text(root, ["cpfTrab", "cpfBenef", "cpfBenefic"])

                    for node, ancestors in base.traverse_with_ancestors(root, []):
                        if base.local_name(node.tag) != "codRubr":
                            continue
                        parent = ancestors[-1] if ancestors else None
                        if parent is None:
                            continue
                        value_text = base.direct_text(parent, "vrRubr")
                        if not value_text:
                            continue
                        total_rubric_lines += 1
                        code = base.canonical_code(node.text or "")
                        bucket = agg[code]
                        bucket["occurrences"] += 1
                        bucket["value"] += base.decimal_value(value_text)
                        if cpf:
                            bucket["cpfs"].add(cpf)
                        if per_apur:
                            bucket["months"].add(per_apur)
                        if year:
                            bucket["years"].add(year)
                        bucket["event_types"].add(event_type)

    for code, descriptions in definitions.items():
        if code in agg:
            agg[code]["descriptions"].update(descriptions)

    return {
        "agg": agg,
        "definitions": definitions,
        "exact_raw_counts": exact_raw_counts,
        "exact_variants": exact_variants,
        "total_rubric_lines": total_rubric_lines,
        "xml_count": xml_count,
    }


def write_csv(path, fieldnames, rows):
    with path.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def main():
    zip_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_ZIP
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    result = scan(zip_path)
    agg = result["agg"]

    inventory_rows = []
    for code, bucket in agg.items():
        descriptions = " | ".join(sorted(bucket["descriptions"]))
        inventory_rows.append({
            "code": code,
            "descriptions": descriptions,
            "occurrences": bucket["occurrences"],
            "distinct_cpfs": len(bucket["cpfs"]),
            "distinct_months": len(bucket["months"]),
            "years": ", ".join(sorted(bucket["years"])),
            "event_types": ", ".join(sorted(bucket["event_types"])),
            "total_value": money(bucket["value"]),
            "_value": bucket["value"],
        })
    inventory_rows.sort(key=lambda row: row["_value"], reverse=True)
    write_csv(
        OUTPUT_DIR / "inventario_rubricas_total.csv",
        ["code", "descriptions", "occurrences", "distinct_cpfs", "distinct_months", "years", "event_types", "total_value"],
        inventory_rows,
    )

    health_rows = [
        row for row in inventory_rows
        if any(term in normalize(row["descriptions"]) for term in HEALTH_TERMS)
    ]
    write_csv(
        OUTPUT_DIR / "rubricas_saude_afastamento.csv",
        ["code", "descriptions", "occurrences", "distinct_cpfs", "distinct_months", "years", "event_types", "total_value"],
        health_rows,
    )

    # per year totals for health rubrics
    year_totals = defaultdict(lambda: {"value": Decimal("0"), "occurrences": 0, "codes": set()})
    health_codes = {row["code"] for row in health_rows}
    for code in health_codes:
        bucket = agg[code]
    # rebuild per-year from months is not stored; approximate using years set only for presence.
    # For accurate per-year we re-derive from inventory: not stored per year. Provide code x year presence instead.

    exact_rows = []
    for code in EXACT_CODES:
        variants = result["exact_variants"][code]
        exact_rows.append({
            "code": code,
            "raw_codRubr_hits": result["exact_raw_counts"][code],
            "variants_encontradas": " | ".join(f"{value}:{count}" for value, count in sorted(variants.items())) or "(nenhuma)",
            "em_agregado_com_valor": agg.get(code, {}).get("occurrences", 0),
            "descricao_s1010": " | ".join(sorted(result["definitions"].get(code, []))) or "(sem definicao S-1010)",
        })
    write_csv(
        OUTPUT_DIR / "checagem_codigos_exatos.csv",
        ["code", "raw_codRubr_hits", "variants_encontradas", "em_agregado_com_valor", "descricao_s1010"],
        exact_rows,
    )

    summary = {
        "zip_path": str(zip_path),
        "xml_count": result["xml_count"],
        "total_rubric_lines_com_valor": result["total_rubric_lines"],
        "distinct_codes": len(agg),
        "health_codes": len(health_rows),
        "exact_codes_raw_hits": result["exact_raw_counts"],
        "top_health": [
            {"code": row["code"], "descricao": row["descriptions"], "anos": row["years"], "total": row["total_value"]}
            for row in health_rows[:15]
        ],
    }
    (OUTPUT_DIR / "inventario_summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
