#!/usr/bin/env python3
"""
Extract A100 (Serviços) and C100 (Vendas) records from EFD PIS/COFINS TXT files.

Usage: python extract_efd_razao.py <efd_dir> <output_json>

Reads all PISCOFINS_*.txt files in <efd_dir>, extracts A100 and C100 records,
and writes JSON with { "a100": [...], "c100": [...] }.

A100/C100 columns (pipe-delimited, 1-indexed):
  1ª = Código (participante)
  8ª = Número da NF
  10ª = Data da Emissão da NF (DDMMYYYY)
  12ª = Valor da NF

NF numbers are normalized to 5 digits (last 5 significant digits).
"""
import sys
import os
import json
import glob
from datetime import datetime


def parse_date(val):
    """Parse DDMMYYYY to YYYY-MM-DD."""
    val = val.strip()
    if len(val) == 8 and val.isdigit():
        try:
            return datetime.strptime(val, "%d%m%Y").strftime("%Y-%m-%d")
        except ValueError:
            return None
    return None


def parse_value(val):
    """Parse Brazilian decimal string to float."""
    if not val or not val.strip():
        return 0.0
    val = val.strip().replace(".", "").replace(",", ".")
    try:
        return float(val)
    except ValueError:
        return 0.0


def normalize_nf(nf):
    """
    Normalize NF to 5 digits.
    - Strip leading zeros
    - If more than 5 digits, take last 5
    - If less than 5 digits, pad with zeros
    """
    stripped = nf.lstrip('0')
    if not stripped:
        return '0'
    if len(stripped) >= 5:
        return stripped[-5:]
    return stripped.zfill(5)


def extract_records(txt_path):
    """Extract A100 and C100 records from a single EFD file."""
    a100_records = []
    c100_records = []

    with open(txt_path, "r", encoding="latin-1") as f:
        for line in f:
            line = line.strip()
            if not line.startswith("|"):
                continue

            parts = line.split("|")
            # parts[0] is empty (before first |), parts[-1] is empty (after last |)
            # So actual fields are parts[1:-1]
            fields = parts[1:-1]
            if len(fields) < 2:
                continue

            reg_type = fields[0]

            if reg_type == "A100" and len(fields) >= 12:
                # 1ª=Código(0), 8ª=NºNF(7), 10ª=Data(9), 12ª=Valor(11)
                nf_raw = fields[7].strip()
                a100_records.append({
                    "codigo": fields[0].strip(),
                    "num_nf": normalize_nf(nf_raw),
                    "num_nf_raw": nf_raw,
                    "data_emissao": parse_date(fields[9]),
                    "valor_nf": parse_value(fields[11]),
                    "source_file": os.path.basename(txt_path),
                })

            elif reg_type == "C100" and len(fields) >= 12:
                # 1ª=Código(0), 8ª=NºNF(7), 10ª=Data(9), 12ª=Valor(11)
                nf_raw = fields[7].strip()
                c100_records.append({
                    "codigo": fields[0].strip(),
                    "num_nf": normalize_nf(nf_raw),
                    "num_nf_raw": nf_raw,
                    "data_emissao": parse_date(fields[9]),
                    "valor_nf": parse_value(fields[11]),
                    "source_file": os.path.basename(txt_path),
                })

    return a100_records, c100_records


def main():
    if len(sys.argv) < 3:
        print("Usage: python extract_efd_razao.py <efd_dir> <output_json>", file=sys.stderr)
        sys.exit(1)

    efd_dir = sys.argv[1]
    output_json = sys.argv[2]

    if not os.path.isdir(efd_dir):
        print(f"Error: directory not found: {efd_dir}", file=sys.stderr)
        sys.exit(1)

    all_a100 = []
    all_c100 = []

    txt_files = sorted(glob.glob(os.path.join(efd_dir, "PISCOFINS_*.txt")))
    print(f"Found {len(txt_files)} EFD files", file=sys.stderr)

    for txt_path in txt_files:
        a100, c100 = extract_records(txt_path)
        all_a100.extend(a100)
        all_c100.extend(c100)
        print(f"  {os.path.basename(txt_path)}: A100={len(a100)}, C100={len(c100)}", file=sys.stderr)

    result = {
        "a100": all_a100,
        "c100": all_c100,
    }

    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"Extracted: A100={len(all_a100)}, C100={len(all_c100)} -> {output_json}", file=sys.stderr)


if __name__ == "__main__":
    main()
