"""스토어 심사 제출 직전 자동 점검 — `python tool/store_preflight.py`

docs/STORE-SUBMIT-SHEET.md 가 약속한 사실이 **지금도 참인지** 실측한다. 문서만 믿고
제출했다가 반려되는 일을 막는 게이트 (2026-09-03 사용자 "테스트 무조건 통과하게").
전부 통과하면 exit 0, 하나라도 어긋나면 exit 1 + 어긋난 줄을 그대로 보여 준다.

검사 항목
  1. 공개 URL 4종(홈·방침·약관·삭제) + API health 가 200
  2. 공개 방침에 사라진 항목('착용 칭호')·옛 심사 아이디(googletest)가 없음
  3. 운영 서버 심사 계정 3개 로그인 200 (코치 role=coach · 회원 kind=member)
     — 비밀번호는 Railway 변수에서 읽는다 (`railway variables --json`, services/hyphen 에서
       링크된 서비스). 로컬에 railway CLI 가 없으면 이 항목은 SKIP 으로 표시한다.
  4. 스토어 에셋 규격 — 구글 폰 7장 1080×1920 · 애플 6.9" 7장 1320×2868 · 6.5" 7장
     1284×2778 · 아이콘 512 · 피처 1024×500, 그리고 그 파일들이 골든보다 새것
  5. 산출물 — AAB 가 pubspec 버전 이후에 만들어졌는지 (오래된 AAB 업로드 방지)
  6. 안드로이드 매니페스트에 위험 권한(카메라·위치·연락처·포그라운드 서비스) 없음
  7. iOS: PrivacyInfo.xcprivacy 가 프로젝트 Resources 에 등록, 러너 macos-26,
     ITSAppUsesNonExemptEncryption=false

값의 정본(아이디·URL·규격)은 이 파일 상단 상수 한 곳 — 시트와 어긋나면 시트를 고친다.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SERVER_DIR = ROOT.parent.parent / "services" / "hyphen"

API = "https://service-facing-production.up.railway.app"
URLS = {
    "홈페이지/지원 URL": "https://web-facing-production.up.railway.app/",
    "개인정보처리방침": "https://web-facing-admin-production-dca4.up.railway.app/privacy",
    "이용약관": "https://web-facing-admin-production-dca4.up.railway.app/terms",
    "계정 삭제 요청": "https://web-facing-admin-production-dca4.up.railway.app/delete-account",
    "API health": API + "/health",
}
# 공개 문서에 남아 있으면 안 되는 문구 (없어진 기능·옛 심사 아이디)
FORBIDDEN_IN_LEGAL = ("착용 칭호", "googletest")

# 심사 계정 — 아이디는 여기, 비밀번호는 Railway 변수 (공개 저장소라 코드에 안 적는다)
REVIEW_ACCOUNTS = (
    ("testcoach1", "REVIEW_COACH_PASSWORD", "coach"),
    ("testmember1", "REVIEW_MEMBER_PASSWORD", "member"),
    ("testmember2", "REVIEW_MEMBER2_PASSWORD", "member"),
)

STORE = ROOT / "build" / "store"
ASSETS = (
    ("phone_*.png", 7, (1080, 1920)),
    ("ios/6.9/*.png", 7, (1320, 2868)),
    ("ios/6.5/*.png", 7, (1284, 2778)),
    ("icon_512.png", 1, (512, 512)),
    ("feature_1024x500.png", 1, (1024, 500)),
)
GOLDENS = ROOT / "test" / "golden" / "goldens"
AAB = ROOT / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
MANIFEST = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
RISKY_PERMS = ("CAMERA", "ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION",
               "READ_CONTACTS", "FOREGROUND_SERVICE", "RECEIVE_BOOT_COMPLETED",
               "RECORD_AUDIO", "READ_MEDIA_IMAGES", "READ_EXTERNAL_STORAGE")

results: list[tuple[str, str, str]] = []  # (PASS|FAIL|SKIP, 항목, 상세)


def rec(ok: bool | None, name: str, detail: str = "") -> None:
    results.append(("SKIP" if ok is None else ("PASS" if ok else "FAIL"), name, detail))


def http(url: str, method: str = "GET", body: dict | None = None,
         headers: dict | None = None) -> tuple[int, bytes]:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, method=method, data=data,
                                 headers={"Content-Type": "application/json",
                                          "X-Device-Id": "store-preflight",
                                          **(headers or {})})
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:  # noqa: BLE001 — 네트워크 자체 실패도 FAIL 로 보여 준다
        return 0, str(e).encode()


def check_urls() -> None:
    for label, url in URLS.items():
        st, body = http(url)
        rec(st == 200, f"URL 200 — {label}", f"{st} {url}")
        if label in ("개인정보처리방침", "계정 삭제 요청") and st == 200:
            text = body.decode("utf-8", "replace")
            # 항목 목록(<li>)만 본다 — "최종 갱신 … 착용 칭호 항목 삭제" 같은 개정 이력 문장은
            # 그 단어를 담는 게 정상이라, 본문 전체를 검사하면 거짓 경보가 난다.
            items = " ".join(re.findall(r"<li[^>]*>(.*?)</li>", text, re.S))
            bad = [w for w in FORBIDDEN_IN_LEGAL if w in items or (w == "googletest" and w in text)]
            rec(not bad, f"공개 문서 항목에 금지 문구 없음 — {label}", ", ".join(bad) or "깨끗함")


def railway_vars() -> dict | None:
    if not SERVER_DIR.exists():
        return None
    try:
        # Windows 콘솔 기본 cp949 로 읽으면 한글 값(REVIEW_COACH_NAME)에서 디코드가 죽는다.
        out = subprocess.run(["railway", "variables", "--json"], cwd=SERVER_DIR,
                             capture_output=True, text=True, encoding="utf-8",
                             errors="replace", shell=True, timeout=60)
    except Exception:  # noqa: BLE001
        return None
    if out.returncode != 0 or not out.stdout.strip():
        return None
    try:
        return json.loads(out.stdout)
    except json.JSONDecodeError:
        return None


def check_accounts() -> None:
    env = railway_vars()
    if env is None:
        for lid, _, _ in REVIEW_ACCOUNTS:
            rec(None, f"운영 로그인 — {lid}", "railway CLI 없음/미링크 → 비밀번호를 못 읽어 SKIP")
        return
    ids = {x.strip().lower() for x in env.get("REVIEW_LOGIN_IDS", "").split(",") if x.strip()}
    rec(ids == {a[0] for a in REVIEW_ACCOUNTS},
        "REVIEW_LOGIN_IDS 가 심사 계정 3개와 일치", ",".join(sorted(ids)))
    for lid, pw_key, kind in REVIEW_ACCOUNTS:
        pw = (env.get(pw_key) or "").strip()
        if not pw:
            rec(False, f"운영 로그인 — {lid}", f"Railway 변수 {pw_key} 비어 있음")
            continue
        st, body = http(API + "/api/v1/auth/login", "POST", {"login_id": lid, "password": pw})
        data = {}
        try:
            data = json.loads(body.decode() or "{}").get("data") or {}
        except json.JSONDecodeError:
            pass
        ok = st == 200 and ((kind == "coach" and data.get("role") == "coach")
                            or (kind == "member" and data.get("kind") == "member"))
        rec(ok, f"운영 로그인 — {lid}",
            f"{st} name={data.get('name')} role={data.get('role')} kind={data.get('kind')}")


def check_assets() -> None:
    try:
        from PIL import Image
    except ImportError:
        rec(None, "스토어 에셋 규격", "Pillow 미설치 → SKIP")
        return
    newest_golden = max((p.stat().st_mtime for p in GOLDENS.glob("*.png")), default=0)
    for pattern, count, size in ASSETS:
        files = sorted(STORE.glob(pattern))
        bad = []
        for f in files:
            with Image.open(f) as im:
                if im.size != size:
                    bad.append(f"{f.name}={im.size[0]}x{im.size[1]}")
        stale = [f.name for f in files if f.stat().st_mtime < newest_golden]
        ok = len(files) == count and not bad and not stale
        detail = f"{len(files)}/{count}장"
        if bad:
            detail += " 규격 불일치 " + ", ".join(bad)
        if stale:
            detail += " 골든보다 오래됨 " + ", ".join(stale)
        rec(ok, f"스토어 에셋 — {pattern} {size[0]}x{size[1]}", detail)
    # 스크린샷 안에 사라진 표기가 없는지는 골든 fakes 가 정본 — 문자열로 확인
    fakes = (ROOT / "test" / "golden" / "fakes.dart").read_text(encoding="utf-8")
    rec("WOD Class" not in fakes and "Morning WOD" not in fakes,
        "골든 가짜 수업명에 'WOD' 없음", "fakes.dart")


def check_build() -> None:
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    ver = re.search(r"^version:\s*(\S+)", pubspec, re.M)
    rec(bool(ver), "pubspec version", ver.group(1) if ver else "없음")
    if AAB.exists():
        fresh = AAB.stat().st_mtime >= (ROOT / "pubspec.yaml").stat().st_mtime
        rec(fresh, "AAB 가 pubspec 이후 빌드", f"{AAB.stat().st_size // 1024 // 1024}MB {AAB.name}")
    else:
        rec(False, "AAB 존재", "flutter build appbundle --release --dart-define=API_BASE_URL=" + API)
    manifest = MANIFEST.read_text(encoding="utf-8")
    perms = re.findall(r'uses-permission android:name="android\.permission\.([A-Z_]+)"', manifest)
    risky = [p for p in perms if p in RISKY_PERMS]
    rec(not risky, "매니페스트 위험 권한 없음", ", ".join(perms))
    rec('android:allowBackup="false"' in manifest, "allowBackup=false", "")


def check_ios() -> None:
    pbx = (ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    rec((ROOT / "ios" / "Runner" / "PrivacyInfo.xcprivacy").exists()
        and "PrivacyInfo.xcprivacy in Resources" in pbx,
        "iOS PrivacyInfo.xcprivacy 등록", "")
    plist = (ROOT / "ios" / "Runner" / "Info.plist").read_text(encoding="utf-8")
    rec("<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>" in plist,
        "ITSAppUsesNonExemptEncryption=false", "")
    wf = (ROOT / ".github" / "workflows" / "ios.yml").read_text(encoding="utf-8")
    rec("runs-on: macos-26" in wf and "runs-on: macos-15" not in wf,
        "iOS 러너 macos-26 (Xcode 26 SDK)", "")


def main() -> int:
    for fn in (check_urls, check_accounts, check_assets, check_build, check_ios):
        try:
            fn()
        except Exception as e:  # noqa: BLE001
            rec(False, fn.__name__, f"예외 {e!r}")
    width = max(len(n) for _, n, _ in results)
    for status, name, detail in results:
        print(f"[{status}] {name.ljust(width)}  {detail}")
    fails = [r for r in results if r[0] == "FAIL"]
    skips = [r for r in results if r[0] == "SKIP"]
    print(f"\n{len(results) - len(fails) - len(skips)} PASS · {len(fails)} FAIL · {len(skips)} SKIP")
    return 1 if fails else 0


if __name__ == "__main__":
    os.environ.setdefault("PYTHONIOENCODING", "utf-8")
    sys.exit(main())
