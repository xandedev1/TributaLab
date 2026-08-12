import pdfplumber

pdf_path = r"C:\Users\xandao\Downloads\Marcos_Cruzamento\Marcos Cruzamento dados soluções\Razão 2022 Receita\31100100003 Serviços Mercado Interno.pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    # Try extracting words with positions
    words = page.extract_words()
    print(f"Total words: {len(words)}")
    # Show first 30 words with positions
    for w in words[:30]:
        print(f"  x={w['x0']:.0f} y={w['top']:.0f} text='{w['text']}'")
    
    print("\n--- Lines by y-coordinate ---")
    # Group words by y-coordinate (top)
    from collections import defaultdict
    lines = defaultdict(list)
    for w in words:
        y_key = round(w['top'])
        lines[y_key].append(w)
    
    # Show first 5 lines
    for y in sorted(lines.keys())[:15]:
        ws = sorted(lines[y], key=lambda w: w['x0'])
        print(f"y={y}: {[w['text'] for w in ws]}")
