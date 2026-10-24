"""Учебные веб-сервисы лаборатории. Роль задаётся переменной ROLE.

portal   (portal.test)   80 HTTP, 443 HTTPS, 8443 обычный HTTP на «HTTPS-похожем» порту
archive  (archive.test)  80 HTTP
delivery (delivery.test) 80 и 8080 HTTP, «внешний» сервер за NAT
"""
import datetime
import os
import ssl
import threading
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROLE = os.environ.get("ROLE", "portal")
LOG_PATH = "/logs/portal.log"
log_lock = threading.Lock()


def log(level, request_id, message):
    if ROLE != "portal":
        return
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")[:-4] + "Z"
    line = f"{stamp} {level} request_id={request_id} {message}\n"
    with log_lock, open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line)


class Handler(BaseHTTPRequestHandler):
    server_version = "LabServer/1.0"
    sys_version = ""

    def log_message(self, *args):
        pass

    def reply(self, status, body, request_id):
        data = (body + "\n").encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-Request-ID", request_id)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        request_id = "r-" + uuid.uuid4().hex[:8]
        client = self.client_address[0]
        port = self.server.server_address[1]
        path = self.path.split("?")[0]
        status, body = self.route(path, client, port, request_id)
        log("INFO", request_id, f"client={client} port={port} GET {path} status={status}")
        self.reply(status, body, request_id)

    def route(self, path, client, port, request_id):
        if path == "/whoami":
            return 200, f"Сервер {ROLE} видит ваш адрес как: {client}"
        if ROLE == "portal":
            if path == "/":
                return 200, "Учебный портал portal.test. Страницы: /menu, /order, /whoami"
            if path == "/menu":
                return 200, "OK"
            if path == "/order":
                log("ERROR", request_id, "cannot open /data/orders.db: permission denied")
                return 500, f"Внутренняя ошибка сервера. Номер запроса: {request_id}"
        elif ROLE == "archive" and path == "/":
            return 200, "Архив документов archive.test работает."
        elif ROLE == "delivery" and path == "/":
            return 200, f"Служба доставки delivery.test, порт {port}."
        return 404, "Страница не найдена"


def serve(port, tls=False):
    httpd = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    if tls:
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain("/etc/lab-tls/portal.crt", "/etc/lab-tls/portal.key")
        httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()


PORTS = {
    "portal": [(80, False), (443, True), (8443, False)],
    "archive": [(80, False)],
    "delivery": [(80, False), (8080, False)],
}

if __name__ == "__main__":
    if ROLE == "portal":
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    for port, tls in PORTS[ROLE]:
        serve(port, tls)
    print(f"{ROLE}: слушаю порты {[p for p, _ in PORTS[ROLE]]}", flush=True)
    threading.Event().wait()
