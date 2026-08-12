import pdfplumber
import re

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    text = page.extract_text()
    lines = text.split('\n')
    # Show first 10 lines reversed
    for i, line in enumerate(lines[:30]):
        rev = line[::-1]
        print(f"[{i}] REV: {rev[:150]}")
