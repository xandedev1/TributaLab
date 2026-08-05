"""Cliente CDP minimo para inspecionar e operar o navegador aberto em --remote-debugging-port."""

import json
import sys
import urllib.request

import websocket


def targets(port: int = 9222):
    raw = urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list", timeout=5).read()
    return [t for t in json.loads(raw) if t.get("type") == "page"]


def evaluate(expression: str, port: int = 9222, index: int = 0, timeout: int = 30):
    pages = targets(port)
    if not pages:
        return {"error": "nenhuma aba aberta"}
    ws = websocket.create_connection(pages[index]["webSocketDebuggerUrl"], timeout=timeout)
    try:
        ws.send(json.dumps({
            "id": 1,
            "method": "Runtime.evaluate",
            "params": {
                "expression": expression,
                "returnByValue": True,
                "awaitPromise": True,
            },
        }))
        while True:
            msg = json.loads(ws.recv())
            if msg.get("id") == 1:
                return msg
    finally:
        ws.close()


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if len(sys.argv) > 1 and sys.argv[1] == "list":
        for i, t in enumerate(targets()):
            print(f"{i}: {t.get('title')} | {t.get('url')}")
    else:
        expr = sys.stdin.read()
        idx = int(sys.argv[1]) if len(sys.argv) > 1 else 0
        out = evaluate(expr, index=idx)
        result = out.get("result", {}).get("result", {})
        if "exceptionDetails" in out.get("result", {}):
            print("ERRO:", json.dumps(out["result"]["exceptionDetails"], ensure_ascii=False)[:1500])
        else:
            value = result.get("value")
            print(value if isinstance(value, str) else json.dumps(value, ensure_ascii=False, indent=2))
