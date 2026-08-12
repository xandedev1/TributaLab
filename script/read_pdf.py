import pdfplumber
import os

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

print(f"=== {os.path.basename(pdf_path)} ===\n")

with pdfplumber.open(pdf_path) as pdf:
    print(f"Total pages: {len(pdf.pages)}\n")
    # Read first 3 pages
    for i, page in enumerate(pdf.pages[:3]):
        print(f"--- Page {i+1} ---")
        text = page.extract_text()
        if text:
            print(text[:2000])
        # Also try tables
        tables = page.extract_tables()
        if tables:
            print(f"\n[Tables found: {len(tables)}]")
            for t_idx, table in enumerate(tables[:1]):
                print(f"Table {t_idx+1} ({len(table)} rows):")
                for row in table[:5]:
                    print(row)
        print()
