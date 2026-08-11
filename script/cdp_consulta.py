import asyncio, json, sys

try:
    import websockets
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', 'websockets'])
    import websockets

WS_URL = 'ws://localhost:9222/devtools/page/EC7B60B7FDA2B24EEE6CAB97ECD02623'

JS = r"""
(() => {
  const rows = document.querySelectorAll('table tr');
  const out = [];
  rows.forEach(tr => {
    const tds = tr.querySelectorAll('td');
    if (tds.length > 0) {
      const textos = Array.from(tds).map(td => td.innerText.trim().replace(/\s+/g, ' '));
      const link = tr.querySelector('a[href*="Download"]');
      out.push({colunas: textos, download: link ? link.href : null});
    }
  });
  return JSON.stringify(out);
})()
"""

async def main():
    async with websockets.connect(WS_URL, max_size=50*1024*1024) as ws:
        await ws.send(json.dumps({'id': 1, 'method': 'Runtime.evaluate', 'params': {'expression': JS, 'returnByValue': True}}))
        while True:
            resp = await ws.recv()
            data = json.loads(resp)
            if data.get('id') == 1:
                val = data.get('result', {}).get('result', {}).get('value')
                if val:
                    rows = json.loads(val)
                    for r in rows:
                        print(' | '.join(r['colunas']), '=>', r['download'] or '')
                else:
                    print('SEM RESULTADO:', json.dumps(data)[:500])
                break

asyncio.run(main())
