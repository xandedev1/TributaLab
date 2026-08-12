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
    
    # Show rows around y=410 (where we found NF numbers before)
    for y in sorted(rows.keys()):
        if 400 <= y <= 470:
            ws = sorted(rows[y], key=lambda w: w['x0'])
            texts = [w['text'][::-1] for w in ws]
            print(f"y={y}: {texts}")
