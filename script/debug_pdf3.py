import pdfplumber
import re
from collections import defaultdict

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    words = page.extract_words()
    
    # Group words by approximate y-coordinate (row)
    lines = defaultdict(list)
    for w in words:
        y_key = round(w['top'] / 5) * 5  # round to nearest 5
        lines[y_key].append(w)
    
    # For each line, sort by x and reverse each word
    for y in sorted(lines.keys()):
        ws = sorted(lines[y], key=lambda w: w['x0'])
        # Reverse each word's text
        reversed_words = [w['text'][::-1] for w in ws]
        line_text = ' '.join(reversed_words)
        print(f"y={y}: {line_text}")
