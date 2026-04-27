// v1.17 Sprint 18 (Plan D): 칭호 잠금 해제 confetti.
//
// 외부 의존 없음 — 커스텀 ParticleSystem 으로 직접 구현.
// 톤: 흑백·Obsession 컨셉 유지. 색상은 fg(흰색)·success(녹)·rarity 컬러만.
// 입자 30개, 1.4초 후 자동 dismiss. heavyImpact haptic 동시 발사.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

class ConfettiOverlay {
  ConfettiOverlay._();

  /// 화면 중앙 상단에서 사방으로 분사. 1.4초 후 자동 종료.
  /// rarity 컬러로 액센트.
  static Future<void> burst(
    BuildContext context, {
    required String rarity,
  }) async {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    HapticFeedback.heavyImpact();
    final entry = OverlayEntry(
      builder: (ctx) => _ConfettiAnim(rarity: rarity),
    );
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 1500));
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
    final rng = math.Random();
    _particles = List.generate(34, (i) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 220 + rng.nextDouble() * 240; // px/sec
      return _Particle(
        startX: 0,
        startY: 0,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 80, // 위로 약간 편향.
        rotation: rng.nextDouble() * 6.28,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        size: 4 + rng.nextDouble() * 8,
        kind: i % 3, // 0=square 1=circle 2=line
      );
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _rarityColor() {
    switch (widget.rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      case 'Common':
      default:
        return FacingTokens.fg;
    }
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
              tint: _rarityColor(),
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

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35; // 화면 위쪽 1/3에서 분사.
    final gravity = 480.0; // px/sec^2
    final dt = t * 1.4; // 시뮬레이션 시간 (sec)
    for (final p in particles) {
      final x = cx + p.startX + p.vx * dt;
      final y = cy + p.startY + p.vy * dt + 0.5 * gravity * dt * dt;
      final fade = (1.0 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = (p.kind == 1 ? FacingTokens.success : tint)
            .withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * dt);
      switch (p.kind) {
        case 0: // square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size,
            ),
            paint,
          );
          break;
        case 1: // circle
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
          break;
        case 2: // line
          paint.strokeWidth = 2;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(-p.size, 0),
            Offset(p.size, 0),
            paint,
          );
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.tint != tint;
}
