import fitz

pdf_path = r'C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf'
doc = fitz.open(pdf_path)

# Search all pages for NF 59537
for page_num in range(len(doc)):
    page = doc[page_num]
    text = page.get_text('text')
    if '59537' in text:
        print('Found on page', page_num)
        lines = text.split('\n')
        for i, line in enumerate(lines):
            if '59537' in line:
                for j in range(max(0, i-2), min(len(lines), i+6)):
                    print(str(j) + ': ' + lines[j][:100])
                break
        break

doc.close()
