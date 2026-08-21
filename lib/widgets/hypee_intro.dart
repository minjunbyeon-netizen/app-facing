import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'mascot.dart';

/// 스플래시 카드 덱 연출 — 캐릭터 11장이 아래에서 부채꼴로 쌓인다.
///
/// 값의 출처: `docs/SPLASH-INTRO-HANDOFF.md` §4 (웹 데모에서 실측·대표 확정).
/// 감으로 조정하지 말 것 — 데모(`services/design/_작업/앱에셋/온보딩연출데모.html`)와
/// 같은 그림이 나와야 한다.
///
/// 배경이 투명한 그림이라 **카드 면(배경·테두리·라운드)을 씌운 뒤 겹친다** —
/// 면을 빼면 실루엣이 서로 뒤엉킨다 (데모 첫 버전의 실패).
/// 그림자는 넣지 않는다 (글로벌 §2-B 다중 box-shadow 차단). 구분은 1px 테두리로 충분하다.
class HypeeIntroDeck extends StatefulWidget {
  const HypeeIntroDeck({super.key});

  @override
  State<HypeeIntroDeck> createState() => _HypeeIntroDeckState();
}

class _HypeeIntroDeckState extends State<HypeeIntroDeck>
    with SingleTickerProviderStateMixin {
  static const int _gapMs = 90; // 장 사이 간격 (60 아래면 뭐가 지나갔는지 안 읽힌다)
  static const int _durMs = 200; // 장별 등장 시간
  late final int _totalMs;

  late final AnimationController _ctrl;
  late final List<Animation<double>> _t; // 장별 진행도 0→1

  List<HypeeAction> get _seq => HypeeActions.introSequence;

  @override
  void initState() {
    super.initState();
    final n = _seq.length;
    _totalMs = (n - 1) * _gapMs + _durMs; // 11장 → 1100ms

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
          // Stack 자식 순서가 곧 겹침 순서다 — 뒤에 그려지는 cheer(i=10)가 맨 앞.
          children: List.generate(_seq.length, (i) {
            final offsetFromMid = i - mid;
            final angle = offsetFromMid * 4.6 * math.pi / 180; // 양끝 ±23°
            final dx = offsetFromMid * 0.042 * w; // 양끝 ±21%
            final dy = (offsetFromMid.abs() * 0.016 - 0.06) * h; // 바깥이 처져 부채꼴
            final enterDy = 0.44 * h; // 아래에서 올라오는 거리

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
