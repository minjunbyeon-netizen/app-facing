// v1.17 Sprint 18 (Plan D): 칭호 잠금 해제 confetti.
//
// 외부 의존 없음 — 커스텀 ParticleSystem 으로 직접 구현.
// v3.3 (2026-08-20 사용자 지시): react-native-confetti-cannon 스타일 —
// 화면 하단 양쪽 캐논에서 위로 쏘아올리는 원뿔 분사, 노출 2초, 입자 60개.
// 색은 토큰만 (primary·success·info·warning + rarity 틴트) — design-block 준수.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import 'hyphen_pictogram.dart';

/// 테스트에서만 갈아 끼우는 난수원. null 이면 매번 새 폭죽 (2026-08-21 골든 안정화).
math.Random? confettiRandom;

class ConfettiOverlay {
  ConfettiOverlay._();

  /// 하단 캐논 발사 — 2초 후 자동 종료. rarity 컬러로 틴트.
  static Future<void> burst(
    BuildContext context, {
    required String rarity,
  }) async {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    HapticFeedback.heavyImpact();
    final entry = OverlayEntry(builder: (ctx) => _ConfettiAnim(rarity: rarity));
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 2000));
    entry.remove();
  }
}

class _ConfettiAnim extends StatefulWidget {
  final String rarity;
  const _ConfettiAnim({required this.rarity});

  @override
  State<_ConfettiAnim> createState() => _ConfettiAnimState();
}

class _ConfettiAnimState extends State<_ConfettiAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    // 골든 캡처를 결정론으로 만들려면 시드를 갈아 끼운다 (quotes.quoteRandom 패턴).
    // 실사용에서는 null 이라 매번 다른 폭죽이 터진다.
    final rng = confettiRandom ?? math.Random();
    // v3.3 캐논: 좌·우 하단 두 발사대. 위쪽 원뿔(수직 ±35°)로 쏘아올린다.
    _particles = List.generate(60, (i) {
      final fromLeft = i.isEven;
      // 수직(-90°) 기준 안쪽으로 기운 원뿔 — 좌측 캐논은 오른쪽 위로.
      final tilt = (rng.nextDouble() - 0.5) * (math.pi * 70 / 180);
      final lean = fromLeft ? 0.35 : -0.35; // 화면 안쪽 편향
      final angle = -math.pi / 2 + tilt + lean;
      final speed = 520 + rng.nextDouble() * 380; // px/sec — 캐논답게 강하게
      return _Particle(
        startX: fromLeft ? -1 : 1, // painter 에서 좌/우 발사대 부호로 사용
        startY: 0,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        rotation: rng.nextDouble() * 6.28,
        rotationSpeed: (rng.nextDouble() - 0.5) * 10,
        size: 5 + rng.nextDouble() * 8,
        kind: i % 3, // 0=square 1=circle 2=line
      );
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, _) {
          final t = _ctrl.value;
          return CustomPaint(
            size: MediaQuery.of(ctx).size,
            painter: _ConfettiPainter(
              particles: _particles,
              t: t,
              tint: RarityPalette.of(widget.rarity).light,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final int kind;

  _Particle({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.kind,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0~1
  final Color tint;
  _ConfettiPainter({
    required this.particles,
    required this.t,
    required this.tint,
  });

  // v3.3: 축하 팔레트 — 토큰만 (design-block). tint(등급색)는 square 담당.
  static const List<Color> _palette = [
    HyphenTokens.success,
    HyphenTokens.info,
    HyphenTokens.warning,
    HyphenTokens.primary,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // v3.3 캐논: 좌·우 하단 발사대 (화면 밖 살짝 아래에서 시작).
    final gravity = 620.0; // px/sec^2
    final dt = t * 2.0; // 시뮬레이션 시간 (sec)
    var idx = 0;
    for (final p in particles) {
      final baseX = p.startX < 0 ? size.width * 0.08 : size.width * 0.92;
      final x = baseX + p.vx * dt;
      final y = size.height + 12 + p.vy * dt + 0.5 * gravity * dt * dt;
      final fade = (1.0 - t).clamp(0.0, 1.0);
      final base = p.kind == 0 ? tint : _palette[idx++ % _palette.length];
      final paint = Paint()..color = base.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * dt);
      switch (p.kind) {
        case 0: // square
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
          break;
        case 1: // circle
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
          break;
        case 2: // line
          paint.strokeWidth = 2;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(Offset(-p.size, 0), Offset(p.size, 0), paint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.tint != tint;
}
