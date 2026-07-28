/// FKit — facing UI 컴포넌트 SSOT (2026-07-28 사용자 지시).
///
/// 새 화면·기능에서 카드·배지·섹션 라벨·통계 타일·빈/에러/로딩 상태를
/// 그때그때 새로 만들지 않는다 — 여기 있는 것만 쓰고, 없으면 여기에 추가한다
/// (글로벌 §3 코드·클래스 SSOT 의 프로젝트 배선). 참조 관례: workcheck gs_* ·
/// writeplz wp_* — 공통 조상 토큰은 appkit.gen.dart / FacingTokens.
///
/// 고정 규격 (전 화면 동일 — 전체 양식 = docs/DESIGN-SSOT.md):
/// - 카드: surface 면 + 1px border + r3, 내부 패딩 sp4
/// - 배지: 1px 컬러 보더 + 대문자 + r1 사각 — 완전 원형 pill 금지 (글로벌 design-block)
/// - 섹션 라벨: sectionLabel 토큰 + 대문자 강제 (코드에서 toUpperCase)
/// - 로딩 스피너: 22×22 stroke 2 muted 단일 규격 / 전면 로딩 = FkLoadingScreen
/// - 에러: 본문 메시지 + OutlinedButton "다시 시도" (문구 고정)
/// - 소셜 로그인 버튼: FkSocialButton (높이 52 · r3 · 마크+라벨 중앙)
library;

import 'package:flutter/material.dart';

import '../core/exception.dart';
import '../core/theme.dart';
import 'brand_logo.dart';

/// 섹션 구분 라벨 — 대문자 강제.
class FkSectionLabel extends StatelessWidget {
  final String text;
  const FkSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: FacingTokens.sectionLabel);
}

/// 표준 카드 — surface + 1px border + r3.
class FkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  const FkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FacingTokens.sp4),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FacingTokens.r3),
      child: card,
    );
  }
}

/// 표준 배지 — 1px 컬러 보더 + 대문자 + r1 사각. (TierBadge 는 티어 전용 별도 SSOT)
class FkBadge extends StatelessWidget {
  final String text;
  final Color color;
  const FkBadge(this.text, {super.key, this.color = FacingTokens.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp2, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(FacingTokens.r1),
      ),
      child: Text(
        text.toUpperCase(),
        style: FacingTokens.micro.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// 통계 타일 — 라벨(위) + 값(아래). 홈 Milestones · 보스 대시보드 공용 형태.
class FkStatTile extends StatelessWidget {
  final String label;
  final String value;
  const FkStatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return FkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FkSectionLabel(label),
          const SizedBox(height: FacingTokens.sp1),
          Text(value,
              style: FacingTokens.h3.copyWith(color: FacingTokens.fg)),
        ],
      ),
    );
  }
}

/// 빈 상태 — h3 제목(영문 헤드라인) + 한글 캡션 수직 스택 (V10 패턴).
class FkEmptyState extends StatelessWidget {
  final String title;
  final String? caption;
  const FkEmptyState({super.key, required this.title, this.caption});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: FacingTokens.h3, textAlign: TextAlign.center),
            if (caption != null) ...[
              const SizedBox(height: FacingTokens.sp2),
              Text(caption!,
                  style: FacingTokens.caption, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// 에러 상태 — 메시지 + Retry. 전 화면 문구·간격 고정.
/// AppException 이면 messageKo, 그 외 '로딩 실패.' — fromError 로 통일 매핑.
class FkErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const FkErrorState({super.key, required this.message, required this.onRetry});

  FkErrorState.fromError(Object? error,
      {super.key, required this.onRetry})
      : message = error is AppException ? error.messageKo : '로딩 실패.';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: FacingTokens.body, textAlign: TextAlign.center),
            const SizedBox(height: FacingTokens.sp3),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

/// 로딩 스피너 — 22×22 stroke 2 muted 단일 규격.
class FkLoading extends StatelessWidget {
  const FkLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: FacingTokens.muted),
      ),
    );
  }
}

/// 전면 로딩 — 진입·전환 화면 유일 규격 (DESIGN-SSOT §6).
/// BrandLogo(기본 폭 220) + FkLoading + 선택 캡션. Scaffold body 로 그대로 끼운다.
class FkLoadingScreen extends StatelessWidget {
  final String? caption;
  const FkLoadingScreen({super.key, this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FacingTokens.bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(FacingTokens.sp5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandLogo(),
          const SizedBox(height: FacingTokens.sp6),
          const FkLoading(),
          if (caption != null) ...[
            const SizedBox(height: FacingTokens.sp3),
            Text(caption!,
                style: FacingTokens.caption, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// 소셜 로그인 버튼 — 유일 규격 (높이 52 · r3 · 마크+라벨 중앙, DESIGN-SSOT §6).
/// 색은 FacingTokens 외부 브랜드 색(naverGreen·googleSurface)만 사용.
class FkSocialButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final String markText;
  final Color? markColor;
  final VoidCallback? onPressed;

  const FkSocialButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.markText,
    required this.onPressed,
    this.markColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: FacingTokens.buttonH,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(FacingTokens.r3),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(FacingTokens.r3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                markText,
                style: FacingTokens.h3.copyWith(
                  color: markColor ?? foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: FacingTokens.body.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: FacingTokens.touchMin),
            ],
          ),
        ),
      ),
    );
  }
}
