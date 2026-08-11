import asyncio, json, sys

try:
    import websockets
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', 'websockets'])
    import websockets

WS_URL = 'ws://localhost:9222/devtools/page/EC7B60B7FDA2B24EEE6CAB97ECD02623'

JS_FILL = r"""
((di, df) => {
  function setVal(el, v) {
    const proto = el instanceof HTMLSelectElement ? HTMLSelectElement.prototype : HTMLInputElement.prototype;
    const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
    setter.call(el, v);
    el.dispatchEvent(new Event('input', {bubbles: true}));
    el.dispatchEvent(new Event('change', {bubbles: true}));
  }
  const tipo = document.getElementById('TipoPedido');
  const dIni = document.getElementById('DataInicial');
  const dFim = document.getElementById('DataFinal');
  if (!tipo || !dIni || !dFim) return 'CAMPOS NAO ENCONTRADOS';
  setVal(tipo, '5');
  setVal(dIni, di);
  setVal(dFim, df);
  return JSON.stringify({tipo: tipo.value, di: dIni.value, df: dFim.value});
})("01/08/2026", "09/08/2026")
"""

JS_CLICK = r"""
(() => {
  const btn = document.getElementById('btnSalvar');
  if (!btn) return 'BOTAO NAO ENCONTRADO';
  btn.click();
  return 'CLICADO';
})()
"""

JS_STATUS = r"""
(() => JSON.stringify({url: location.href, texto: document.body.innerText.substring(0, 1500)}))()
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
    res = data.get('result', {})
    if 'exceptionDetails' in res:
        return 'JS_ERROR: ' + json.dumps(res['exceptionDetails'])[:300]
    return res.get('result', {}).get('value')

async def main():
    async with websockets.connect(WS_URL, max_size=50*1024*1024) as ws:
        st = await evaljs(ws, 1, JS_STATUS)
        info = json.loads(st)
        if 'Solicitacao' not in info['url']:
            await send(ws, 2, 'Page.navigate', {'url': 'https://www.esocial.gov.br/portal/Download/Pedido/Solicitacao'})
            await asyncio.sleep(4)

        fill = await evaljs(ws, 3, JS_FILL)
        print('preenchido:', fill)
        await asyncio.sleep(0.5)
        click = await evaljs(ws, 4, JS_CLICK)
        print('salvar:', click)
        await asyncio.sleep(4)
        st = await evaljs(ws, 5, JS_STATUS)
        info = json.loads(st)
        txt = info['texto'].replace('\n', ' ')
        print('url:', info['url'])
        for palavra in ['sucesso', 'Sucesso', 'registrada', 'erro', 'Erro', 'limite', 'menor ou igual']:
            if palavra in txt:
                idx = txt.find(palavra)
                print('msg: ...' + txt[max(0,idx-120):idx+200] + '...')
                break

asyncio.run(main())
