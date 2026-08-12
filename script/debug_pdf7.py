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
    
    # Find rows with dates (DD/MM/YYYY pattern after reversing)
    for y in sorted(rows.keys()):
        ws = sorted(rows[y], key=lambda w: w['x0'])
        for w in ws:
            rev = w['text'][::-1]
            if re.match(r'\d{2}/\d{2}/\d{4}', rev):
                print(f"y={y} x={w['x0']:.0f}: {rev}")
