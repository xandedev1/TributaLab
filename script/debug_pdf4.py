import pdfplumber
import re
from collections import defaultdict

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    words = page.extract_words()
    
    # Group words by approximate y-coordinate (row)
    rows = defaultdict(list)
    for w in words:
        y_key = round(w['top'] / 5) * 5
        rows[y_key].append(w)
    
    # Find the row with NF numbers (y around 410)
    # Find the row with values (y around 145)
    # Find the row with dates (y around 295 or similar)
    
    # Let's look at all rows and identify which contain NF numbers
    for y in sorted(rows.keys()):
        ws = sorted(rows[y], key=lambda w: w['x0'])
        texts = [w['text'][::-1] for w in ws]  # reverse each word
        # Check if this row has NF-like numbers (6+ digits)
        nf_count = sum(1 for t in texts if re.match(r'^\d{5,}$', t))
        if nf_count > 3:
            print(f"y={y} ({nf_count} nums): {texts[:5]}...")
