/// FKit — facing UI 컴포넌트 SSOT (2026-07-28 사용자 지시).
///
/// 새 화면·기능에서 카드·배지·섹션 라벨·통계 타일·빈/에러/로딩 상태를
/// 그때그때 새로 만들지 않는다 — 여기 있는 것만 쓰고, 없으면 여기에 추가한다
/// (글로벌 §3 코드·클래스 SSOT 의 프로젝트 배선). 참조 관례: workcheck gs_* ·
/// writeplz wp_* — 공통 조상 토큰은 appkit.gen.dart / FacingTokens.
///
/// 고정 규격 (전 화면 동일 — 전체 양식 = docs/DESIGN-SSOT.md):
/// - 버튼: FkButton 3단(primary 채움 52 / secondary 외곽선 52 / tertiary 글자 48).
///   화면당 primary 는 1개. 새 버튼 모양 신설 금지
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

/// 버튼 위계 3단 — **누르는 것의 유일 규격** (v2.2 · 2026-08-12 가시성 개편 지시).
///
/// 그전까지 화면마다 `ElevatedButton`·`OutlinedButton`·`TextButton`·`InkWell` 을
/// 골라 쓰고 `minimumSize` 도 제각각(36·40·52)이라, 같은 무게의 동작이 화면마다
/// 다르게 보였다. 이제 셋 중 하나를 고르는 것으로 끝낸다.
///
/// - [FkButtonKind.primary] — 이 화면에서 지금 해야 할 **단 하나**. 채움 + 흰 글씨.
///   화면당 1개 원칙 (링코 F1 의 교훈 — 강조가 여섯 번이면 강조가 아니다).
/// - [FkButtonKind.secondary] — 같이 놓이는 대등한 선택지. 외곽선.
/// - [FkButtonKind.tertiary] — 부수 동작·이동. 글자만, 그래도 터치는 48 보장.
enum FkButtonKind { primary, secondary, tertiary }

class FkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FkButtonKind kind;

  /// 가로를 꽉 채울지. false 면 글자 폭 + 패딩만 차지한다 (행 안에 나란히 둘 때).
  final bool expand;

  /// 되돌릴 수 없는 동작(초기화·삭제·해지)임을 색으로 알린다.
  /// primary 면 danger 채움, secondary 면 danger 테두리+글자.
  /// 파괴적 동작을 그냥 글자 링크로 두면 일반 메뉴와 구분되지 않는다
  /// (링코 S17 — '서비스 탈퇴'가 일반 항목과 같은 비중이던 문제).
  final bool danger;

  /// 글자색을 브랜드색 대신 중립(fgSecondary)으로. tertiary 에서만 의미가 있다.
  /// 한 화면에 브랜드색이 셋을 넘으면 강조가 죽으므로(링코 F1), primary 버튼과
  /// 같이 놓이는 부수 링크는 이쪽. 회색 muted 로 내리면 비활성처럼 보이므로
  /// fgSecondary(7.7:1) + w600 으로 "읽히되 앞서지 않게" 둔다.
  final bool neutral;

  const FkButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = FkButtonKind.primary,
    this.icon,
    this.expand = true,
    this.neutral = false,
    this.danger = false,
  });

  const FkButton.primary(this.label,
      {super.key,
      required this.onPressed,
      this.icon,
      this.expand = true,
      this.danger = false})
      : kind = FkButtonKind.primary,
        neutral = false;

  const FkButton.secondary(this.label,
      {super.key,
      required this.onPressed,
      this.icon,
      this.expand = true,
      this.danger = false})
      : kind = FkButtonKind.secondary,
        neutral = false;

  const FkButton.tertiary(this.label,
      {super.key,
      required this.onPressed,
      this.icon,
      this.expand = false,
      this.neutral = false})
      : kind = FkButtonKind.tertiary,
        danger = false;

  @override
  Widget build(BuildContext context) {
    // 전체폭이 아니면 테마의 minimumSize(무한대)를 눌러 글자 폭에 맞춘다.
    final size = WidgetStatePropertyAll<Size>(
      Size(expand ? double.infinity : 0, _height),
    );
    final shrink = expand ? null : MaterialTapTargetSize.shrinkWrap;

    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: FacingTokens.sp2),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    switch (kind) {
      case FkButtonKind.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: size,
            tapTargetSize: shrink,
            backgroundColor: danger
                ? const WidgetStatePropertyAll<Color>(FacingTokens.danger)
                : null,
          ),
          child: child,
        );
      case FkButtonKind.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: size,
            tapTargetSize: shrink,
            foregroundColor: danger
                ? const WidgetStatePropertyAll<Color>(FacingTokens.danger)
                : null,
            side: danger
                ? const WidgetStatePropertyAll<BorderSide>(
                    BorderSide(color: FacingTokens.danger))
                : null,
          ),
          child: child,
        );
      case FkButtonKind.tertiary:
        return TextButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: size,
            tapTargetSize: shrink,
            foregroundColor: neutral
                ? const WidgetStatePropertyAll<Color>(
                    FacingTokens.fgSecondary)
                : null,
          ),
          child: child,
        );
    }
  }

  /// v2.5 (2026-08-12 사용자 지시): 3종 모두 같은 컴팩트 높이.
  /// 전엔 채움 52 · 글자 48 로 미묘하게 달라 한 줄에 나란히 두면 층이 졌다.
  double get _height => FacingTokens.buttonHCompact;
}

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

/// 배지 — **표시·선택 통합 유일 규격** (v1.32 · 2026-08-07 "1종으로 통합" 지시).
/// 1px 컬러 보더 + r1(4) 사각 + micro w700 대문자. 원형 pill 금지.
///
/// [onTap] 을 주면 선택 컨트롤로 동작한다 — 터치 최소 48 보장, [selected] 면 면 채움 반전.
/// 화면마다 따로 만들던 `_Pill`·`_MiniPill`·`_StatusChip`·`_CategoryChip`·`_PainChip`·
/// `_chip` 등 11종은 v1.32 에서 전부 이 하나로 흡수했다. 새 variant 신설 금지 —
/// 모양이 다른 배지가 필요하면 여기부터 고친다. (TierBadge 만 티어 전용 별도 정본)
class FkBadge extends StatelessWidget {
  final String text;
  final Color color;

  /// 면 채움(반전) 여부. 선택 컨트롤에서만 의미가 있다.
  final bool selected;

  /// null 이면 표시 전용 배지, 주면 탭 가능한 선택 컨트롤.
  final VoidCallback? onTap;

  const FkBadge(
    this.text, {
    super.key,
    this.color = FacingTokens.muted,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;
    // 시각 크기는 표시·선택이 완전히 같다 (1종 강제). 다른 건 터치 영역뿐.
    final box = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FacingTokens.sp2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(FacingTokens.r1),
      ),
      child: Text(
        text.toUpperCase(),
        style: FacingTokens.micro.copyWith(
          color: selected ? FacingTokens.bg : color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
    if (!tappable) return box;
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FacingTokens.r1),
        // 배지 자체는 작게 두고 손가락이 닿을 48 만 세로로 확보한다.
        // widthFactor: 1 — 가로는 글자 폭에 딱 맞춘다 (Row 안에서 늘어나지 않게).
        child: SizedBox(
          height: FacingTokens.touchMin,
          child: Center(widthFactor: 1, child: box),
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

/// 표 행 — 좌 아이콘(선택) · 제목/부제 · 우 값. "한 줄에 한 항목" 표기의 유일 규격.
/// 홈 업적·마일스톤처럼 나열형 데이터는 그리드 타일 대신 이 행으로 쌓는다
/// (v1.30 — 색 타일 그리드가 산만하다는 사용자 지시로 표 형태 전환).
class FkListRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Color? trailingColor;

  /// 우측 슬롯을 위젯으로 — 출석 체크 배지처럼 값이 아니라 조작이 붙을 때.
  /// [trailing] 과 동시 사용 금지 (둘 다 오른쪽 자리를 쓴다).
  final Widget? trailingWidget;

  /// 행 하단 슬롯 — 진행바 등. 없으면 생략.
  final Widget? below;
  final VoidCallback? onTap;

  const FkListRow({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.trailingColor,
    this.trailingWidget,
    this.below,
    this.onTap,
  }) : assert(trailing == null || trailingWidget == null,
            'trailing 과 trailingWidget 은 같은 자리다 — 하나만 쓴다');

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FacingTokens.sp3,
        // v2.5 (2026-08-12 사용자 지시): 위아래 12 씩이면 두 줄짜리 행 하나가
        // 70 을 넘어 업적·마일스톤 표가 화면을 다 먹었다. 8 로 내린다.
        vertical: FacingTokens.sp2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? FacingTokens.muted),
                const SizedBox(width: FacingTokens.sp3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FacingTokens.body
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: FacingTokens.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: FacingTokens.sp3),
                Text(
                  trailing!,
                  style: FacingTokens.micro.copyWith(
                    color: trailingColor ?? FacingTokens.muted,
                    fontWeight: FontWeight.w600,
                    fontFeatures: FacingTokens.tabular,
                  ),
                ),
              ],
              if (trailingWidget != null) ...[
                const SizedBox(width: FacingTokens.sp3),
                trailingWidget!,
              ],
              // v2.2 (H8): 누를 수 있는 행에 오른쪽 화살표를 붙인다. 그전엔
              // 아이콘 + 제목만 있어 프로필 메뉴 10줄이 "읽는 목록"인지
              // "누르는 목록"인지 구분되지 않았다. 우측에 값이 이미 있는 행은
              // 자리를 다투므로 붙이지 않는다.
              if (onTap != null &&
                  trailing == null &&
                  trailingWidget == null) ...[
                const SizedBox(width: FacingTokens.sp2),
                const Icon(Icons.chevron_right,
                    size: 18, color: FacingTokens.muted),
              ],
            ],
          ),
          if (below != null) ...[
            const SizedBox(height: FacingTokens.sp1),
            below!,
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// 표 카드 — FkListRow 들을 1px 구분선으로 쌓는다 (카드 1개 = 표 1개).
class FkRowCard extends StatelessWidget {
  final List<Widget> rows;
  final EdgeInsetsGeometry? margin;
  const FkRowCard({super.key, required this.rows, this.margin});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(
          height: 1,
          thickness: 1,
          color: FacingTokens.border,
          indent: FacingTokens.sp4,
          endIndent: FacingTokens.sp4,
        ));
      }
      children.add(rows[i]);
    }
    return FkCard(
      margin: margin,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FacingTokens.r3),
        child: Column(children: children),
      ),
    );
  }
}

/// 아코디언 — 기본 접힘 묶음 구획. ExpansionTile 반복 배선(기본 divider 제거 ·
/// muted 화살표 · sectionLabel 제목 · 부제 preview)의 유일 규격.
/// 자주 쓰지 않는 항목 다발은 펼치기 전까지 헤더 한 줄만 차지한다
/// (v1.31 — 프로필 메뉴가 세로로 주렁주렁 길다는 사용자 지시로 도입).
/// [inset] = 카드 안에 넣을 때 true (좌우 여백을 카드 내부에 맞춤).
class FkAccordion extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool inset;

  const FkAccordion({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
    this.inset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      // ExpansionTile 기본 상·하단 divider 제거.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        // v2.5 (2026-08-12 사용자 지시 "50% 수준으로"): 기본 ExpansionTile 은
        // 제목+부제면 헤더 한 줄이 72 를 넘어 프로필 한 화면에 네 항목도 안 들어갔다.
        // dense + compact + 최소 높이 44 로 절반 가까이 내린다.
        dense: true,
        visualDensity: VisualDensity.compact,
        minTileHeight: 44,
        tilePadding: EdgeInsets.symmetric(
          horizontal: inset ? FacingTokens.sp3 : 2,
          vertical: 0,
        ),
        childrenPadding: inset
            ? const EdgeInsets.fromLTRB(
                FacingTokens.sp3, 0, FacingTokens.sp3, FacingTokens.sp3)
            : EdgeInsets.zero,
        collapsedIconColor: FacingTokens.muted,
        iconColor: FacingTokens.muted,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: FkSectionLabel(title),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: FacingTokens.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        children: children,
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
