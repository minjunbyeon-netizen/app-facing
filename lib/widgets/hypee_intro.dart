import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'brand_logo.dart';
import 'mascot.dart';

/// 스플래시 등장 연출 — **C안: 카드가 로고로 빨려듦** (2026-08-22 대표 확정).
///
/// 순서: 캐릭터 카드 11장이 중앙에서 부채꼴로 쌓인다 → 가운데로 모이며 작아져
/// 사라진다 → 그 자리에서 HYPHEN 로고가 피어났다가 잠깐 뒤 사라진다.
/// 로고가 위에 계속 떠 있던 구 A안(v3.7)을 대체한다 — 캐릭터가 나올 때는
/// 캐릭터만 보여야 한다는 사용자 지시.
///
/// **전체 2450ms 로 맞춰 두었다.** 스플래시 최소 대기(`AppKit.splashMin`)가
/// 2500ms 라 그 안에 끝나야 로고가 사라지기 전에 화면이 넘어가지 않는다.
/// 값을 늘리려면 splashMin 이 아니라 이 안에서 조정할 것 — splashMin 은
/// appkit(3앱 공통 조상)이라 건드리면 다른 앱까지 흔든다.
///
/// 배경이 투명한 그림이라 **카드 면(배경·테두리·라운드)을 씌운 뒤 겹친다** —
/// 면을 빼면 실루엣이 서로 뒤엉킨다. 그림자는 넣지 않는다 (글로벌 §2-B).
class HypeeIntroDeck extends StatefulWidget {
  const HypeeIntroDeck({super.key});

  @override
  State<HypeeIntroDeck> createState() => _HypeeIntroDeckState();
}

class _HypeeIntroDeckState extends State<HypeeIntroDeck>
    with SingleTickerProviderStateMixin {
  // ── 타임라인 (ms) — 웹 데모 `스플래시연출비교.html` C안을 2450ms 로 압축 ──
  static const int _gapMs = 90; // 장 사이 간격 (60 아래면 뭐가 지나갔는지 안 읽힌다)
  static const int _durMs = 200; // 장별 등장 시간
  // 덱이 다 쌓이는 시점 = (11-1)*90 + 200 = 1100ms. 아래 수렴 시작이 그 뒤다.
  static const int _suckStartMs = 1250; // 수렴 시작
  static const int _suckEndMs = 1650;
  static const int _logoInStartMs = 1700;
  static const int _logoInEndMs = 2000;
  static const int _logoOutStartMs = 2200; // 200ms 머문 뒤 퇴장
  static const int _totalMs = 2450;

  late final AnimationController _ctrl;
  late final List<Animation<double>> _enter; // 장별 등장 0→1
  late final Animation<double> _suck; // 중앙 수렴 0→1
  late final Animation<double> _logoIn;
  late final Animation<double> _logoOut;

  List<HypeeAction> get _seq => HypeeActions.introSequence;

  Animation<double> _seg(int startMs, int endMs, Curve curve) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(startMs / _totalMs, endMs / _totalMs, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _enter = List.generate(
      _seq.length,
      (i) => _seg(i * _gapMs, i * _gapMs + _durMs, Curves.easeOutCubic),
    );
    // 안쪽으로 빨려드는 느낌 — 처음 느리다 끝에서 가속 (easeInCubic).
    _suck = _seg(_suckStartMs, _suckEndMs, Curves.easeInCubic);
    _logoIn = _seg(_logoInStartMs, _logoInEndMs, Curves.easeOutCubic);
    _logoOut = _seg(_logoOutStartMs, _totalMs, Curves.easeIn);

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
          children: [
            // 카드 덱 — Stack 자식 순서가 곧 겹침 순서다. 뒤에 그려지는
            // cheer(i=10)가 맨 앞에 선다. 순서를 뒤집지 말 것.
            ...List.generate(_seq.length, (i) {
              final offsetFromMid = i - mid;
              final angle = offsetFromMid * 4.6 * math.pi / 180; // 양끝 ±23°
              final dx = offsetFromMid * 0.042 * w; // 양끝 ±21%
              final dy = (offsetFromMid.abs() * 0.016 - 0.06) * h; // 부채꼴 처짐
              final enterDy = 0.44 * h; // 아래에서 올라오는 거리

              return AnimatedBuilder(
                animation: Listenable.merge([_enter[i], _suck]),
                builder: (context, child) {
                  final t = _enter[i].value;
                  final s = _suck.value; // 0 → 1 로 갈수록 중앙으로 모인다
                  if (s >= 1.0) return const SizedBox.shrink();
                  // 수렴: 위치·회전을 0 으로 당기고 크기를 줄이며 사라진다.
                  final pull = 1 - s;
                  return Opacity(
                    opacity: t * (1 - s),
                    child: Transform.translate(
                      offset: Offset(
                        dx * pull,
                        (dy + enterDy * (1 - t)) * pull,
                      ),
                      child: Transform.rotate(
                        angle: angle * pull,
                        child: Transform.scale(
                          scale: (0.8 + 0.2 * t) * (1 - 0.78 * s),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: _card(w, h, _seq[i]),
              );
            }),
            // 로고 — 카드가 모인 그 자리에서 피어났다가 사라진다.
            AnimatedBuilder(
              animation: Listenable.merge([_logoIn, _logoOut]),
              builder: (context, child) {
                final o = _logoIn.value * (1 - _logoOut.value);
                if (o <= 0) return const SizedBox.shrink();
                return Opacity(
                  opacity: o,
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * _logoIn.value,
                    child: child,
                  ),
                );
              },
              child: const BrandLogo(),
            ),
          ],
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
