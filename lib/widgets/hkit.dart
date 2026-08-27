/// HKit — hyphen UI 컴포넌트 SSOT (2026-07-28 사용자 지시).
///
/// 새 화면·기능에서 카드·배지·섹션 라벨·통계 타일·빈/에러/로딩 상태를
/// 그때그때 새로 만들지 않는다 — 여기 있는 것만 쓰고, 없으면 여기에 추가한다
/// (글로벌 §3 코드·클래스 SSOT 의 프로젝트 배선). 참조 관례: workcheck gs_* ·
/// writeplz wp_* — 공통 조상 토큰은 appkit.gen.dart / HyphenTokens.
///
/// 고정 규격 (전 화면 동일 — 전체 양식 = docs/DESIGN-SSOT.md):
/// - 버튼: HkButton 3단(primary 채움 52 / secondary 외곽선 52 / tertiary 글자 48).
///   화면당 primary 는 1개. 새 버튼 모양 신설 금지
/// - 카드: surface 면 + 1px border + r3, 내부 패딩 sp4
/// - 배지: 1px 컬러 보더 + 대문자 + r1 사각 — 완전 원형 pill 금지 (글로벌 design-block)
/// - 섹션 라벨: sectionLabel 토큰 + 대문자 강제 (코드에서 toUpperCase)
/// - 로딩 스피너: 22×22 stroke 2 muted 단일 규격 / 전면 로딩 = HkLoadingScreen
/// - 에러: 본문 메시지 + OutlinedButton "다시 시도" (문구 고정)
/// - 소셜 로그인 버튼: HkSocialButton (높이 52 · r3 · 마크+라벨 중앙)
library;

import 'package:flutter/material.dart';

import '../core/exception.dart';
import '../core/theme.dart';
import 'brand_logo.dart';
import 'mascot.dart';
import '../core/appkit.gen.dart';

/// 버튼 위계 3단 — **누르는 것의 유일 규격** (v2.2 · 2026-08-12 가시성 개편 지시).
///
/// 그전까지 화면마다 `ElevatedButton`·`OutlinedButton`·`TextButton`·`InkWell` 을
/// 골라 쓰고 `minimumSize` 도 제각각(36·40·52)이라, 같은 무게의 동작이 화면마다
/// 다르게 보였다. 이제 셋 중 하나를 고르는 것으로 끝낸다.
///
/// - [HkButtonKind.primary] — 이 화면에서 지금 해야 할 **단 하나**. 채움 + 흰 글씨.
///   화면당 1개 원칙 (링코 F1 의 교훈 — 강조가 여섯 번이면 강조가 아니다).
/// - [HkButtonKind.secondary] — 같이 놓이는 대등한 선택지. 외곽선.
/// - [HkButtonKind.tertiary] — 부수 동작·이동. 글자만, 그래도 터치는 48 보장.
enum HkButtonKind { primary, secondary, tertiary }

class HkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final HkButtonKind kind;

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

  /// 처리 중 — **버튼을 스피너로 갈아 끼우지 않는다**. 자리(높이·폭)를 그대로 둔
  /// 채 글자만 스피너로 바꾸고 눌리지 않게 한다 (v3.33 · 2026-08-27 사용자 지시
  /// "변수가 생길 부분은 변수 자리를 미리 만들고"). 전엔 화면마다
  /// `_busy ? HkLoading() : HkButton(...)` 로 갈아 끼워, 로딩이 시작되는 순간
  /// 버튼 높이(36)와 스피너 높이(22)의 차이만큼 아래 요소가 통째로 밀렸다.
  /// 규격 = DESIGN-SSOT §레이아웃 안정성.
  final bool busy;

  const HkButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = HkButtonKind.primary,
    this.icon,
    this.expand = true,
    this.neutral = false,
    this.danger = false,
    this.busy = false,
  });

  const HkButton.primary(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.danger = false,
    this.busy = false,
  }) : kind = HkButtonKind.primary,
       neutral = false;

  const HkButton.secondary(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.danger = false,
    this.busy = false,
  }) : kind = HkButtonKind.secondary,
       neutral = false;

  const HkButton.tertiary(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.neutral = false,
    this.busy = false,
  }) : kind = HkButtonKind.tertiary,
       danger = false;

  @override
  Widget build(BuildContext context) {
    // 전체폭이 아니면 테마의 minimumSize(무한대)를 눌러 글자 폭에 맞춘다.
    final size = WidgetStatePropertyAll<Size>(
      Size(expand ? double.infinity : 0, _height),
    );
    final shrink = expand ? null : MaterialTapTargetSize.shrinkWrap;
    final action = busy ? null : onPressed;

    final Widget child = busy
        ? HkLoading(
            color: kind == HkButtonKind.primary
                ? HyphenTokens.onColor
                : HyphenTokens.primary,
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: HyphenTokens.sp2),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    switch (kind) {
      case HkButtonKind.primary:
        // busy 는 눌리지 않지만 **비활성 회색으로 내리지 않는다** — 색까지 바뀌면
        // 같은 자리에 있어도 "사라진 것"처럼 읽힌다. 면은 그대로, 글자만 스피너.
        final WidgetStatePropertyAll<Color>? bg = danger
            ? const WidgetStatePropertyAll<Color>(HyphenTokens.danger)
            : busy
            ? const WidgetStatePropertyAll<Color>(HyphenTokens.primary)
            : null;
        return ElevatedButton(
          onPressed: action,
          style: ButtonStyle(
            minimumSize: size,
            tapTargetSize: shrink,
            backgroundColor: bg,
          ),
          child: child,
        );
      case HkButtonKind.secondary:
        return OutlinedButton(
          onPressed: action,
          style: ButtonStyle(
            minimumSize: size,
            tapTargetSize: shrink,
            foregroundColor: danger
                ? const WidgetStatePropertyAll<Color>(HyphenTokens.danger)
                : null,
            side: danger
                ? const WidgetStatePropertyAll<BorderSide>(
                    BorderSide(color: HyphenTokens.danger),
                  )
                : busy
                ? const WidgetStatePropertyAll<BorderSide>(
                    BorderSide(color: HyphenTokens.borderStrong),
                  )
                : null,
          ),
          child: child,
        );
      case HkButtonKind.tertiary:
        return TextButton(
          onPressed: action,
          style: ButtonStyle(
            minimumSize: size,
            tapTargetSize: shrink,
            foregroundColor: neutral
                ? const WidgetStatePropertyAll<Color>(HyphenTokens.fgSecondary)
                : null,
          ),
          child: child,
        );
    }
  }

  /// v2.5 (2026-08-12 사용자 지시): 3종 모두 같은 컴팩트 높이.
  /// 전엔 채움 52 · 글자 48 로 미묘하게 달라 한 줄에 나란히 두면 층이 졌다.
  double get _height => HyphenTokens.buttonHCompact;
}

/// 섹션 구분 라벨 — 대문자 강제.
class HkSectionLabel extends StatelessWidget {
  final String text;
  const HkSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: HyphenTokens.sectionLabel);
}

/// 체크 줄 — 체크박스 + 라벨 한 줄 (v3.18 · 2026-08-25 로그인 '아이디 기억하기').
///
/// Material [Checkbox] 는 원형 리플·둥근 모서리라 이 앱의 사각 규격과 어긋난다.
/// 그래서 배지(HkBadge)와 같은 r1 사각 + 1px 보더로 직접 그린다. 터치 영역은
/// 라벨까지 포함해 48 이상 (글로벌 모바일 룰). 새 체크 variant 신설 금지 —
/// 다른 화면에 체크가 필요하면 이걸 쓴다 (§3 코드·클래스 SSOT).
class HkCheckRow extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  const HkCheckRow({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: HyphenTokens.touchMin),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? HyphenTokens.primary : HyphenTokens.surface,
                border: Border.all(
                  color: value ? HyphenTokens.primary : HyphenTokens.border,
                ),
                borderRadius: BorderRadius.circular(HyphenTokens.r1),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: HyphenTokens.onColor,
                    )
                  : null,
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Text(
              label,
              style: HyphenTokens.caption.copyWith(color: HyphenTokens.fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// 표준 카드 — surface + 1px border + 모서리(r3 기본).
///
/// v3.27 (2026-08-25 사용자 지시 "카드 36곳 마저"): 화면마다 Container 로
/// 같은 크롬을 다시 그리던 것을 흡수하려고 네 칸을 열었다 —
/// [radius](r2 카드도 있다) · [borderColor](예약됨=초록 같은 상태 테두리) ·
/// [clipBehavior](안쪽 ExpansionTile 이 모서리를 넘지 않게) · [width].
/// 그 밖의 모양(왼쪽 색띠·말풍선·원형)은 카드가 아니다 — 여기 넣지 않는다.
class HkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final Clip clipBehavior;
  final double? width;
  const HkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HyphenTokens.sp4),
    this.margin,
    this.onTap,
    this.radius = HyphenTokens.r3,
    this.borderColor = HyphenTokens.border,
    this.borderWidth = 1,
    this.clipBehavior = Clip.none,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
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
/// 모양이 다른 배지가 필요하면 여기부터 고친다.
class HkBadge extends StatelessWidget {
  final String text;
  final Color color;

  /// 면 채움(반전) 여부. 선택 컨트롤에서만 의미가 있다.
  final bool selected;

  /// null 이면 표시 전용 배지, 주면 탭 가능한 선택 컨트롤.
  final VoidCallback? onTap;

  const HkBadge(
    this.text, {
    super.key,
    this.color = HyphenTokens.muted,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;
    // 시각 크기는 표시·선택이 완전히 같다 (1종 강제). 다른 건 터치 영역뿐.
    final box = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HyphenTokens.sp2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(HyphenTokens.r1),
      ),
      child: Text(
        text.toUpperCase(),
        style: HyphenTokens.micro.copyWith(
          color: selected ? HyphenTokens.bg : color,
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
        borderRadius: BorderRadius.circular(HyphenTokens.r1),
        // 배지 자체는 작게 두고 손가락이 닿을 48 만 세로로 확보한다.
        // widthFactor: 1 — 가로는 글자 폭에 딱 맞춘다 (Row 안에서 늘어나지 않게).
        child: SizedBox(
          height: HyphenTokens.touchMin,
          child: Center(widthFactor: 1, child: box),
        ),
      ),
    );
  }
}

/// 통계 타일 — 라벨(위) + 값(아래). 홈 Milestones · 보스 대시보드 공용 형태.
class HkStatTile extends StatelessWidget {
  final String label;
  final String value;
  const HkStatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return HkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HkSectionLabel(label),
          const SizedBox(height: HyphenTokens.sp1),
          Text(value, style: HyphenTokens.h3.copyWith(color: HyphenTokens.fg)),
        ],
      ),
    );
  }
}

/// 표 행 — 좌 아이콘(선택) · 제목/부제 · 우 값. "한 줄에 한 항목" 표기의 유일 규격.
/// 홈 업적·마일스톤처럼 나열형 데이터는 그리드 타일 대신 이 행으로 쌓는다
/// (v1.30 — 색 타일 그리드가 산만하다는 사용자 지시로 표 형태 전환).
class HkListRow extends StatelessWidget {
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

  /// 좌측 슬롯을 위젯으로 — 업적 배지처럼 아이콘 하나로 안 끝날 때
  /// (2026-08-21 픽토그램 팩). [icon] 과 동시 사용 금지.
  final Widget? leadingWidget;
  final VoidCallback? onTap;

  const HkListRow({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.leadingWidget,
    this.subtitle,
    this.trailing,
    this.trailingColor,
    this.trailingWidget,
    this.below,
    this.onTap,
  }) : assert(
         trailing == null || trailingWidget == null,
         'trailing 과 trailingWidget 은 같은 자리다 — 하나만 쓴다',
       ),
       assert(
         icon == null || leadingWidget == null,
         'icon 과 leadingWidget 은 같은 자리다 — 하나만 쓴다',
       );

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HyphenTokens.sp3,
        // v2.5 (2026-08-12 사용자 지시): 위아래 12 씩이면 두 줄짜리 행 하나가
        // 70 을 넘어 업적·마일스톤 표가 화면을 다 먹었다. 8 로 내린다.
        vertical: HyphenTokens.sp2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingWidget != null) ...[
                leadingWidget!,
                const SizedBox(width: HyphenTokens.sp3),
              ] else if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? HyphenTokens.muted),
                const SizedBox(width: HyphenTokens.sp3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: HyphenTokens.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: HyphenTokens.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: HyphenTokens.sp3),
                Text(
                  trailing!,
                  style: HyphenTokens.micro.copyWith(
                    color: trailingColor ?? HyphenTokens.muted,
                    fontWeight: FontWeight.w600,
                    fontFeatures: HyphenTokens.tabular,
                  ),
                ),
              ],
              if (trailingWidget != null) ...[
                const SizedBox(width: HyphenTokens.sp3),
                trailingWidget!,
              ],
              // v2.2 (H8): 누를 수 있는 행에 오른쪽 화살표를 붙인다. 그전엔
              // 아이콘 + 제목만 있어 프로필 메뉴 10줄이 "읽는 목록"인지
              // "누르는 목록"인지 구분되지 않았다. 우측에 값이 이미 있는 행은
              // 자리를 다투므로 붙이지 않는다.
              if (onTap != null &&
                  trailing == null &&
                  trailingWidget == null) ...[
                const SizedBox(width: HyphenTokens.sp2),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: HyphenTokens.muted,
                ),
              ],
            ],
          ),
          if (below != null) ...[
            const SizedBox(height: HyphenTokens.sp1),
            below!,
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// 표 카드 — HkListRow 들을 1px 구분선으로 쌓는다 (카드 1개 = 표 1개).
class HkRowCard extends StatelessWidget {
  final List<Widget> rows;
  final EdgeInsetsGeometry? margin;
  const HkRowCard({super.key, required this.rows, this.margin});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: HyphenTokens.border,
            indent: HyphenTokens.sp4,
            endIndent: HyphenTokens.sp4,
          ),
        );
      }
      children.add(rows[i]);
    }
    return HkCard(
      margin: margin,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HyphenTokens.r3),
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
class HkAccordion extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool inset;

  const HkAccordion({
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
          horizontal: inset ? HyphenTokens.sp3 : 2,
          vertical: 0,
        ),
        childrenPadding: inset
            ? const EdgeInsets.fromLTRB(
                HyphenTokens.sp3,
                0,
                HyphenTokens.sp3,
                HyphenTokens.sp3,
              )
            : EdgeInsets.zero,
        collapsedIconColor: HyphenTokens.muted,
        iconColor: HyphenTokens.muted,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: HkSectionLabel(title),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: HyphenTokens.caption,
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
class HkEmptyState extends StatelessWidget {
  final String title;
  final String? caption;
  const HkEmptyState({super.key, required this.title, this.caption});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HyphenTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: HyphenTokens.h3, textAlign: TextAlign.center),
            if (caption != null) ...[
              const SizedBox(height: HyphenTokens.sp2),
              Text(
                caption!,
                style: HyphenTokens.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 에러 상태 — 메시지 + Retry. 전 화면 문구·간격 고정.
/// AppException 이면 messageKo, 그 외 '로딩 실패.' — fromError 로 통일 매핑.
class HkErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const HkErrorState({super.key, required this.message, required this.onRetry});

  HkErrorState.fromError(Object? error, {super.key, required this.onRetry})
    : message = error is AppException ? error.messageKo : '로딩 실패.';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HyphenTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: HyphenTokens.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HyphenTokens.sp3),
            HkButton.secondary('다시 시도', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// 로딩 스피너 — 22×22 stroke 2 muted 단일 규격.
/// [color] 는 색 있는 면 위에 얹을 때만 (버튼 안 = onColor). 크기는 바꾸지 않는다.
class HkLoading extends StatelessWidget {
  final Color? color;
  const HkLoading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color ?? HyphenTokens.muted,
        ),
      ),
    );
  }
}

/// 고정 높이 상단 띠 — **뒤로가기가 있든 없든 높이가 같다** (v3.33 · 2026-08-27
/// 사용자 지시 "고정 같은 자리").
///
/// 전엔 화면이 `appBar: Navigator.canPop(context) ? HkAppBar() : null` 로
/// 상단바 자체를 달았다 뗐다 했다 — 같은 화면인데 들어온 경로에 따라 본문 전체가
/// [HyphenTokens.appBarH] 만큼 위아래로 뛰었다. 이제 띠는 항상 있고, **안에 든
/// 화살표만** 조건부다. 구분선은 두지 않는다 (돌아갈 곳이 없을 때 빈 띠가
/// '죽은 줄'로 보이던 이유).
///
/// 제목·actions 가 필요한 밀어 넣은 화면은 종전대로 [HkAppBar] 를 쓴다.
class HkBackBar extends StatelessWidget {
  /// 화살표를 눌렀을 때. 기본은 [Navigator.maybePop].
  final VoidCallback? onBack;
  const HkBackBar({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return SizedBox(
      height: HyphenTokens.appBarH,
      width: double.infinity,
      child: canPop
          ? Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '뒤로',
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
            )
          : null,
    );
  }
}

/// 안내·에러 한 줄이 들어올 **예약된 자리** (공간 예약 / space reservation).
///
/// v3.33 (2026-08-27 사용자 지시): `if (_error != null) ...[HkInlineError(...)]`
/// 로 블록이 생겼다 사라지면 그 아래가 통째로 밀린다. 이 위젯은 메시지가 없어도
/// [HyphenTokens.noticeSlotH] 만큼 자리를 지키고, 내용만 갈아 끼운다.
/// 규격·적용 대상 = DESIGN-SSOT §레이아웃 안정성.
class HkNoticeSlot extends StatelessWidget {
  /// null 이면 빈 자리만 남긴다.
  final String? message;

  /// 있으면 배너 우측에 '다시 시도' — 목록 위 실패 배너로 쓸 때 (v3.34).
  /// 자리 높이는 그대로다 (버튼이 붙어도 [HyphenTokens.noticeSlotH] 안).
  final VoidCallback? onRetry;
  const HkNoticeSlot(this.message, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HyphenTokens.noticeSlotH,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) HkInlineError(message!, onRetry: onRetry),
        ],
      ),
    );
  }
}

/// 비동기 구역이 미리 잡아 두는 **예약된 자리** (공간 예약 / space reservation).
///
/// v3.34 (2026-08-27): 목록 구역을 `snap.data ?? []` 로 그리면 로딩 중에도
/// '없음' 문구가 먼저 뜨고, 응답이 도착하는 순간 내용이 튀어나오며 그 아래가
/// 통째로 밀린다. 한 화면에 그런 구역이 넷이면 도착 순서대로 네 번 밀린다.
///
/// 이 위젯은 셋을 **같은 자리**에 놓는다 — 로딩(스켈레톤) · 없음(문구) · 내용.
/// **로딩과 없음은 반드시 구분한다**: 아직 모르는 것과 없는 것은 다른 사실이다.
/// [minHeight] 는 그 구역의 한 줄 높이(평균 내용)로 잡는다 — 과하게 크면 빈
/// 화면이 허전해지고, 작으면 도착할 때 밀린다.
/// 규격·적용 대상 = DESIGN-SSOT §레이아웃 안정성.
class HkSectionSlot extends StatelessWidget {
  /// 항상 지키는 최소 높이. 내용이 이보다 길면 자연히 늘어난다.
  final double minHeight;

  /// 아직 도착하지 않았다 — 스켈레톤. ([child] 유무와 무관하게 우선한다.)
  final bool loading;

  /// 도착했는데 비어 있을 때의 한 줄 문구.
  final String empty;

  /// 도착한 내용. null 이면 [empty].
  final Widget? child;

  /// 스켈레톤 줄 수 — 그 구역의 한 줄 모양에 맞춘다.
  final int skeletonRows;

  const HkSectionSlot({
    super.key,
    required this.minHeight,
    required this.loading,
    required this.empty,
    this.child,
    this.skeletonRows = 1,
  });

  @override
  Widget build(BuildContext context) {
    final Widget inner;
    if (loading) {
      inner = _skeleton();
    } else if (child == null) {
      inner = Align(
        alignment: Alignment.topLeft,
        child: Text(empty, style: HyphenTokens.caption),
      );
    } else {
      inner = child!;
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: SizedBox(width: double.infinity, child: inner),
    );
  }

  /// 정적 스켈레톤 — 반짝이는 애니메이션을 쓰지 않는다 (골든·pumpAndSettle 이
  /// 영원히 안 끝난다. 움직임은 스피너 하나로 충분하다).
  Widget _skeleton() {
    final rows = skeletonRows < 1 ? 1 : skeletonRows;
    final rowH = (minHeight - HyphenTokens.sp2 * (rows - 1)) / rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) const SizedBox(height: HyphenTokens.sp2),
          _HkSkeletonBar(height: rowH),
        ],
      ],
    );
  }
}

/// 스켈레톤 한 줄 — 내용이 들어올 면의 크기만 미리 보여 준다.
class _HkSkeletonBar extends StatelessWidget {
  final double height;
  const _HkSkeletonBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: HyphenTokens.surfaceAlt,
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
    );
  }
}

/// 고른 값에 따라 나타나는 **미리보기 한 줄**의 예약된 자리 (공간 예약).
///
/// v3.33 (2026-08-27): [HkNoticeSlot] 이 에러·안내 전용이라면 이쪽은 일반
/// 미리보기용이다. `if (_x != null) ...[Row(...)]` 로 블록이 생겼다 사라지면
/// 그 아래 섹션이 통째로 밀린다 — 아직 고르지 않았을 때는 [placeholder] 한 줄이
/// 자리를 지키고, 고르면 [child] 로 갈아 끼운다. 바깥 높이는 어느 쪽이든 같다.
/// 규격·적용 대상 = DESIGN-SSOT §레이아웃 안정성.
class HkPreviewSlot extends StatelessWidget {
  /// 보여 줄 내용. null 이면 [placeholder] 한 줄이 대신 선다.
  final Widget? child;

  /// 아직 고르지 않았을 때 그 자리에 서는 안내 한 줄.
  final String placeholder;

  /// 슬롯 높이 — 들어올 수 있는 것 중 **가장 높은 것**(배지 26.2)에 맞춘다.
  final double height;

  const HkPreviewSlot({
    super.key,
    this.child,
    required this.placeholder,
    this.height = HyphenTokens.sp6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child:
            child ??
            Text(
              placeholder,
              style: HyphenTokens.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      ),
    );
  }
}

/// 스켈레톤 행 — 로딩 중 **모양만** 보여 주는 회색 자리 (skeleton screen).
///
/// v3.34 (2026-08-27 · DESIGN-SSOT §레이아웃 안정성). 목록이 로딩 → 완료로 바뀌면
/// 표가 한 줄에서 여러 줄로 커지며 그 아래를 통째로 밀어냈다. 이 행은 [HkListRow]
/// 한 줄과 **같은 높이**([rowH])를 차지해, 데이터가 도착해도 표 높이가 그대로다.
///
/// 공간 예약(space reservation)과는 다른 기법이다 — 자리를 잡는 것은 부모가 하고,
/// 이 위젯은 그 자리에 **무엇이 올지**를 미리 보여 준다. 둘을 같이 쓴다.
/// 깜빡이는 애니메이션은 두지 않는다 (무한 애니메이션은 골든·접근성 양쪽에 손해).
class HkSkeletonRow extends StatelessWidget {
  /// [HkListRow] 한 줄의 자연 높이 — 상하 sp2(8+8) + 제목(15×1.5=22.5) + 2 +
  /// 부제(13×1.45=18.85) = 59.35 → 60. 목록 자리는 이 값으로 예약한다.
  static const double rowH = 60;

  /// 좌측 배지(32) 자리를 함께 그릴지 — 업적 표처럼 아이콘이 붙는 목록용.
  final bool leading;
  const HkSkeletonRow({super.key, this.leading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp3),
        child: Row(
          children: [
            if (leading) ...[
              const HkSkeletonBar(
                width: 32,
                height: 32,
                radius: HyphenTokens.r2,
              ),
              const SizedBox(width: HyphenTokens.sp3),
            ],
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HkSkeletonBar(width: 116, height: 12),
                SizedBox(height: HyphenTokens.sp2),
                HkSkeletonBar(width: 172, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 스켈레톤 조각 — 글자·배지가 앉을 자리를 나타내는 회색 막대. 면은 border 1색.
class HkSkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const HkSkeletonBar({
    super.key,
    required this.width,
    required this.height,
    this.radius = HyphenTokens.r1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: HyphenTokens.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// 높이가 오락가락하는 영역의 **자리를 미리 잡아 두는 슬롯** (공간 예약 /
/// space reservation).
///
/// [HkNoticeSlot] 이 안내 한 줄 전용 고정 높이라면, 이쪽은 내용을 가리지 않는
/// 범용 자리다. 로딩 스피너 → 목록, 공지 없음 → 공지 배너, 버튼 묶음 → 상태
/// 박스처럼 **상태에 따라 높이가 갈리는 곳**에 씌우면 아래 요소가 밀리지 않는다.
/// 규격·적용 대상 = DESIGN-SSOT §레이아웃 안정성.
///
/// - [minHeight] 는 그 자리가 가질 수 있는 **가장 긴 경우**로 잡는다. 내용이
///   그보다 짧아도 자리는 남고, 길면 그만큼만 늘어난다.
/// - [child] 가 null 이면 빈 자리만 남긴다 (내용이 아직·영영 없을 때).
class HkReservedSlot extends StatelessWidget {
  final double minHeight;
  final Widget? child;
  const HkReservedSlot({super.key, required this.minHeight, this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

/// 진입 계열 화면(스플래시·로그인·전면 로딩)의 로고 위 고정 간격 (DESIGN-SSOT §6).
///
/// v3.3 (2026-08-21 사용자 지시 "로고 위치 고정"): 스플래시는 로고를 세로 중앙에,
/// 로그인은 콘텐츠 블록째 중앙에 놓아 화면이 넘어갈 때마다 로고가 위아래로 뛰었다.
/// 콘텐츠 높이와 무관하게 로고가 같은 자리에 서도록, 화면 높이의 24% 를
/// 로고 위에 고정으로 깐다 (sp5 패딩 안 기준 — 진입 화면은 전부 sp5 패딩).
class HkEntryLogoGap extends StatelessWidget {
  static const double fraction = 0.24;
  const HkEntryLogoGap({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.sizeOf(context).height * fraction);
  }
}

/// 전면 로딩 — 진입·전환 화면 유일 규격 (DESIGN-SSOT §6).
/// BrandLogo(기본 폭 220) + HkLoading + 선택 캡션. Scaffold body 로 그대로 끼운다.
/// v3.3: 세로 중앙 → HkEntryLogoGap 고정 오프셋 — 로그인 화면과 로고 자리가 같아
/// 버튼을 누르고 로딩으로 넘어가도 로고가 움직이지 않는다.
class HkLoadingScreen extends StatelessWidget {
  final String? caption;
  const HkLoadingScreen({super.key, this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HyphenTokens.bg,
      padding: const EdgeInsets.all(HyphenTokens.sp5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HkEntryLogoGap(),
          const Center(child: BrandLogo()),
          const SizedBox(height: HyphenTokens.sp6),
          const HkLoading(),
          if (caption != null) ...[
            const SizedBox(height: HyphenTokens.sp3),
            Text(
              caption!,
              style: HyphenTokens.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 소셜 로그인 버튼 — 유일 규격 (높이 52 · r3 · 마크+라벨 중앙, DESIGN-SSOT §6).
/// 색은 HyphenTokens 외부 브랜드 색(naverGreen·googleSurface)만 사용.
class HkSocialButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final String markText;
  final Color? markColor;
  final VoidCallback? onPressed;

  const HkSocialButton({
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
      height: HyphenTokens.buttonH,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(HyphenTokens.r3),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(HyphenTokens.r3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                markText,
                style: HyphenTokens.h3.copyWith(
                  color: markColor ?? foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: HyphenTokens.body.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: HyphenTokens.touchMin),
            ],
          ),
        ),
      ),
    );
  }
}

/// 스낵바 SSOT — 앱의 짧은 알림은 전부 이 창구로 낸다 (2026-08-21 신설).
///
/// 왜 필요했나: 스낵바가 화면마다 `ScaffoldMessenger...showSnackBar(SnackBar(...))`
/// 로 흩어져 있어(24개 파일) 모양·노출시간이 제각각이고, 캐릭터를 넣으려면
/// 전부를 따로 고쳐야 했다. 여기 하나로 모아 캐릭터 슬롯도 한 곳에만 둔다.
///
/// 캐릭터는 표정 3종(happy·sad·neutral)을 성격별로 돌려 쓴다 — 완료는 happy,
/// 실패는 sad, 안내는 neutral. 경로·존재 판단은 [HyphenMascot] SSOT 가 한다.
class HkSnack {
  const HkSnack._(this._messenger);

  final ScaffoldMessengerState _messenger;

  /// 비동기 작업 **전에** 미리 잡아 두는 손잡이. `await` 뒤에 context 를 다시
  /// 쓰면 위험하므로(화면이 이미 닫혔을 수 있다) 기존 코드가
  /// `final messenger = ScaffoldMessenger.of(context)` 로 잡아 두던 자리를
  /// 이것으로 바꾼다 — 같은 안전성에 캐릭터 슬롯만 얹힌다.
  static HkSnack of(BuildContext context) =>
      HkSnack._(ScaffoldMessenger.of(context));

  /// 손잡이로 내는 일반 알림.
  void info(String message, {MascotMood? mood, Duration? duration}) => _emit(
    _messenger,
    message,
    mood: mood,
    duration: duration ?? const Duration(seconds: 2),
  );

  /// 손잡이로 내는 실패 알림.
  void fail(String message) => _emit(
    _messenger,
    message,
    mood: MascotMood.sad,
    duration: const Duration(seconds: 3),
    danger: true,
  );

  static void _emit(
    ScaffoldMessengerState messenger,
    String message, {
    MascotMood? mood,
    required Duration duration,
    bool danger = false,
  }) {
    final showMascot = mood != null && HyphenMascot.has(mood);
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: HyphenTokens.surface,
        behavior: SnackBarBehavior.floating,
        // 2026-08-21 — M3 기본 그림자가 골든에서 검은 띠로 찍힌다. 이 앱은
        // 면+1px 테두리로 층을 표현하므로(글로벌 design-block 다중 그림자 금지)
        // 그림자를 끈다.
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          side: BorderSide(
            color: danger ? HyphenTokens.danger : HyphenTokens.border,
            width: 1,
          ),
        ),
        content: Row(
          children: [
            if (showMascot) ...[
              HyphenMascot(mood: mood, size: 32),
              const SizedBox(width: HyphenTokens.sp3),
            ],
            Expanded(
              child: Text(
                message,
                style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 일반 알림. [mood] 를 주면 캐릭터가 준비된 순간부터 함께 뜬다.
  static void show(
    BuildContext context,
    String message, {
    MascotMood? mood,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _emit(messenger, message, mood: mood, duration: duration);
  }

  /// 실패 알림 — 우는 표정(sad)을 쓴다. 웃는 캐릭터는 절대 붙이지 않는다.
  static void error(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _emit(
      messenger,
      message,
      mood: MascotMood.sad,
      duration: const Duration(seconds: 3),
      danger: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// v3.24 (2026-08-25 사용자 지시 "인라인·이원화 전부 통일") — 아래 4종은
// 화면마다 흩어져 있던 것을 HKit 으로 끌어올린 정본이다. 화면 코드에서
// AppBar( · AlertDialog( · showModalBottomSheet( · 에러 박스 Container 를
// 직접 쓰면 §3 코드·클래스 SSOT 위반 — 여기 것을 쓴다.
// ─────────────────────────────────────────────────────────────────────────

/// 상단바 정본. 모양은 테마(appBarTheme)가, **무엇을 싣는지**는 여기가 정한다.
///
/// - [HkAppBar] — 밀어 넣은(push) 화면: 뒤로가기 + 제목 (+ 선택 actions).
/// - [HkAppBar.identity] — 셸 상단바: 체육관명 + 역할 두 줄. 회원 셸·코치 셸이
///   같은 것을 쓴다 — 탭이 바뀌어도 상단바는 안 바뀐다 (브리프 D46·D47).
class HkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? identityName;
  final String? identityRole;
  final List<Widget>? actions;
  final bool implyLeading;

  const HkAppBar({
    super.key,
    this.title,
    this.actions,
    this.implyLeading = true,
  }) : identityName = null,
       identityRole = null;

  const HkAppBar.identity({
    super.key,
    required String name,
    required String role,
    this.actions,
  }) : title = null,
       identityName = name,
       identityRole = role,
       implyLeading = false;

  @override
  Size get preferredSize => const Size.fromHeight(HyphenTokens.appBarH);

  @override
  Widget build(BuildContext context) {
    if (identityName != null) {
      return AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              identityName!,
              style: HyphenTokens.h3.copyWith(color: HyphenTokens.fg),
            ),
            Text(
              identityRole!,
              style: HyphenTokens.micro.copyWith(color: HyphenTokens.primary),
            ),
          ],
        ),
        actions: actions,
      );
    }
    return AppBar(
      automaticallyImplyLeading: implyLeading,
      title: title == null ? null : Text(title!),
      actions: actions,
    );
  }
}

/// 다이얼로그 정본 — 모양은 테마(dialogTheme), 버튼은 [HkButton] 만.
///
/// 확인형은 [confirm] (되돌릴 수 없는 동작은 `danger: true`), 알림형은 [info],
/// 입력칸 등 자유 내용은 [custom]. 화면에서 AlertDialog 를 직접 만들지 않는다.
class HkDialog {
  HkDialog._();

  static const EdgeInsets _actionsPad = EdgeInsets.fromLTRB(
    HyphenTokens.sp3,
    0,
    HyphenTokens.sp3,
    HyphenTokens.sp3,
  );

  /// 취소/확정 두 버튼. 확정이면 true.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actionsPadding: _actionsPad,
        actions: [
          HkButton.tertiary(
            cancelLabel,
            neutral: true,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          danger
              ? HkButton.primary(
                  confirmLabel,
                  expand: false,
                  danger: true,
                  onPressed: () => Navigator.pop(ctx, true),
                )
              : HkButton.tertiary(
                  confirmLabel,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
        ],
      ),
    );
    return ok == true;
  }

  /// 확인 버튼 하나.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String label = '확인',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: _actionsPad,
        actions: [
          HkButton.tertiary(label, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  /// 자유 내용 (입력칸 등). actions 는 [HkButton] 으로 만든다.
  static Future<T?> custom<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    required List<Widget> Function(BuildContext ctx) actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: content,
        actionsPadding: _actionsPad,
        actions: actions(ctx),
      ),
    );
  }
}

/// 바텀시트 정본 — 모양은 테마(bottomSheetTheme). 항상 isScrollControlled.
/// 시트 안에서 자기 배경을 그리는 위젯(WodResultSheet)만 `transparent: true`.
class HkSheet {
  HkSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool transparent = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: transparent ? Colors.transparent : null,
      builder: builder,
    );
  }
}

/// 폼 안 인라인 에러 박스 (로그인 실패 등 — 화면을 갈아엎지 않고 그 자리에 알림).
/// 전면 에러는 [HkErrorState], 스낵은 [HkSnack.error] — 셋은 자리가 다르다.
class HkInlineError extends StatelessWidget {
  final String message;

  /// 있으면 우측에 '다시 시도' — 목록 위 한 줄 배너로 쓸 때 (v3.25).
  final VoidCallback? onRetry;
  const HkInlineError(this.message, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      message,
      style: HyphenTokens.caption.copyWith(color: HyphenTokens.danger),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HyphenTokens.sp3,
        vertical: onRetry == null ? HyphenTokens.sp2 : 0,
      ),
      decoration: BoxDecoration(
        color: HyphenTokens.danger.withValues(alpha: 0.12),
        border: Border.all(color: HyphenTokens.danger.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: onRetry == null
          ? text
          : Row(
              children: [
                Expanded(child: text),
                HkButton.tertiary('다시 시도', neutral: true, onPressed: onRetry),
              ],
            ),
    );
  }
}

/// 하단 탭바 정본 — 회원 셸·코치 셸이 같은 것을 쓴다 (v3.25 · 두 벌 → 하나).
/// 테마(색·인디케이터·라벨)·상단 구분선·SafeArea 까지 여기.
class HkTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  const HkTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: HyphenTokens.bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: HyphenTokens.accent.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
        ),
        // v2.2: 켜진 탭을 브랜드색으로 — 인디케이터 면 하나로만 구분되면 흐리다.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return HyphenTokens.micro.copyWith(
            color: selected ? HyphenTokens.primary : HyphenTokens.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.1,
          );
        }),
      ),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: HyphenTokens.border, width: 1),
            ),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            height: AppKit.tabbarH,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
