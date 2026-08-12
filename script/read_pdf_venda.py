import pdfplumber

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100001 Venda Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    print(f"Total pages: {len(pdf.pages)}\n")
    page = pdf.pages[0]
    text = page.extract_text()
    for line in text.split('\n'):
        print(line[::-1])
