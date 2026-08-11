import asyncio, json, sys

try:
    import websockets
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', 'websockets'])
    import websockets

WS_URL = 'ws://localhost:9222/devtools/page/EC7B60B7FDA2B24EEE6CAB97ECD02623'

JS_OPTIONS = r"""
(() => {
  const sel = document.getElementById('TipoPedido');
  return JSON.stringify(Array.from(sel.options).map(o => ({value: o.value, text: o.text})));
})()
"""

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

async def main():
    async with websockets.connect(WS_URL, max_size=50*1024*1024) as ws:
        val = await evaljs(ws, 1, JS_OPTIONS)
        print(json.dumps(json.loads(val), indent=2, ensure_ascii=False))

asyncio.run(main())
