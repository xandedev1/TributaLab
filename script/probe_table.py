import pdfplumber
import re
import json

pdf_path = r'C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf'

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[370]
    # Tabela tem grid visível -> lines strategy
    tables = page.extract_tables({"vertical_strategy": "lines", "horizontal_strategy": "lines"})
    print(f"tables: {len(tables)}")
    for t in tables:
        for row in t[:22]:
            print([ (c or '').replace('\n',' ')[:60] for c in row ])
        break
