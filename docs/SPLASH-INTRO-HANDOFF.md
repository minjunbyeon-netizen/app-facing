# 스플래시 HYPEE 등장 연출 — 이식 인계장

> **작성** 2026-08-21 19:40 · 별도 세션(cwd `C:\dev\services\video`)에서 설계·검증 후 넘김
> **이 문서 하나로 끝난다.** 대표 결정은 이미 났다 — 물어볼 것 없이 §3 스텝 1~4 를 실행하면 된다.
> **앱 코드는 아직 무변경이다.** 이 문서와 대기 항목 한 줄만 추가돼 있다.

---

## 0. 30초 요약

캐릭터(HYPEE) 전신 액션 **11장이 카드로 착착 쌓이는 연출**을 **스플래시 화면**에 넣는다.
앱을 켤 때마다 재생된다. 약 1.1초 걸리고, 스플래시가 어차피 2.5초를 기다리므로 **체감 지연은 0이다.**

- 연출 시안 4개를 웹 데모로 만들어 실제로 돌려 보고 대표가 **4안(카드 쌓기)** 을 골랐다.
- 데모: `C:\dev\services\design\_작업\앱에셋\온보딩연출데모.html` — 더블클릭하면 브라우저에서 4안이 동시에 돈다.
- 이 문서의 §4 표가 데모에서 실측·확정한 값이다. **감으로 다시 정하지 말고 그 숫자를 쓴다.**

---

## 1. 대표 결정 (2026-08-21 19:31 · 확정 — 다시 묻지 말 것)

### ① 연출 = 4안 카드 쌓기

아래에서 카드가 부채꼴로 하나씩 올라와 쌓이고, 마지막 장(`cheer` = 두 팔 든 환호)이 맨 앞에 선다.

> **캐릭터 그림은 배경이 투명이라 그냥 겹치면 뭉갠다.**
> 반드시 카드 면(배경·테두리·라운드)을 씌운 뒤 겹칠 것. 데모 첫 버전이 이걸 빠뜨려 실패했다.

### ② 위치 = 스플래시 · 앱 켤 때마다 재생

대표 표현: *"앱을 껐다가 다시 켜면 보이면 좋겠는데, 첫 구동 때 보인다고 해야 하나?"*

원하는 것은 **앱 실행할 때마다**다. "첫 구동"은 설치 후 딱 한 번을 뜻하므로 그게 아니다.
→ **`shared_preferences` 1회 플래그를 만들지 않는다.** 스플래시가 뜰 때마다 그냥 재생한다.

> ⚠ **인트로 화면(`/intro`) 부활이 아니다.**
> v2.3(2026-08-12 사용자 지시)에서 "첫 실행 인트로 3장"을 없앴고,
> v3.3(2026-08-21, 커밋 `fb7ae8c`)에서 `/intro` 라우트와 `lib/features/intro/intro_screen.dart` 를 코드째 지웠다.
> **지운 상태 그대로 둔다.** `splash_screen.dart` 에만 얹는다.

---

## 2. 쓰는 그림 — 전신 액션 11종

원본은 이미 3배율까지 다 뽑혀 있다. **새로 만들거나 생성할 것이 없다.**

```
C:\dev\services\design\_작업\앱에셋\flutter\        ← 1.0x (루트)
C:\dev\services\design\_작업\앱에셋\flutter\2.0x\
C:\dev\services\design\_작업\앱에셋\flutter\3.0x\
```

**등장 순서 = 운동 하루의 흐름** (이 순서가 연출의 뼈대다. 바꾸면 이야기가 깨진다)

| # | 파일 | 장면 |
|---|---|---|
| 0 | `hypee_hesitate.webp` | 문 앞에서 망설임 |
| 1 | `hypee_stretch.webp` | 스트레칭 |
| 2 | `hypee_jumprope.webp` | 줄넘기 |
| 3 | `hypee_kettlebell.webp` | 케틀벨 |
| 4 | `hypee_battlerope.webp` | 배틀로프 |
| 5 | `hypee_wallball.webp` | 월볼 |
| 6 | `hypee_boxjump.webp` | 박스점프 |
| 7 | `hypee_rest.webp` | 휴식(물 마시기) |
| 8 | `hypee_scale.webp` | 체중계 |
| 9 | `hypee_thumbsup.webp` | 엄지척 |
| 10 | `hypee_cheer.webp` | 환호 ← **맨 앞에 서는 카드** |

**얼굴만 나오는 표정 9종**(`calm·determined·happy·smug·struggle·surprised·tired·wink·worried`)은 **쓰지 않는다.**
사용자 지시다. 전신은 30~67KB, 얼굴만은 3~4KB로 파일 크기가 갈리니 헷갈리면 크기로 확인하면 된다.

---

## 3. 이식 절차

### 스텝 1 — 에셋을 앱에 넣는다

**`assets/character/` 에 그냥 쏟아붓지 말 것.** 그 폴더는 스낵바 전용 3장(`happy·sad·neutral`)의 자리이고,
`assets/character/README.md` 에 *"여기 있는 그림만 앱에 나온다 / 3장이면 끝이다"* 규칙이 박혀 있다.
**`assets/character/action/` 하위 폴더를 새로 판다.**

```bash
SRC="C:/dev/services/design/_작업/앱에셋/flutter"
DST="C:/dev/apps/hyphen-app/assets/character/action"
mkdir -p "$DST/2.0x" "$DST/3.0x"
for k in hesitate stretch jumprope kettlebell battlerope wallball boxjump rest scale thumbsup cheer; do
  cp "$SRC/hypee_$k.webp"      "$DST/"
  cp "$SRC/2.0x/hypee_$k.webp" "$DST/2.0x/"
  cp "$SRC/3.0x/hypee_$k.webp" "$DST/3.0x/"
done
```

`pubspec.yaml` 의 assets 목록에 한 줄 추가한다 (`- assets/character/` 바로 아래).
2.0x·3.0x 는 Flutter 가 자동으로 배율 변형으로 인식하므로 따로 적지 않는다.

```yaml
    - assets/character/
    # 스플래시 등장 연출용 전신 액션 11종 (2026-08-21). 스낵바 3장과 성격이 달라
    # 하위 폴더로 분리한다 — 규칙 = assets/character/README.md
    - assets/character/action/
```

`assets/character/README.md` 에도 이 폴더가 생겼다는 사실을 한 문단 적어 둔다.
그 README 는 지금 "3장이면 끝"이라고만 말하고 있어, 그대로 두면 다음 사람이 액션 11종을 이물질로 본다.

### 스텝 2 — 경로 문자열은 `mascot.dart` 안에만 (SSOT)

`lib/widgets/mascot.dart` 헤더 주석의 규칙이다: **"경로 문자열은 이 파일 밖에 두지 않는다."**
액션 11종도 같은 파일에 등록한다. 기존 `MascotMood`(스낵바 3종)와 **섞지 말고 옆에 나란히** 둔다 — 성격이 다르다.

```dart
/// 스플래시 등장 연출용 전신 액션. 스낵바 표정(MascotMood)과 별개다 —
/// 저쪽은 "성격 3종을 전 화면이 돌려 쓴다", 이쪽은 "한 번에 다 나오는 한 벌"이다.
enum HypeeAction {
  hesitate, stretch, jumprope, kettlebell, battlerope,
  wallball, boxjump, rest, scale, thumbsup, cheer,
}

class HypeeActions {
  const HypeeActions._();

  /// 등장 순서 = 운동 하루의 흐름 (망설임 → 준비 → 운동 → 휴식 → 결과 → 환호).
  /// 마지막 cheer 가 카드 덱 맨 앞에 선다.
  static const List<HypeeAction> introSequence = [
    HypeeAction.hesitate, HypeeAction.stretch, HypeeAction.jumprope,
    HypeeAction.kettlebell, HypeeAction.battlerope, HypeeAction.wallball,
    HypeeAction.boxjump, HypeeAction.rest, HypeeAction.scale,
    HypeeAction.thumbsup, HypeeAction.cheer,
  ];

  static const Map<HypeeAction, String> _assets = {
    HypeeAction.hesitate:   'assets/character/action/hypee_hesitate.webp',
    HypeeAction.stretch:    'assets/character/action/hypee_stretch.webp',
    HypeeAction.jumprope:   'assets/character/action/hypee_jumprope.webp',
    HypeeAction.kettlebell: 'assets/character/action/hypee_kettlebell.webp',
    HypeeAction.battlerope: 'assets/character/action/hypee_battlerope.webp',
    HypeeAction.wallball:   'assets/character/action/hypee_wallball.webp',
    HypeeAction.boxjump:    'assets/character/action/hypee_boxjump.webp',
    HypeeAction.rest:       'assets/character/action/hypee_rest.webp',
    HypeeAction.scale:      'assets/character/action/hypee_scale.webp',
    HypeeAction.thumbsup:   'assets/character/action/hypee_thumbsup.webp',
    HypeeAction.cheer:      'assets/character/action/hypee_cheer.webp',
  };

  static String assetFor(HypeeAction a) => _assets[a]!;
}
```

### 스텝 3 — 연출 위젯 `lib/widgets/hypee_intro.dart` (신규)

뼈대는 **스플래시가 이미 쓰는 방식 그대로**다. `splash_screen.dart` 의 `_opacities`/`_slides`
6슬롯 Interval 패턴을 11슬롯으로 늘린 것이 전부다.

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'mascot.dart';

/// 스플래시 카드 덱 연출 — 캐릭터 11장이 아래에서 부채꼴로 쌓인다.
///
/// 값의 출처: `docs/SPLASH-INTRO-HANDOFF.md` §4 (웹 데모에서 실측·대표 확정).
/// 감으로 조정하지 말 것 — 데모(`services/design/_작업/앱에셋/온보딩연출데모.html`)와
/// 같은 그림이 나와야 한다.
class HypeeIntroDeck extends StatefulWidget {
  const HypeeIntroDeck({super.key});

  @override
  State<HypeeIntroDeck> createState() => _HypeeIntroDeckState();
}

class _HypeeIntroDeckState extends State<HypeeIntroDeck>
    with SingleTickerProviderStateMixin {
  static const int _gapMs = 90;   // 장 사이 간격
  static const int _durMs = 200;  // 장별 등장 시간
  late final int _totalMs;

  late final AnimationController _ctrl;
  late final List<Animation<double>> _t;   // 장별 진행도 0→1

  List<HypeeAction> get _seq => HypeeActions.introSequence;

  @override
  void initState() {
    super.initState();
    final n = _seq.length;
    _totalMs = (n - 1) * _gapMs + _durMs;   // 11장 → 1100ms

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    );

    _t = List.generate(n, (i) {
      final start = (i * _gapMs) / _totalMs;
      final end = (i * _gapMs + _durMs) / _totalMs;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 11장을 거의 동시에 디코딩한다 — 미리 올려 두지 않으면 첫 장이 늦게 뜬다.
    for (final a in _seq) {
      precacheImage(AssetImage(HypeeActions.assetFor(a)), context);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final mid = (_seq.length - 1) / 2;

        return Stack(
          alignment: Alignment.center,
          children: List.generate(_seq.length, (i) {
            final offsetFromMid = i - mid;
            final angle = offsetFromMid * 4.6 * math.pi / 180;   // 양끝 ±23°
            final dx = offsetFromMid * 0.042 * w;                // 양끝 ±21%
            final dy = (offsetFromMid.abs() * 0.016 - 0.06) * h; // 바깥이 처져 부채꼴
            final enterDy = 0.44 * h;                            // 아래에서 올라오는 거리

            return AnimatedBuilder(
              animation: _t[i],
              builder: (context, child) {
                final t = _t[i].value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(dx, dy + enterDy * (1 - t)),
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
                    ),
                  ),
                );
              },
              child: _card(w, h, _seq[i]),
            );
          }),
        );
      },
    );
  }

  Widget _card(double w, double h, HypeeAction a) => Container(
        width: w * 0.62,
        height: h * 0.46,
        padding: const EdgeInsets.all(HyphenTokens.sp3),
        decoration: BoxDecoration(
          color: HyphenTokens.surface,
          border: Border.all(color: HyphenTokens.border),
          borderRadius: BorderRadius.circular(HyphenTokens.r3),
        ),
        child: Image.asset(
          HypeeActions.assetFor(a),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
}
```

> **그림자를 넣지 말 것.** 글로벌 §2-B 가 다중 box-shadow 를 차단한다. 카드 구분은 테두리 1px 로 충분하다.
> `Stack` 자식 순서가 곧 겹침 순서다 — 뒤에 그려지는 `cheer`(i=10)가 맨 앞에 선다. 순서를 뒤집지 말 것.

### 스텝 4 — 스플래시에 배치

`lib/features/splash/splash_screen.dart` `build()` 의 **`const Spacer()` 자리**에 넣는다.

```dart
// 현재
_fadeSlide(0, const Center(child: BrandLogo())),
const Spacer(),
_fadeOnly(2, const HkLoading()),

// 이후
_fadeSlide(0, const Center(child: BrandLogo())),
const Expanded(child: HypeeIntroDeck()),
_fadeOnly(2, const HkLoading()),
```

**로고 자리는 건드리지 말 것.** v3.3 에서 "로그인 화면과 로고 위치를 맞춰 전환 때 로고가 안 뛰게" 고정한 것이라
(`HkEntryLogoGap`), 연출을 넣느라 로고를 밀면 그 작업이 깨진다.

**타이밍은 손댈 것이 없다.** 연출 1100ms < `AppKit.splashMin` 2500ms.
연출 컨트롤러는 기존 `_ctrl`(1500ms)과 **별도**로 둔다 — 위 위젯이 자기 컨트롤러를 갖고 있으므로
스플래시의 6슬롯 Interval 을 건드릴 일이 없다.

---

## 4. 확정 값 (데모 실측 — 그대로 쓸 것)

| 항목 | 값 | 비고 |
|---|---|---|
| 장 수 | 11 | 전신 액션만 |
| 장 사이 간격 | **90ms** | 60ms 아래로 내리면 뭐가 지나갔는지 안 읽힌다 |
| 장별 등장 시간 | **200ms** | `Curves.easeOutCubic` |
| 전체 길이 | **1100ms** | (11-1)×90 + 200 |
| 회전 | `(i - 5) × 4.6°` | 양끝 ±23° |
| 가로 위치 | `(i - 5) × 4.2%` (폭 기준) | 양끝 ±21% |
| 세로 위치 | `|i - 5| × 1.6% - 6%` (높이 기준) | 바깥 카드가 처져 부채꼴이 된다 |
| 등장 전 | 위 위치 + `y +44%`, `scale 0.8`, `opacity 0` | 아래에서 올라온다 |
| 등장 후 | 위 위치, `scale 1.0`, `opacity 1` | |
| 카드 크기 | 폭 **62%** × 높이 **46%** | 연출 영역 기준 |
| 카드 여백 | `sp3`(12) · 라운드 `r3`(12) · 테두리 1px | `surface` 배경, `border` 테두리 |

**화면 문구는 없다.** 데모의 회색 막대는 "문구가 들어갈 자리"를 표시한 것일 뿐,
이번 연출은 문구 없이 성립한다. 필요해지면 사용자에게 받아서 앉힌다 — **지어내지 말 것.**

---

## 5. 검증

```bash
cd C:/dev/apps/hyphen-app
flutter analyze                    # 0 이어야 한다
flutter test                       # 기존 170개 통과 유지
```

**골든이 반드시 깨진다.** `test/golden/screens_golden_test.dart:93` 의 `common: splash` 가
애니메이션 완료(1.3초) 시점을 캡처하는데, 그 시점이면 카드 덱이 다 쌓여 있다.

```bash
flutter test --update-goldens test/golden/screens_golden_test.dart
```

⚠ 갱신 전에 **`test/golden/failures/` 의 diff 이미지를 눈으로 확인**할 것.
"카드 덱이 제대로 쌓인 그림"으로 바뀐 것인지, 레이아웃이 깨진 것인지는 사람이 봐야 안다.

마지막으로 **실기 확인**. 웹 데모에서 매끄러워도 저사양 실기에서는 프레임이 튈 수 있다.
갤S22 릴리즈 APK로 확인하고, 버벅이면 `_durMs`를 늘리는 것이 아니라 이미지 크기(3.0x 제외)부터 의심한다.

---

## 6. 함정 (같은 데서 두 번 넘어지지 말 것)

1. **카드 면을 빼면 뭉갠다.** 배경 투명 그림을 부채꼴로 겹치면 실루엣이 뒤엉킨다. 데모 첫 버전의 실패다.
2. **`assets/character/` 루트에 11장을 넣지 말 것.** 그 폴더는 스낵바 3장 전용이고 README 규칙이 있다.
3. **`/intro` 를 되살리지 말 것.** 오늘 지운 것이다. 스플래시에만 얹는다.
4. **1회 플래그를 만들지 말 것.** 대표는 "켤 때마다"를 원했다.
5. **로고 위치를 밀지 말 것.** `HkEntryLogoGap` 은 로그인 화면과 자리를 맞추려고 고정한 값이다.
6. **`services/design` 은 독립 repo 가 아니다.** `dev-root` 의 `.gitignore:60` 이 `services/` 를 통째로 무시한다 —
   데모 HTML·빌드 스크립트는 git 에 안 올라간다(정상). 로컬 파일이 유일본이다.
7. 이 repo 루트에 **`.nopush` 마커**가 있다. 커밋은 자유, push 는 훅이 사람 확인을 받는다.
8. **`Get-Process python | Stop-Process` 금지.** 설계 세션에서 임시 웹서버를 정리하다 autocomfy MCP 서버까지 죽였다.
   반드시 `Start-Process ... -PassThru` 로 받은 PID 하나만 종료한다.
9. **playwright 는 `file://` 을 차단한다.** 데모를 다시 볼 때는 `python -m http.server` 로 띄우고,
   한글 경로는 인자로 넘기면 깨지니 ASCII 경로에 복사해서 서빙한다.

---

## 7. 데모를 다시 굽는 방법 (연출을 더 손보고 싶을 때)

빌드 스크립트는 `C:\dev\services\design\_작업\앱에셋\tools\` 에 있다.

```bash
# 쓰는 컷·순서를 바꿀 때만 (긴 변 440px webp q88로 11종 재인코딩)
python "C:/dev/services/design/_작업/앱에셋/tools/mk_assets.py"

# 템플릿 + 이미지 -> 단일 HTML
python "C:/dev/services/design/_작업/앱에셋/tools/build.py"
```

- 연출·속도·각도는 `tools/tpl.html` 만 고친다 (`DUR` 상수, `play()` 의 `deck` 분기, `PATTERNS` 배열).
- 쓰는 컷·순서는 `tools/mk_assets.py` 의 `ORDER` 목록을 고친다.
- 데모에서 값을 바꿨으면 **이 문서 §4 표도 같이 고친다** (글로벌 §0-B — 값이 두 곳에서 갈리면 안 된다).

---

## 8. 되돌리기

앱 코드는 아직 무변경이라, 이식 후 되돌릴 일이 생기면 커밋 하나만 revert 하면 된다.
에셋까지 지우려면 `assets/character/action/` 폴더와 `pubspec.yaml` 한 줄을 함께 걷어낸다.

---

## 9. 설계 세션에서 실제로 한 일 (참고)

- `drawable-hdpi` 20종 중 전신 액션 11종 선별 (얼굴만 나오는 9종 제외)
- 등장 연출 4안 설계 + 단일 HTML 데모 제작 (이미지 base64 내장, 459KB)
- playwright 로 실동작 검증 → 1안 겹침 과다·4안 뭉개짐 발견 → 둘 다 고쳐 재검증
- 대표 시연 → **4안 채택 + 스플래시 매 실행 재생** 확정
- 빌드 스크립트 3종을 `앱에셋\tools\` 로 영구화

세션 요약본(같은 내용의 축약판)은 `C:\dev\services\video\docs\HANDOFF.md` 에도 있다.
**상세 정본은 이 문서다.**
