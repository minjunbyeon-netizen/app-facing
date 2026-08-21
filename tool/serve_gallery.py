# 골든 갤러리 로컬 서버 — 캐시 금지 헤더를 붙인다.
# 사용: python tool/serve_gallery.py [포트]   (기본 8123)
#
# 왜 필요했나 (2026-08-21): python -m http.server 로 띄우면 브라우저가 3MB HTML 을
# 캐시해, 골든을 새로 뽑아도 화면이 그대로였다. 새로고침해도 옛 화면이 보이는
# 착시를 없애려고 no-store 를 강제한다.
import functools
import http.server
import socketserver
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "build"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8123


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, *args):  # 조용히
        pass


if __name__ == "__main__":
    handler = functools.partial(NoCacheHandler, directory=str(ROOT))
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), handler) as httpd:
        print(f"serving {ROOT} at http://127.0.0.1:{PORT}/goldens_gallery.html")
        httpd.serve_forever()
