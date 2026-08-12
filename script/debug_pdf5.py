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
    
    # Print ALL rows with their content
    for y in sorted(rows.keys()):
        ws = sorted(rows[y], key=lambda w: w['x0'])
        texts = [w['text'][::-1] for w in ws]
        line = ' | '.join(texts)
        print(f"y={y}: {line}")
