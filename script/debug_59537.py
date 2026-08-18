import fitz

pdf_path = r'C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf'
doc = fitz.open(pdf_path)
page = doc[370]
text = page.get_text('text')
lines = text.split('\n')

# Find NF 59537
for i, line in enumerate(lines):
    if '59537' in line:
        print('Found at line', i)
        for j in range(max(0, i-2), min(len(lines), i+6)):
            print(str(j) + ': ' + lines[j][:100])
        break

doc.close()
