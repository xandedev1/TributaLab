import pdfplumber
import re
from collections import defaultdict

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    words = page.extract_words()
    
    # Group by y
    rows = defaultdict(list)
    for w in words:
        y_key = round(w['top'] / 5) * 5
        rows[y_key].append(w)
    
    # Find all rows with NF-like patterns
    for y in sorted(rows.keys()):
        ws = sorted(rows[y], key=lambda w: w['x0'])
        texts = [w['text'][::-1] for w in ws]
        # Check for NF pattern (5-6 digits)
        nf_matches = [t for t in texts if re.match(r'^\d{5,6}$', t)]
        if len(nf_matches) >= 3:
            print(f"y={y}: NF candidates: {nf_matches[:5]}")
        # Check for "NF" text
        nf_text = [t for t in texts if 'NF' in t]
        if nf_text:
            print(f"y={y}: NF text: {nf_text[:5]}")
