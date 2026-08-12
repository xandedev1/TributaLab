import pdfplumber
import re
from collections import defaultdict

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    words = page.extract_words()
    
    # Group words by approximate y-coordinate (row)
    rows = defaultdict(list)
    for w in words:
        y_key = round(w['top'] / 5) * 5
        rows[y_key].append(w)
    
    # Find the row with NF numbers (y=410) - these define the columns
    nf_row_y = 410
    nf_words = sorted(rows.get(nf_row_y, []), key=lambda w: w['x0'])
    
    # Each NF word defines a column center (x position)
    columns = []
    for w in nf_words:
        nf_num = w['text'][::-1]  # reverse to get readable
        x_center = (w['x0'] + w['x1']) / 2
        columns.append({'nf': nf_num, 'x': x_center})
    
    print(f"Found {len(columns)} columns")
    
    # Now find values (y=145) and match to columns by x position
    value_words = sorted(rows.get(145, []), key=lambda w: w['x0'])
    print(f"\nValues row ({len(value_words)} items):")
    for vw in value_words:
        val_text = vw['text'][::-1]
        # Find closest column
        vw_x = (vw['x0'] + vw['x1']) / 2
        closest_col = min(columns, key=lambda c: abs(c['x'] - vw_x))
        print(f"  x={vw_x:.0f} val={val_text} -> NF={closest_col['nf']} (col x={closest_col['x']:.0f})")
