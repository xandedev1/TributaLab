import fitz, json, os

# 1. Header do relatório ISO anterior da SOLUCOES (branding + CNPJ)
pdf = r'C:\Users\xandao\Downloads\SOLUCOES_RELATORIO_2026_ISO_19011_2026.pdf'
doc = fitz.open(pdf)
print('=== SOLUCOES ISO ANTERIOR - PAGE 1 (primeiras 60 linhas) ===')
lines = doc[0].get_text('text').splitlines()
for l in lines[:60]:
    print(l)
doc.close()

# 2. Estrutura dos JSONs
print('\n=== JSONS ===')
base = r'C:\Users\xandao\Documents\GitHub\TributaLab\tmp'
for name in ['efd_razao.json', 'razao_servicos.json', 'razao_vendas.json', 'devolucao.json']:
    p = os.path.join(base, name)
    if not os.path.exists(p):
        print(name, 'MISSING')
        continue
    data = json.load(open(p, encoding='utf-8'))
    print(name, 'top keys:', list(data.keys()))
    for k, v in data.items():
        if isinstance(v, list) and v:
            print('  ', k, 'len:', len(v), 'sample keys:', list(v[0].keys()))
        elif not isinstance(v, list):
            print('  ', k, '=', v)

# 3. reportlab disponível?
try:
    import reportlab
    print('\nreportlab OK', reportlab.Version)
except ImportError:
    print('\nreportlab MISSING')
