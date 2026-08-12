#!/usr/bin/env python3
"""
Extract Razão records from PDF files (Livro Razão - Sped Digital).

Usage: python extract_razao_pdf.py <pdf_path> <output_json>

ATENÇÃO: este extrator está EM REVISÃO. Ver docs/05_qa/razao-pdf-extracao-loop-analise.md
O layout real do PDF é uma tabela linha-a-linha (Data | Histórico | Nº Lançamento |
Débito | Crédito | Saldo), mas o texto vem espelhado/rotacionado pelo pdfplumber.
A heurística atual (agrupar por y e casar colunas por x) só funciona até ~pág 369.
"""
import sys
import os
import json
import re
from collections import defaultdict

try:
    import pdfplumber
except ImportError:
    print("Error: pdfplumber not installed. Run: pip install pdfplumber", file=sys.stderr)
    sys.exit(1)


def parse_value(val):
    """Parse Brazilian decimal string to float."""
    if not val or not val.strip():
        return 0.0
    val = val.strip().replace("R$", "").replace(".", "").replace(",", ".").strip()
    try:
        return float(val)
    except ValueError:
        return 0.0


def parse_date(val):
    """Parse DD/MM/YYYY to YYYY-MM-DD."""
    val = val.strip()
    match = re.match(r'(\d{2})/(\d{2})/(\d{4})', val)
    if match:
        return f"{match.group(3)}-{match.group(2)}-{match.group(1)}"
    return None


def extract_nf_5_digits(nf_raw):
    """Normaliza o NF para 5 dígitos (o EFD traz 00059523, o Razão 59523)."""
    stripped = nf_raw.lstrip('0')
    if not stripped:
        return None
    if len(stripped) >= 5:
        return stripped[-5:]
    return stripped.zfill(5)


def extract_records_from_pdf(pdf_path):
    """Extract records from a Razão PDF (mirrored text, column layout)."""
    records = []
    errors = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            words = page.extract_words()
            if not words:
                continue

            rows = defaultdict(list)
            for w in words:
                y_key = round(w['top'] / 5) * 5
                rows[y_key].append(w)

            nf_y = None
            best_count = 0
            for y, ws in rows.items():
                count = 0
                for w in ws:
                    rev = w['text'][::-1]
                    if re.match(r'^\d{8,9}$', rev):
                        count += 1
                if count > best_count and count >= 3:
                    nf_y = y
                    best_count = count

            if not nf_y:
                continue

            nf_words = []
            for w in sorted(rows[nf_y], key=lambda w: w['x0']):
                rev = w['text'][::-1]
                if re.match(r'^\d{8,9}$', rev):
                    nf_words.append(w)

            columns = []
            for w in nf_words:
                nf_raw = w['text'][::-1]
                x_center = (w['x0'] + w['x1']) / 2
                columns.append({'nf_raw': nf_raw, 'x': x_center})

            value_y = None
            best_vcount = 0
            for y, ws in rows.items():
                if y == nf_y:
                    continue
                count = 0
                for w in ws:
                    rev = w['text'][::-1]
                    if re.match(r'^\d{1,3}(\.\d{3})*,\d{2}$', rev):
                        count += 1
                if count > best_vcount and count >= 3:
                    value_y = y
                    best_vcount = count

            date_y = None
            best_dcount = 0
            for y, ws in rows.items():
                if y == nf_y:
                    continue
                count = 0
                for w in ws:
                    rev = w['text'][::-1]
                    if re.match(r'^\d{2}/\d{2}/\d{4}$', rev):
                        count += 1
                if count > best_dcount and count >= 3:
                    date_y = y
                    best_dcount = count

            value_map = {}
            if value_y and value_y in rows:
                for vw in rows[value_y]:
                    val_text = vw['text'][::-1]
                    if not re.match(r'^\d{1,3}(\.\d{3})*,\d{2}$', val_text):
                        continue
                    vw_x = (vw['x0'] + vw['x1']) / 2
                    closest = min(columns, key=lambda c: abs(c['x'] - vw_x))
                    value_map[closest['nf_raw']] = parse_value(val_text)

            date_map = {}
            if date_y and date_y in rows:
                for dw in rows[date_y]:
                    date_text = dw['text'][::-1]
                    if not re.match(r'^\d{2}/\d{2}/\d{4}$', date_text):
                        continue
                    dw_x = (dw['x0'] + dw['x1']) / 2
                    closest = min(columns, key=lambda c: abs(c['x'] - dw_x))
                    date_map[closest['nf_raw']] = parse_date(date_text)

            for col in columns:
                nf_raw = col['nf_raw']
                if len(nf_raw) < 8:
                    continue

                nf = extract_nf_5_digits(nf_raw)
                if nf is None:
                    errors.append({
                        "nf_raw": nf_raw,
                        "error": "NF inválido (todos zeros)",
                        "source_file": os.path.basename(pdf_path),
                    })
                    continue

                credito = value_map.get(nf_raw, 0.0)
                data = date_map.get(nf_raw)

                if credito == 0.0 and not data:
                    continue

                records.append({
                    "num_nf": nf,
                    "num_nf_raw": nf_raw,
                    "data_emissao": data,
                    "credito": credito,
                    "source_file": os.path.basename(pdf_path),
                })

    return records, errors


def main():
    if len(sys.argv) < 3:
        print("Usage: python extract_razao_pdf.py <pdf_path> <output_json>", file=sys.stderr)
        sys.exit(1)

    pdf_path = sys.argv[1]
    output_json = sys.argv[2]

    if not os.path.isfile(pdf_path):
        print(f"Error: file not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    records, errors = extract_records_from_pdf(pdf_path)
    print(f"Extracted {len(records)} records, {len(errors)} errors from {os.path.basename(pdf_path)}", file=sys.stderr)

    with open(output_json, "w", encoding="utf-8") as f:
        json.dump({"records": records, "errors": errors}, f, ensure_ascii=False, indent=2)

    print(f"Written to {output_json}", file=sys.stderr)


if __name__ == "__main__":
    main()
