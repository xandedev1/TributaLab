import pdfplumber

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    # Page 1 - reverse each line
    page = pdf.pages[0]
    text = page.extract_text()
    for line in text.split('\n'):
        reversed_line = line[::-1]
        print(reversed_line)
    print("\n=== PAGE 2 ===\n")
    page = pdf.pages[1]
    text = page.extract_text()
    for line in text.split('\n'):
        reversed_line = line[::-1]
        print(reversed_line)
