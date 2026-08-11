import asyncio, json, sys

try:
    import websockets
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', 'websockets'])
    import websockets

WS_URL = 'ws://localhost:9222/devtools/page/EC7B60B7FDA2B24EEE6CAB97ECD02623'

async def send(ws, mid, method, params=None):
    await ws.send(json.dumps({'id': mid, 'method': method, 'params': params or {}}))
    while True:
        resp = await ws.recv()
        data = json.loads(resp)
        if data.get('id') == mid:
            return data

async def evaljs(ws, mid, expr):
    data = await send(ws, mid, 'Runtime.evaluate', {'expression': expr, 'returnByValue': True})
    return data.get('result', {}).get('result', {}).get('value')

JS_INSPECT = r"""
(() => {
  return JSON.stringify({
    url: location.href,
    bodyText: document.body.innerText.substring(0, 2500),
    inputs: Array.from(document.querySelectorAll('input, select, button')).map(e => ({tag: e.tagName, type: e.type, id: e.id, name: e.name, value: (e.value||'').substring(0,60), texto: (e.innerText||'').trim().substring(0,60)}))
  });
})()
"""

async def main():
    async with websockets.connect(WS_URL, max_size=50*1024*1024) as ws:
        await send(ws, 1, 'Page.navigate', {'url': 'https://www.esocial.gov.br/portal/Download/Pedido/Solicitacao'})
        await asyncio.sleep(5)
        val = await evaljs(ws, 2, JS_INSPECT)
        info = json.loads(val)
        print('URL:', info['url'])
        print('\n--- TEXTO ---')
        print(info['bodyText'])
        print('\n--- CAMPOS ---')
        for i in info['inputs']:
            print(i)

asyncio.run(main())
