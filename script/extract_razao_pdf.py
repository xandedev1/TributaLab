#!/usr/bin/env python3
"""
Extract Razão records from PDF files (Livro Razão - Sped Digital).

Usage: python extract_razao_pdf.py <pdf_path> <output_json>

The PDFs have mirrored/reversed text and are laid out in COLUMNS.
Each column is a record with:
  - NF number (8-9 digits with leading zeros, actual NF is last 5 digits)
  - Crédito value (Brazilian currency)
  - Data (DD/MM/YYYY)

We match columns by x-position.
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
    """
    Extract the actual NF number (last 5 digits).
    If the number has more or less than 5 digits after stripping zeros,
    return None to flag as error.
    """
    # Strip leading zeros
    stripped = nf_raw.lstrip('0')
    if not stripped:
        return None  # All zeros
    
    # Check if exactly 5 digits
    if len(stripped) == 5:
        return stripped
    elif len(stripped) > 5:
        # More than 5 digits - take last 5
        return stripped[-5:]
    else:
        # Less than 5 digits - pad with zeros
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

            # Group words by approximate y-coordinate (row)
            rows = defaultdict(list)
            for w in words:
                y_key = round(w['top'] / 5) * 5
                rows[y_key].append(w)

            # Find the NF row: multiple words with 8-9 digits after reversing
            # NF is at y~410 (Serviços: 8 digits) or y~595 (Vendas: 9 digits)
            nf_y = None
            best_count = 0
            for y, ws in rows.items():
                count = 0
                for w in ws:
                    rev = w['text'][::-1]
                    # NF has 8-9 digits (with leading zeros)
                    if re.match(r'^\d{8,9}$', rev):
                        count += 1
                if count > best_count and count >= 3:
                    nf_y = y
                    best_count = count

            if not nf_y:
                continue

            # NF columns define the record positions
            nf_words = sorted(rows[nf_y], key=lambda w: w['x0'])
            columns = []
            for w in nf_words:
                nf_raw = w['text'][::-1]
                x_center = (w['x0'] + w['x1']) / 2
                columns.append({'nf_raw': nf_raw, 'x': x_center})

            # Find value row: multiple words matching Brazilian currency pattern after reversing
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

            # Find date row: multiple words matching DD/MM/YYYY after reversing
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

            # Match values to columns by x-position
            value_map = {}
            if value_y and value_y in rows:
                for vw in rows[value_y]:
                    val_text = vw['text'][::-1]
                    vw_x = (vw['x0'] + vw['x1']) / 2
                    closest = min(columns, key=lambda c: abs(c['x'] - vw_x))
                    value_map[closest['nf_raw']] = parse_value(val_text)

            # Match dates to columns by x-position
            date_map = {}
            if date_y and date_y in rows:
                for dw in rows[date_y]:
                    date_text = dw['text'][::-1]
                    dw_x = (dw['x0'] + dw['x1']) / 2
                    closest = min(columns, key=lambda c: abs(c['x'] - dw_x))
                    date_map[closest['nf_raw']] = parse_date(date_text)

            # Build records
            for col in columns:
                nf_raw = col['nf_raw']
                # Skip header-like NFs (e.g., page numbers)
                if len(nf_raw) < 8:
                    continue
                
                # Extract 5-digit NF
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
                
                # Skip if no value and no date
                if credito == 0.0 and not data:
                    continue
                
                records.append({
                    "num_nf": nf,  # 5 digits
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

    result = {
        "records": records,
        "errors": errors,
    }

    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"Written to {output_json}", file=sys.stderr)


if __name__ == "__main__":
    main()
