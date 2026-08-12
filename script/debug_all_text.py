import pdfplumber
import re
from collections import defaultdict

pdf_path = r'C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf'

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[370]
    words = page.extract_words()
    
    rows = defaultdict(list)
    for w in words:
        y_key = round(w['top'] / 5) * 5
        rows[y_key].append(w)
    
    # Show all rows with any text
    for y, ws in sorted(rows.items()):
        ws_sorted = sorted(ws, key=lambda w: w['x0'])
        line_text = ' '.join(w['text'][::-1] for w in ws_sorted)
        
        # Show rows with numbers or NF
        if re.search(r'\d', line_text) or 'NF' in line_text or 'FN' in line_text:
            print(f'y={y}: {line_text[:200]}')
