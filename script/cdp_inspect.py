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
  return JSON.stringify({
    url: location.href,
    title: document.title,
    bodyText: document.body ? document.body.innerText.substring(0, 3000) : 'SEM BODY',
    numTables: document.querySelectorAll('table').length,
    numForms: document.querySelectorAll('form').length,
    numIframes: document.querySelectorAll('iframe').length,
    inputs: Array.from(document.querySelectorAll('input, select, button')).map(e => ({tag: e.tagName, type: e.type, id: e.id, name: e.name, value: (e.value||'').substring(0,50), texto: (e.innerText||'').trim().substring(0,50)}))
  });
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
                    info = json.loads(val)
                    print('URL:', info['url'])
                    print('TITULO:', info['title'])
                    print('TABELAS:', info['numTables'], '| FORMS:', info['numForms'], '| IFRAMES:', info['numIframes'])
                    print('\n--- TEXTO DA PAGINA ---')
                    print(info['bodyText'])
                    print('\n--- INPUTS/BOTOES ---')
                    for i in info['inputs']:
                        print(i)
                else:
                    print('SEM RESULTADO:', json.dumps(data)[:800])
                break

asyncio.run(main())
