import asyncio, json, sys

try:
    import websockets
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', 'websockets'])
    import websockets

WS_URL = 'ws://localhost:9222/devtools/page/EC7B60B7FDA2B24EEE6CAB97ECD02623'

MESES = [
    ('01/04/2026', '30/04/2026', 'abril'),
    ('01/05/2026', '31/05/2026', 'maio'),
    ('01/06/2026', '30/06/2026', 'junho'),
    ('01/07/2026', '31/07/2026', 'julho'),
    ('01/08/2026', '31/08/2026', 'agosto'),
    ('01/09/2026', '30/09/2026', 'setembro'),
    ('01/10/2026', '31/10/2026', 'outubro'),
    ('01/11/2026', '30/11/2026', 'novembro'),
    ('01/12/2026', '31/12/2026', 'dezembro'),
]

JS_FILL = r"""
((di, df) => {
  // seta valor com evento pra frameworks reativos
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
})(%s, %s)
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
(() => {
  return JSON.stringify({url: location.href, texto: document.body.innerText.substring(0, 1200)});
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
    res = data.get('result', {})
    if 'exceptionDetails' in res:
        return 'JS_ERROR: ' + json.dumps(res['exceptionDetails'])[:300]
    return res.get('result', {}).get('value')

async def main():
    async with websockets.connect(WS_URL, max_size=50*1024*1024) as ws:
        mid = 100
        for di, df, nome in MESES:
            # garante que estamos na pagina de solicitacao
            st = await evaljs(ws, mid, JS_STATUS); mid += 1
            info = json.loads(st)
            if 'Solicitacao' not in info['url']:
                await send(ws, mid, 'Page.navigate', {'url': 'https://www.esocial.gov.br/portal/Download/Pedido/Solicitacao'}); mid += 1
                await asyncio.sleep(4)

            fill = await evaljs(ws, mid, JS_FILL % (json.dumps(di), json.dumps(df))); mid += 1
            print(f'[{nome}] preenchido: {fill}')
            await asyncio.sleep(0.5)

            click = await evaljs(ws, mid, JS_CLICK); mid += 1
            print(f'[{nome}] salvar: {click}')
            await asyncio.sleep(4)

            st = await evaljs(ws, mid, JS_STATUS); mid += 1
            info = json.loads(st)
            txt = info['texto'].replace('\n', ' ')
            print(f'[{nome}] resultado url={info["url"]}')
            # procura mensagem de sucesso/erro
            for palavra in ['sucesso', 'Sucesso', 'registrada', 'erro', 'Erro', 'limite']:
                if palavra in txt:
                    idx = txt.find(palavra)
                    print(f'[{nome}] msg: ...{txt[max(0,idx-100):idx+200]}...')
                    break

asyncio.run(main())
