import asyncio, json, sys

try:
    import websockets
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', 'websockets'])
    import websockets

WS_URL = 'ws://localhost:9222/devtools/page/EC7B60B7FDA2B24EEE6CAB97ECD02623'

async def main():
    async with websockets.connect(WS_URL, max_size=50*1024*1024) as ws:
        await ws.send(json.dumps({'id': 1, 'method': 'Page.navigate', 'params': {'url': 'https://www.esocial.gov.br/portal/Download/Pedido/Consulta'}}))
        resp = await ws.recv()
        print('NAV:', resp[:200])
        await asyncio.sleep(5)
        await ws.send(json.dumps({'id': 2, 'method': 'Runtime.evaluate', 'params': {'expression': 'document.title + " | " + location.href', 'returnByValue': True}}))
        resp = await ws.recv()
        data = json.loads(resp)
        print('PAGE:', data.get('result', {}).get('result', {}).get('value'))

asyncio.run(main())
