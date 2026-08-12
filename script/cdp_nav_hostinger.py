import subprocess
import time
import json
import urllib.request

# Start Brave with remote debugging
brave_path = r"C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
subprocess.Popen([
    brave_path,
    "--remote-debugging-port=9222",
    "--user-data-dir=C:\\Users\\xandao\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data\\CDP",
    "https://realaudittech.com/auditor-fiscal/login"
])

print("Brave opened. Waiting for you to login...")
print("Monitoring every 10 seconds...")

# Wait for login (check if we can access the companies page)
logged_in = False
for i in range(60):  # 10 minutes max
    time.sleep(10)
    try:
        req = urllib.request.Request("http://localhost:9222/json")
        with urllib.request.urlopen(req, timeout=5) as resp:
            tabs = json.loads(resp.read().decode())
            for tab in tabs:
                url = tab.get("url", "")
                title = tab.get("title", "")
                print(f"[{i*10}s] {title[:50]} | {url[:80]}")
                if "empresas" in url or ("auditor-fiscal" in url and "login" not in url):
                    logged_in = True
                    print("\n>>> LOGIN DETECTED! <<<")
                    break
            if logged_in:
                break
    except Exception as e:
        print(f"[{i*10}s] Error: {e}")

if logged_in:
    print("\nNavigating to Cruzamento EFD x Razao...")
    # Navigate to the page
    try:
        req = urllib.request.Request("http://localhost:9222/json")
        with urllib.request.urlopen(req, timeout=5) as resp:
            tabs = json.loads(resp.read().decode())
            for tab in tabs:
                if "auditor-fiscal" in tab.get("url", ""):
                    ws_url = tab["webSocketDebuggerUrl"]
                    print(f"Found tab: {tab['url']}")
                    # Use websocket to navigate
                    import websocket
                    ws = websocket.create_connection(ws_url)
                    ws.send(json.dumps({
                        "id": 1,
                        "method": "Page.navigate",
                        "params": {"url": "https://realaudittech.com/auditor-fiscal/cruzamento-efd-razao"}
                    }))
                    print("Navigated to Cruzamento EFD x Razao")
                    ws.close()
                    break
    except Exception as e:
        print(f"Error navigating: {e}")
else:
    print("\nTimeout waiting for login.")
