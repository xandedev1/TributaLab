import asyncio, json, sys

try:
    import websockets
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', 'websockets'])
    import websockets

WS_URL = 'ws://localhost:9222/devtools/page/EC7B60B7FDA2B24EEE6CAB97ECD02623'

# Clica no botão Consultar e aguarda, depois extrai a tabela
JS_CLICK = r"""
(() => {
  const btn = document.querySelector('input[type=submit][value="Consultar"]');
  if (btn) { btn.click(); return 'CLICADO'; }
  return 'BOTAO NAO ENCONTRADO';
})()
"""

JS_TABLE = r"""
(() => {
  const rows = document.querySelectorAll('table tr');
  const out = [];
  rows.forEach(tr => {
    const tds = tr.querySelectorAll('td');
    if (tds.length > 0) {
      const textos = Array.from(tds).map(td => td.innerText.trim().replace(/\s+/g, ' '));
      const links = Array.from(tr.querySelectorAll('a')).map(a => a.href);
      out.push({colunas: textos, links: links});
    }
  });
  return JSON.stringify({numRows: out.length, rows: out});
})()
"""

async def send(ws, mid, expr):
    await ws.send(json.dumps({'id': mid, 'method': 'Runtime.evaluate', 'params': {'expression': expr, 'returnByValue': True}}))
    while True:
        resp = await ws.recv()
        data = json.loads(resp)
        if data.get('id') == mid:
            return data.get('result', {}).get('result', {}).get('value')

async def main():
    async with websockets.connect(WS_URL, max_size=50*1024*1024) as ws:
        r = await send(ws, 1, JS_CLICK)
        print('CLICK:', r)
        await asyncio.sleep(6)
        val = await send(ws, 2, JS_TABLE)
        if val:
            data = json.loads(val)
            print('LINHAS:', data['numRows'])
            for row in data['rows']:
                print(' | '.join(row['colunas']), '=>', row['links'])
        else:
            print('SEM RESULTADO')

asyncio.run(main())
