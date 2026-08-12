#!/usr/bin/env python3
"""
Extract Devolução records from PDF files (Livro Razão - Sped Digital).

Usage: python extract_devolucao_pdf.py <pdf_path> <output_json>
"""
import fitz
import re
import json
import sys
import os

def parse_value(val):
    if not val:
        return 0.0
    val = str(val).strip().replace("R$", "").replace(".", "").replace(",", ".").strip()
    try:
        return float(val)
    except ValueError:
        return 0.0

def parse_date(val):
    if not val:
        return None
    match = re.match(r'(\d{2})/(\d{2})/(\d{4})', str(val).strip())
    if match:
        return f"{match.group(3)}-{match.group(2)}-{match.group(1)}"
    return None

def extract_nf_5_digits(nf_raw):
    stripped = str(nf_raw).lstrip('0')
    if not stripped:
        return None
    if len(stripped) >= 5:
        return stripped[-5:]
    return stripped.zfill(5)

def extract_records(pdf_path):
    doc = fitz.open(pdf_path)
    records = []
    
    for page_num in range(len(doc)):
        page = doc[page_num]
        text = page.get_text("text")
        lines = text.split('\n')
        
        for i, line in enumerate(lines):
            # Look for NF pattern in devolução context
            match = re.search(r'NFE?\s*[.\s]*N?[º°]?\s*(\d+)', line, re.IGNORECASE)
            if not match:
                continue
            
            nf_raw = match.group(1)
            nf = extract_nf_5_digits(nf_raw)
            if not nf:
                continue
            
            # Data is 2 lines above
            data_emissao = None
            if i >= 2:
                date_match = re.search(r'(\d{2}/\d{2}/\d{4})', lines[i-2])
                if date_match:
                    data_emissao = parse_date(date_match.group(1))
            
            # Valor is in the next 1-3 lines
            valor = 0.0
            for offset in range(1, 4):
                if i + offset < len(lines):
                    value_match = re.search(r'R\$\s*([\d.,]+)', lines[i+offset])
                    if value_match:
                        valor = parse_value(value_match.group(1))
                        break
            
            if valor == 0.0 and not data_emissao:
                continue
            
            records.append({
                "num_nf": nf,
                "num_nf_raw": nf_raw,
                "data_emissao": data_emissao,
                "valor": valor,
                "source_file": os.path.basename(pdf_path),
                "page": page_num + 1,
            })
    
    doc.close()
    
    # Sum duplicate NFs
    summed = {}
    for r in records:
        key = r["num_nf"]
        if key not in summed:
            summed[key] = r.copy()
        else:
            summed[key]["valor"] += r["valor"]
    
    return list(summed.values())

def main():
    if len(sys.argv) < 3:
        print("Usage: python extract_devolucao_pdf.py <pdf_path> <output_json>", file=sys.stderr)
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    output_json = sys.argv[2]
    
    records = extract_records(pdf_path)
    print(f"Extracted {len(records)} records from {os.path.basename(pdf_path)}", file=sys.stderr)
    
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump({"records": records, "errors": []}, f, ensure_ascii=False, indent=2)
    
    print(f"Written to {output_json}", file=sys.stderr)

if __name__ == "__main__":
    main()
