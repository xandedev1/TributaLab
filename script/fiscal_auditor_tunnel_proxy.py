from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from http.client import HTTPConnection
import os


UPSTREAM_HOST = "127.0.0.1"
UPSTREAM_PORT = int(os.environ.get("FISCAL_AUDITOR_UPSTREAM_PORT", "3101"))
LISTEN_PORT = int(os.environ.get("FISCAL_AUDITOR_PROXY_PORT", "3102"))
ALLOWED_PREFIXES = ("/auditor-fiscal", "/assets/")
HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class FiscalAuditorProxy(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        self._proxy()

    def do_HEAD(self):
        self._proxy()

    def do_POST(self):
        self._proxy()

    def do_DELETE(self):
        self._proxy()

    def _proxy(self):
        if not self.path.startswith(ALLOWED_PREFIXES):
            self.send_error(404)
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(content_length) if content_length else None
        headers = {
            name: value
            for name, value in self.headers.items()
            if name.lower() not in HOP_BY_HOP_HEADERS and name.lower() != "host"
        }
        headers["Host"] = f"localhost:{UPSTREAM_PORT}"
        headers["X-Forwarded-Proto"] = "https"
        if "Origin" in headers:
            headers["Origin"] = f"https://localhost:{UPSTREAM_PORT}"
        if "Referer" in headers:
            referer_path = self.headers["Referer"].split("/", 3)[-1]
            headers["Referer"] = f"https://localhost:{UPSTREAM_PORT}/{referer_path}"

        connection = HTTPConnection(UPSTREAM_HOST, UPSTREAM_PORT, timeout=60)
        try:
            connection.request(self.command, self.path, body=body, headers=headers)
            response = connection.getresponse()
            payload = response.read()
            self.send_response(response.status, response.reason)
            for name, value in response.getheaders():
                if name.lower() not in HOP_BY_HOP_HEADERS and name.lower() != "content-length":
                    if name.lower() == "location":
                        value = value.replace(f"https://localhost:{UPSTREAM_PORT}", "")
                        value = value.replace(f"http://localhost:{UPSTREAM_PORT}", "")
                    self.send_header(name, value)
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(payload)
        finally:
            connection.close()

    def log_message(self, message, *args):
        print(f"{self.client_address[0]} {message % args}", flush=True)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", LISTEN_PORT), FiscalAuditorProxy).serve_forever()