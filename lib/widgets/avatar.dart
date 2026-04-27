// v1.19 페르소나 P0-2: 회원·코치 아바타 — display_name 첫글자 + avatar_color 배경.
//
// fallback 정책:
//  - displayName 있으면 첫 글자 (한글이면 그대로, 영문은 대문자)
//  - 없으면 hash 8자 첫 글자
//  - 색상 없으면 muted (자동 hash 색상으로 대체 가능 추후)
//
// 톤: VISUAL_CONCEPT 흑백·전사. avatar_color 는 회원 본인이 선택한 액센트 1색만.

import 'package:flutter/material.dart';

import '../core/theme.dart';

class Avatar extends StatelessWidget {
  final String? displayName;
  final String hash; // fallback (이니셜·자동 색상)
  final String? colorHex; // '#RRGGBB' 또는 null
  final double size;
  final bool selected;

  const Avatar({
    super.key,
    required this.hash,
    this.displayName,
    this.colorHex,
    this.size = 36,
    this.selected = false,
  });

  static String _firstLetter(String? name, String hash) {
    final src = (name ?? '').trim();
    if (src.isNotEmpty) {
      final c = src[0];
      // 영문이면 대문자, 한글·숫자 그대로.
      return c.toUpperCase();
    }
    if (hash.isNotEmpty) return hash[0].toUpperCase();
    return 'C';
  }

  static Color _colorFromHash(String hash) {
    // 간이 hash → muted 변형 색 (회색 톤 5종).
    if (hash.isEmpty) return FacingTokens.muted;
    final n = hash.codeUnitAt(0) % 5;
    switch (n) {
      case 0:
        return const Color(0xFF8A8A8A);
      case 1:
        return const Color(0xFF707070);
      case 2:
        return const Color(0xFFA0A0A0);
      case 3:
        return const Color(0xFF6A6A6A);
      case 4:
      default:
        return const Color(0xFF909090);
    }
  }

  static Color parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final raw = hex.replaceAll('#', '');
    if (raw.length != 6 && raw.length != 8) return fallback;
    final v = int.tryParse(raw, radix: 16);
    if (v == null) return fallback;
    if (raw.length == 6) {
      return Color(0xFF000000 | v);
    }
    return Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final base = parseHex(colorHex, _colorFromHash(hash));
    final letter = _firstLetter(displayName, hash);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FacingTokens.bg,
        border: Border.all(
          color: base,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Text(
        letter,
        style: FacingTokens.body.copyWith(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: base,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
