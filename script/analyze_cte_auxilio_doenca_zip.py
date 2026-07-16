#!/usr/bin/env python3

import csv
import io
import json
import re
import sys
import unicodedata
import zipfile
from collections import Counter, defaultdict
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path
from xml.etree import ElementTree as ET


DEFAULT_ZIP = Path(r"C:\Users\xandao\Downloads\CTE-TODOS-EVENTOS-XML.zip")
DEFAULT_OUTPUT_DIR = Path("tmp/cte_auxilio_doenca_report")

TARGET_RUBRICS = {
    "3302": "Complement Auxilio Doenca",
    "3605": "Complement Auxilio Doenca",
    "0218": "Desc adto Auxilio doenca",
    "0213": "Dias Lic. Medica ate 15d",
    "0014": "Hrs Atestado ate 15 dias",
}

DESCRIPTION_NEEDLES = [normalize for normalize in []]


def normalize_text(value):
    value = value or ""
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    return re.sub(r"\s+", " ", value).strip().lower()


DESCRIPTION_NEEDLES = [normalize_text(value) for value in TARGET_RUBRICS.values()]

# Se definido como um conjunto (ex.: {"S-1200"}), a coleta de itens considera
# apenas esses tipos de evento. None significa considerar todos os eventos.
ITEM_EVENT_TYPES = None
DESCRIPTION_CANDIDATE_NEEDLES = [
    "auxilio doenca",
    "doenca",
    "lic medica",
    "licenca medica",
    "atestado",
]


def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def direct_child(element, name):
    for child in list(element):
        if local_name(child.tag) == name:
            return child
    return None


def direct_text(element, name):
    child = direct_child(element, name)
    return (child.text or "").strip() if child is not None else ""


def first_text(element, names):
    wanted = set(names)
    for child in element.iter():
        if local_name(child.tag) in wanted and child.text:
            return child.text.strip()
    return ""


def first_event_id(element):
    for child in element.iter():
        event_id = child.attrib.get("Id")
        if event_id:
            return event_id
    return ""


def event_node_name(element):
    for child in element.iter():
        name = local_name(child.tag)
        if name.startswith("evt"):
            return name
    return local_name(element.tag)


def event_type_from_name(name):
    match = re.search(r"\.S-(\d{4})\.xml$", name, re.IGNORECASE)
    return f"S-{match.group(1)}" if match else ""


def month_from_zip_name(name):
    match = re.search(r"/(\d{2})-(\d{4})\.zip$", name.replace("\\", "/"))
    if not match:
        return ""
    month, year = match.groups()
    return f"{year}-{month}"


def decimal_value(value):
    if value is None:
        return Decimal("0")
    text = str(value).strip().replace(".", "").replace(",", ".") if "," in str(value) else str(value).strip()
    try:
        return Decimal(text)
    except InvalidOperation:
        return Decimal("0")


def money(value):
    return f"{value.quantize(Decimal('0.01'))}"


def canonical_code(code):
    code = (code or "").strip()
    return code.zfill(4) if code.isdigit() else code


def period_key(period):
    if not period:
        return "9999-99"
    match = re.match(r"^(\d{4})-(\d{2})", period)
    return match.group(0) if match else period


def valid_for_period(definition, period):
    period = period_key(period)
    ini = period_key(definition.get("ini_valid", ""))
    fim = period_key(definition.get("fim_valid", ""))
    if ini and ini != "9999-99" and period < ini:
        return False
    if fim and fim != "9999-99" and period > fim:
        return False
    return True


def choose_definition(catalog_by_code, code, ide_tab_rubr, period):
    candidates = catalog_by_code.get(code, [])
    if ide_tab_rubr:
        matched_table = [item for item in candidates if item.get("ide_tab_rubr") == ide_tab_rubr]
        candidates = matched_table or candidates
    valid = [item for item in candidates if valid_for_period(item, period)]
    candidates = valid or candidates
    if not candidates:
        return {}
    return sorted(candidates, key=lambda item: item.get("ini_valid", ""), reverse=True)[0]


def signed_value(code, value, definition):
    tp_rubr = definition.get("tp_rubr", "")
    if tp_rubr in {"2", "4"}:
        return -value
    if code == "0218" and not tp_rubr:
        return -value
    return value


def operation_nodes(root):
    for node in root.iter():
        if local_name(node.tag) in {"inclusao", "alteracao", "exclusao"}:
            yield node


def collect_rubric_definitions(root, source):
    definitions = []
    for operation in operation_nodes(root):
        ide = direct_child(operation, "ideRubrica")
        if ide is None:
            continue
        code = canonical_code(direct_text(ide, "codRubr"))
        if not code:
            continue

        data = direct_child(operation, "dadosRubrica")
        definitions.append(
            {
                "code": code,
                "raw_code": direct_text(ide, "codRubr"),
                "ide_tab_rubr": direct_text(ide, "ideTabRubr"),
                "ini_valid": direct_text(ide, "iniValid"),
                "fim_valid": direct_text(ide, "fimValid"),
                "operation": local_name(operation.tag),
                "description": direct_text(data, "dscRubr") if data is not None else "",
                "nat_rubr": direct_text(data, "natRubr") if data is not None else "",
                "tp_rubr": direct_text(data, "tpRubr") if data is not None else "",
                "cod_inc_cp": direct_text(data, "codIncCP") if data is not None else "",
                "cod_inc_fgts": direct_text(data, "codIncFGTS") if data is not None else "",
                "cod_inc_irrf": direct_text(data, "codIncIRRF") if data is not None else "",
                "source_zip": source["source_zip"],
                "xml_name": source["xml_name"],
                "event_id": source["event_id"],
            }
        )
    return definitions


def nearest_text(ancestors, names):
    wanted = set(names)
    for ancestor in reversed(ancestors):
        for child in list(ancestor):
            if local_name(child.tag) in wanted and child.text:
                return child.text.strip()
    return ""


def traverse_with_ancestors(element, ancestors):
    yield element, ancestors
    next_ancestors = ancestors + [element]
    for child in list(element):
        yield from traverse_with_ancestors(child, next_ancestors)


def collect_rubric_items(root, source):
    items = []
    references = []
    per_apur = first_text(root, ["perApur"]) or source["month_zip"]
    cpf = first_text(root, ["cpfTrab", "cpfBenef", "cpfBenefic"])
    matricula = first_text(root, ["matricula"])

    for node, ancestors in traverse_with_ancestors(root, []):
        if local_name(node.tag) != "codRubr":
            continue
        code = canonical_code(node.text or "")
        if code not in TARGET_RUBRICS:
            continue

        parent = ancestors[-1] if ancestors else None
        parent_name = local_name(parent.tag) if parent is not None else ""
        value_text = direct_text(parent, "vrRubr") if parent is not None else ""
        reference = {
            "code": code,
            "event_type": source["event_type"],
            "event_node": source["event_node"],
            "source_zip": source["source_zip"],
            "xml_name": source["xml_name"],
            "has_vr_rubr": bool(value_text),
            "parent_node": parent_name,
        }
        references.append(reference)
        if not value_text:
            continue

        value = decimal_value(value_text)
        items.append(
            {
                "per_apur": per_apur,
                "month_zip": source["month_zip"],
                "event_type": source["event_type"],
                "event_node": source["event_node"],
                "event_id": source["event_id"],
                "cpf": cpf,
                "matricula": matricula,
                "ide_dm_dev": nearest_text(ancestors, ["ideDmDev"]),
                "code": code,
                "expected_description": TARGET_RUBRICS[code],
                "raw_code": (node.text or "").strip(),
                "ide_tab_rubr": direct_text(parent, "ideTabRubr") if parent is not None else "",
                "qtd_rubr": direct_text(parent, "qtdRubr") if parent is not None else "",
                "fator_rubr": direct_text(parent, "fatorRubr") if parent is not None else "",
                "vr_rubr": value,
                "parent_node": parent_name,
                "source_zip": source["source_zip"],
                "xml_name": source["xml_name"],
            }
        )
    return items, references


def scan_zip(zip_path):
    event_counts = Counter()
    parse_errors = []
    definitions = []
    items = []
    references = []
    inner_zip_count = 0
    xml_count = 0

    with zipfile.ZipFile(zip_path) as outer:
        inner_entries = [entry for entry in outer.infolist() if entry.filename.lower().endswith(".zip")]
        inner_zip_count = len(inner_entries)
        for outer_entry in inner_entries:
            month_zip = month_from_zip_name(outer_entry.filename)
            with outer.open(outer_entry) as outer_file:
                inner_bytes = outer_file.read()
            with zipfile.ZipFile(io.BytesIO(inner_bytes)) as inner:
                for xml_entry in inner.infolist():
                    if not xml_entry.filename.lower().endswith(".xml"):
                        continue
                    xml_count += 1
                    event_type = event_type_from_name(xml_entry.filename)
                    event_counts[event_type or "UNKNOWN"] += 1
                    try:
                        data = inner.read(xml_entry)
                        root = ET.fromstring(data)
                    except Exception as error:
                        parse_errors.append(
                            {
                                "source_zip": outer_entry.filename,
                                "xml_name": xml_entry.filename,
                                "error": str(error),
                            }
                        )
                        continue

                    source = {
                        "source_zip": outer_entry.filename,
                        "xml_name": xml_entry.filename,
                        "month_zip": month_zip,
                        "event_type": event_type,
                        "event_node": event_node_name(root),
                        "event_id": first_event_id(root),
                    }
                    if event_type == "S-1010":
                        definitions.extend(collect_rubric_definitions(root, source))
                    if ITEM_EVENT_TYPES is not None and event_type not in ITEM_EVENT_TYPES:
                        continue
                    found_items, found_refs = collect_rubric_items(root, source)
                    items.extend(found_items)
                    references.extend(found_refs)

    return {
        "inner_zip_count": inner_zip_count,
        "xml_count": xml_count,
        "event_counts": event_counts,
        "parse_errors": parse_errors,
        "definitions": definitions,
        "items": items,
        "references": references,
    }


def enrich_items(items, definitions):
    catalog_by_code = defaultdict(list)
    for definition in definitions:
        catalog_by_code[definition["code"]].append(definition)

    for item in items:
        definition = choose_definition(catalog_by_code, item["code"], item["ide_tab_rubr"], item["per_apur"])
        item["s1010_description"] = definition.get("description", "")
        item["nat_rubr"] = definition.get("nat_rubr", "")
        item["tp_rubr"] = definition.get("tp_rubr", "")
        item["cod_inc_cp"] = definition.get("cod_inc_cp", "")
        item["cod_inc_fgts"] = definition.get("cod_inc_fgts", "")
        item["cod_inc_irrf"] = definition.get("cod_inc_irrf", "")
        item["s1010_ini_valid"] = definition.get("ini_valid", "")
        item["s1010_fim_valid"] = definition.get("fim_valid", "")
        item["signed_vr_rubr"] = signed_value(item["code"], item["vr_rubr"], definition)


def aggregate(items):
    by_code = defaultdict(lambda: {"occurrences": 0, "events": set(), "cpfs": set(), "months": set(), "value": Decimal("0"), "signed": Decimal("0")})
    by_month = defaultdict(lambda: {"occurrences": 0, "events": set(), "cpfs": set(), "value": Decimal("0"), "signed": Decimal("0"), "codes": Counter()})
    by_event_type = defaultdict(lambda: {"occurrences": 0, "value": Decimal("0"), "signed": Decimal("0")})

    for item in items:
        code_bucket = by_code[item["code"]]
        code_bucket["occurrences"] += 1
        code_bucket["events"].add(item["event_id"])
        if item["cpf"]:
            code_bucket["cpfs"].add(item["cpf"])
        code_bucket["months"].add(item["per_apur"])
        code_bucket["value"] += item["vr_rubr"]
        code_bucket["signed"] += item["signed_vr_rubr"]

        month_bucket = by_month[item["per_apur"]]
        month_bucket["occurrences"] += 1
        month_bucket["events"].add(item["event_id"])
        if item["cpf"]:
            month_bucket["cpfs"].add(item["cpf"])
        month_bucket["value"] += item["vr_rubr"]
        month_bucket["signed"] += item["signed_vr_rubr"]
        month_bucket["codes"][item["code"]] += 1

        event_bucket = by_event_type[item["event_type"]]
        event_bucket["occurrences"] += 1
        event_bucket["value"] += item["vr_rubr"]
        event_bucket["signed"] += item["signed_vr_rubr"]

    return by_code, by_month, by_event_type


def write_csv(path, fieldnames, rows):
    with path.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            serializable = {}
            for key in fieldnames:
                value = row.get(key, "")
                serializable[key] = money(value) if isinstance(value, Decimal) else value
            writer.writerow(serializable)


def write_outputs(output_dir, zip_path, scan):
    output_dir.mkdir(parents=True, exist_ok=True)
    definitions = scan["definitions"]
    items = scan["items"]
    references = scan["references"]
    enrich_items(items, definitions)
    by_code, by_month, by_event_type = aggregate(items)

    item_rows = sorted(items, key=lambda row: (period_key(row["per_apur"]), row["code"], row["cpf"], row["event_id"]))
    write_csv(
        output_dir / "rubricas_auxilio_doenca_detalhe.csv",
        [
            "per_apur",
            "month_zip",
            "event_type",
            "event_node",
            "event_id",
            "cpf",
            "matricula",
            "ide_dm_dev",
            "code",
            "expected_description",
            "s1010_description",
            "nat_rubr",
            "tp_rubr",
            "cod_inc_cp",
            "cod_inc_fgts",
            "cod_inc_irrf",
            "qtd_rubr",
            "fator_rubr",
            "vr_rubr",
            "signed_vr_rubr",
            "ide_tab_rubr",
            "parent_node",
            "source_zip",
            "xml_name",
        ],
        item_rows,
    )

    code_rows = []
    for code in sorted(TARGET_RUBRICS):
        bucket = by_code[code]
        definitions_for_code = [definition for definition in definitions if definition["code"] == code]
        descriptions = sorted({definition["description"] for definition in definitions_for_code if definition["description"]})
        tp_values = sorted({definition["tp_rubr"] for definition in definitions_for_code if definition["tp_rubr"]})
        code_rows.append(
            {
                "code": code,
                "expected_description": TARGET_RUBRICS[code],
                "s1010_descriptions": " | ".join(descriptions),
                "tp_rubr_values": " | ".join(tp_values),
                "occurrences": bucket["occurrences"],
                "distinct_events": len(bucket["events"]),
                "distinct_cpfs": len(bucket["cpfs"]),
                "distinct_months": len(bucket["months"]),
                "months": ", ".join(sorted(bucket["months"])),
                "total_vr_rubr": bucket["value"],
                "total_signed_vr_rubr": bucket["signed"],
            }
        )
    write_csv(
        output_dir / "rubricas_auxilio_doenca_por_codigo.csv",
        [
            "code",
            "expected_description",
            "s1010_descriptions",
            "tp_rubr_values",
            "occurrences",
            "distinct_events",
            "distinct_cpfs",
            "distinct_months",
            "months",
            "total_vr_rubr",
            "total_signed_vr_rubr",
        ],
        code_rows,
    )

    month_rows = []
    for month in sorted(by_month, key=period_key):
        bucket = by_month[month]
        row = {
            "per_apur": month,
            "occurrences": bucket["occurrences"],
            "distinct_events": len(bucket["events"]),
            "distinct_cpfs": len(bucket["cpfs"]),
            "total_vr_rubr": bucket["value"],
            "total_signed_vr_rubr": bucket["signed"],
        }
        for code in sorted(TARGET_RUBRICS):
            row[f"occurrences_{code}"] = bucket["codes"][code]
        month_rows.append(row)
    write_csv(
        output_dir / "rubricas_auxilio_doenca_por_mes.csv",
        [
            "per_apur",
            "occurrences",
            "distinct_events",
            "distinct_cpfs",
            "total_vr_rubr",
            "total_signed_vr_rubr",
        ]
        + [f"occurrences_{code}" for code in sorted(TARGET_RUBRICS)],
        month_rows,
    )

    definition_rows = [definition for definition in definitions if definition["code"] in TARGET_RUBRICS]
    all_definition_rows = sorted(definitions, key=lambda row: (row["code"], row["ini_valid"], row["event_id"]))
    candidate_definition_rows = [
        definition
        for definition in all_definition_rows
        if definition["code"] in TARGET_RUBRICS
        or any(needle in normalize_text(definition["description"]) for needle in DESCRIPTION_CANDIDATE_NEEDLES)
    ]
    definition_fieldnames = [
        "code",
        "raw_code",
        "ide_tab_rubr",
        "ini_valid",
        "fim_valid",
        "operation",
        "description",
        "nat_rubr",
        "tp_rubr",
        "cod_inc_cp",
        "cod_inc_fgts",
        "cod_inc_irrf",
        "event_id",
        "source_zip",
        "xml_name",
    ]
    write_csv(
        output_dir / "rubricas_auxilio_doenca_definicoes_s1010.csv",
        definition_fieldnames,
        sorted(definition_rows, key=lambda row: (row["code"], row["ini_valid"], row["event_id"])),
    )
    write_csv(output_dir / "rubricas_s1010_todas_definicoes.csv", definition_fieldnames, all_definition_rows)
    write_csv(output_dir / "rubricas_s1010_candidatas_por_descricao.csv", definition_fieldnames, candidate_definition_rows)

    reference_counts = Counter((reference["event_type"], reference["code"], reference["has_vr_rubr"]) for reference in references)
    references_rows = [
        {
            "event_type": event_type,
            "code": code,
            "has_vr_rubr": has_vr_rubr,
            "references": count,
        }
        for (event_type, code, has_vr_rubr), count in sorted(reference_counts.items())
    ]
    write_csv(
        output_dir / "rubricas_auxilio_doenca_referencias_por_evento.csv",
        ["event_type", "code", "has_vr_rubr", "references"],
        references_rows,
    )

    total_value = sum((item["vr_rubr"] for item in items), Decimal("0"))
    total_signed = sum((item["signed_vr_rubr"] for item in items), Decimal("0"))
    distinct_months = sorted({item["per_apur"] for item in items}, key=period_key)
    distinct_cpfs = {item["cpf"] for item in items if item["cpf"]}
    distinct_events = {item["event_id"] for item in items if item["event_id"]}

    summary = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "zip_path": str(zip_path),
        "inner_zip_count": scan["inner_zip_count"],
        "xml_count": scan["xml_count"],
        "parse_error_count": len(scan["parse_errors"]),
        "event_counts": dict(sorted(scan["event_counts"].items())),
        "target_codes": TARGET_RUBRICS,
        "match_occurrences": len(items),
        "distinct_events": len(distinct_events),
        "distinct_cpfs": len(distinct_cpfs),
        "distinct_months": len(distinct_months),
        "months": distinct_months,
        "total_vr_rubr": money(total_value),
        "total_signed_vr_rubr": money(total_signed),
        "outputs": [
            "relatorio_auxilio_doenca_cte.md",
            "rubricas_auxilio_doenca_por_codigo.csv",
            "rubricas_auxilio_doenca_por_mes.csv",
            "rubricas_auxilio_doenca_detalhe.csv",
            "rubricas_auxilio_doenca_definicoes_s1010.csv",
            "rubricas_s1010_candidatas_por_descricao.csv",
            "rubricas_s1010_todas_definicoes.csv",
            "rubricas_auxilio_doenca_referencias_por_evento.csv",
        ],
        "s1010_definition_count": len(definitions),
        "s1010_candidate_definition_count": len(candidate_definition_rows),
    }
    (output_dir / "scan_summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")

    markdown = []
    markdown.append("# Relatorio CTE - Rubricas de auxilio doenca")
    markdown.append("")
    markdown.append(f"Gerado em: {summary['generated_at']}")
    markdown.append(f"ZIP analisado: `{zip_path}`")
    markdown.append("")
    markdown.append("## Escopo")
    markdown.append("")
    markdown.append(f"- ZIPs mensais lidos: {scan['inner_zip_count']}")
    markdown.append(f"- XMLs lidos: {scan['xml_count']}")
    markdown.append(f"- Erros de parse XML: {len(scan['parse_errors'])}")
    markdown.append(f"- Definicoes S-1010 lidas: {len(definitions)}")
    markdown.append(f"- Definicoes S-1010 candidatas por descricao: {len(candidate_definition_rows)}")
    markdown.append("- Busca feita em todos os XMLs; os totais monetarios consideram ocorrencias com `codRubr` alvo e `vrRubr` no mesmo item.")
    markdown.append("- `total_vr_rubr` e o valor positivo informado no eSocial; `total_signed_vr_rubr` trata rubricas S-1010 `tpRubr=2` ou `4` como negativas.")
    markdown.append("")
    markdown.append("## Resultado geral")
    markdown.append("")
    markdown.append(f"- Ocorrencias encontradas: {len(items)}")
    markdown.append(f"- Eventos distintos: {len(distinct_events)}")
    markdown.append(f"- Trabalhadores distintos: {len(distinct_cpfs)}")
    markdown.append(f"- Competencias com ocorrencia: {len(distinct_months)}")
    markdown.append(f"- Total informado (`vrRubr`): {money(total_value)}")
    markdown.append(f"- Total com sinal por tipo de rubrica: {money(total_signed)}")
    markdown.append("")
    markdown.append("## Por codigo")
    markdown.append("")
    markdown.append("| Codigo | Descricao esperada | Ocorrencias | Meses | Trabalhadores | Total informado | Total com sinal |")
    markdown.append("|---|---:|---:|---:|---:|---:|---:|")
    for row in code_rows:
        markdown.append(
            f"| {row['code']} | {row['expected_description']} | {row['occurrences']} | {row['distinct_months']} | {row['distinct_cpfs']} | {money(row['total_vr_rubr'])} | {money(row['total_signed_vr_rubr'])} |"
        )
    markdown.append("")
    markdown.append("## Por competencia")
    markdown.append("")
    markdown.append("| Competencia | Ocorrencias | Trabalhadores | Total informado | Total com sinal | Codigos |")
    markdown.append("|---|---:|---:|---:|---:|---|")
    for row in month_rows:
        codes = ", ".join(f"{code}:{row[f'occurrences_{code}']}" for code in sorted(TARGET_RUBRICS) if row[f"occurrences_{code}"])
        markdown.append(
            f"| {row['per_apur']} | {row['occurrences']} | {row['distinct_cpfs']} | {money(row['total_vr_rubr'])} | {money(row['total_signed_vr_rubr'])} | {codes} |"
        )
    markdown.append("")
    markdown.append("## Arquivos gerados")
    markdown.append("")
    for filename in summary["outputs"]:
        markdown.append(f"- `{filename}`")
    markdown.append("")
    markdown.append("## Contagem de eventos lidos")
    markdown.append("")
    for event_type, count in sorted(scan["event_counts"].items()):
        markdown.append(f"- {event_type}: {count}")
    markdown.append("")

    if scan["parse_errors"]:
        markdown.append("## Erros de parse")
        markdown.append("")
        for error in scan["parse_errors"][:20]:
            markdown.append(f"- {error['source_zip']} / {error['xml_name']}: {error['error']}")
        if len(scan["parse_errors"]) > 20:
            markdown.append(f"- ... mais {len(scan['parse_errors']) - 20} erros")
        markdown.append("")

    (output_dir / "relatorio_auxilio_doenca_cte.md").write_text("\n".join(markdown), encoding="utf-8")
    return summary


def main():
    zip_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_ZIP
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUTPUT_DIR
    if not zip_path.exists():
        raise SystemExit(f"ZIP nao encontrado: {zip_path}")
    scan = scan_zip(zip_path)
    summary = write_outputs(output_dir, zip_path, scan)
    print(json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()