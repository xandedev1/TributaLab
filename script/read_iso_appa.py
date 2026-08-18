import fitz

pdf_path = r'C:\Users\xandao\Downloads\APPA_RELATORIO_2026_ISO_19011_2026.pdf'
doc = fitz.open(pdf_path)
print('Total pages:', len(doc))
print('=' * 80)

for page_num in range(len(doc)):
    page = doc[page_num]
    text = page.get_text('text')
    print(f'--- PAGE {page_num + 1} ---')
    print(text)
    print()

doc.close()
