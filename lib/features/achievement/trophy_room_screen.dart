// v3.35 (2026-08-28 사용자 확정 "E 안"): 트로피 룸 — 업적 목록 행을 누르면 오는
// 화면 2. 같은 AchievementState 를 읽으므로 **로딩이 없다** (추가 호출 0 · 시프트 0).
//
// 위에서 아래로:
//  - 진열대 200 — 검은 판에 누른 업적. 배지 96 · 희귀도 · 제목 · 영문 · 조건 ·
//    분류/확인 방식 태그. 완료면 오른쪽 위 달성 도장, 아니면 "미달성"
//  - 분류 진척 44 — "연속 · 달성 1 / 3" + 4px 막대
//  - 같은 분류 배지 3열 (셀 112) — 탭하면 진열대만 바뀐다
//  - "다른 분류" 배지 3열 — 탭하면 그 분류의 룸으로 통째 바뀐다 (상단바 제목 포함).
//    분류에 업적이 적어 아래가 빌 때 계속 둘러보기.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../../widgets/hkit.dart';
import 'achievement_card.dart';
import 'achievement_group.dart';
import 'achievement_state.dart';
import 'achievements_screen.dart' show AchievementStamp;
import 'hyphen_pictogram.dart';

class TrophyRoomScreen extends StatefulWidget {
  final String code;
  const TrophyRoomScreen({super.key, required this.code});

  @override
  State<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends State<TrophyRoomScreen> {
  late String _code = widget.code;

  void _select(String code) {
    Haptic.light();
    setState(() => _code = code);
  }

  @override
  Widget build(BuildContext context) {
    final snap = context.watch<AchievementState>().snapshot;
    final all = snap.catalog;
    if (all.isEmpty) {
      return const Scaffold(
        appBar: HkAppBar(title: '업적'),
        body: SafeArea(child: HkEmptyState(title: '아직 업적 없음')),
      );
    }
    final sel = all.firstWhere((c) => c.code == _code, orElse: () => all.first);
    final group = AchievementGroup.of(sel.code);
    final label = AchievementGroup.label(group);
    final same = all.where((c) => AchievementGroup.of(c.code) == group).toList();
    final others = all
        .where((c) => AchievementGroup.of(c.code) != group)
        .toList();
    final n = same.where((c) => snap.isUnlocked(c.code)).length;

    return Scaffold(
      appBar: HkAppBar(title: label),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: HyphenTokens.sp5),
          children: [
            _Showcase(
              catalog: sel,
              unlock: snap.unlocked[sel.code],
              groupLabel: label,
            ),
            _GroupProgress(unlocked: n, total: same.length),
            _Grid(
              items: same,
              snap: snap,
              selected: sel.code,
              onTap: _select,
            ),
            if (others.isNotEmpty) ...[
              AchievementGroupLabel(
                label: '다른 분류',
                unlocked: others.where((c) => snap.isUnlocked(c.code)).length,
                total: others.length,
              ),
              _Grid(items: others, snap: snap, selected: null, onTap: _select),
            ],
          ],
        ),
      ),
    );
  }
}

/// 진열대 — 검은 판(ink 색) 위 선택 업적. 글자 줄마다 높이를 예약해 조건이 한 줄이든
/// 두 줄이든 판 높이·아래 요소가 그대로다.
class _Showcase extends StatelessWidget {
  static const double height = 200;
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  final String groupLabel;
  const _Showcase({
    required this.catalog,
    required this.unlock,
    required this.groupLabel,
  });

  @override
  Widget build(BuildContext context) {
    final open = unlock != null;
    final hidden = catalog.isHidden && !open;
    final pal = RarityPalette.of(catalog.rarity);
    final shape = HyphenPictogram.shapeFor(catalog.code);
    final onDark = HyphenTokens.onColor;
    final onDarkSub = onDark.withValues(alpha: 0.64);
    final onDarkBody = onDark.withValues(alpha: 0.84);

    return Container(
      height: height,
      color: HyphenTokens.fg,
      padding: const EdgeInsets.symmetric(
        horizontal: HyphenTokens.sp4 + 4,
        vertical: HyphenTokens.sp4 + 6,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 104,
                child: Center(
                  child: AchievementBadge(
                    code: catalog.code,
                    rarity: catalog.rarity,
                    icon: catalog.icon,
                    size: 96,
                    locked: !open,
                    hidden: hidden,
                  ),
                ),
              ),
              const SizedBox(width: HyphenTokens.sp4 + 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 16,
                      child: Text(
                        pal.ko,
                        style: HyphenTokens.micro.copyWith(
                          color: pal.light,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 26,
                      child: Text(
                        hidden ? '???' : AchievementCard.displayTitle(catalog),
                        style: HyphenTokens.h2.copyWith(color: onDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 20,
                      child: Text(
                        hidden ? '' : AchievementCard.gridLabel(catalog.name),
                        style: HyphenTokens.caption.copyWith(color: onDarkSub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: HyphenTokens.sp1 + 2),
                    SizedBox(
                      height: 40,
                      child: Text(
                        hidden
                            ? '조건 비공개 · 달성하면 공개'
                            : (open
                                  ? catalog.description
                                  : AchievementCard.lockedHint(catalog)),
                        style: HyphenTokens.caption.copyWith(
                          color: onDarkBody,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: HyphenTokens.sp1 + 2),
                    SizedBox(
                      height: 26,
                      child: Row(
                        children: hidden
                            ? [HkBadge('숨김', color: onDarkSub)]
                            : [
                                HkBadge(groupLabel, color: onDarkSub),
                                const SizedBox(width: HyphenTokens.sp1),
                                HkBadge(
                                  HyphenPictogram.shapeLabel(shape),
                                  color: onDarkSub,
                                ),
                                if (!open) ...[
                                  const Spacer(),
                                  Text(
                                    '미달성',
                                    style: HyphenTokens.micro.copyWith(
                                      color: onDarkSub,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (open)
            Positioned(
              right: 0,
              top: 0,
              child: AchievementStamp(
                date: unlock!.unlockedAt,
                color: Color.lerp(HyphenTokens.accent, onDark, 0.35)!,
              ),
            ),
        ],
      ),
    );
  }
}

/// 분류 진척 — "달성 1 / 3" + 4px 막대. 높이 44 고정. 분류 이름은 상단바가 갖는다.
class _GroupProgress extends StatelessWidget {
  final int unlocked;
  final int total;
  const _GroupProgress({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (unlocked / total).clamp(0, 1).toDouble();
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                // 문구 조정 6: 분류 이름은 상단바에 이미 있다 — 여기선 수치만.
                Text(
                  '달성 $unlocked / $total',
                  style: HyphenTokens.caption.copyWith(
                    color: HyphenTokens.fg,
                    fontWeight: FontWeight.w600,
                    fontFeatures: HyphenTokens.tabular,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(pct * 100).round()}%',
                  style: HyphenTokens.caption.copyWith(
                    fontFeatures: HyphenTokens.tabular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HyphenTokens.sp1 + 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(HyphenTokens.r1),
              child: Stack(
                children: [
                  Container(height: 4, color: HyphenTokens.border),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(height: 4, color: HyphenTokens.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 배지 3열 — 셀 112 고정 (배지 64 + 라벨 2줄 예약). ListView 안에 놓이므로
/// 스스로 스크롤하지 않는다.
class _Grid extends StatelessWidget {
  static const double cellH = 112;
  final List<AchievementCatalog> items;
  final AchievementSnapshot snap;
  final String? selected;
  final ValueChanged<String> onTap;
  const _Grid({
    required this.items,
    required this.snap,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        HyphenTokens.sp4,
        HyphenTokens.sp2,
        HyphenTokens.sp4,
        HyphenTokens.sp3,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: HyphenTokens.sp2,
        crossAxisSpacing: HyphenTokens.sp1 + 2,
        mainAxisExtent: cellH,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final c = items[i];
        return _Cell(
          catalog: c,
          unlocked: snap.isUnlocked(c.code),
          selected: c.code == selected,
          onTap: () => onTap(c.code),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final AchievementCatalog catalog;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;
  const _Cell({
    required this.catalog,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hidden = catalog.isHidden && !unlocked;
    // 선택 표시는 HkCard 의 테두리 색만 바꾼다 (배지 린트 §7-C — 선택 칩 신설 금지).
    return HkCard(
      onTap: onTap,
      radius: HyphenTokens.r2,
      borderColor: selected ? HyphenTokens.fg : Colors.transparent,
      borderWidth: 1.5,
      padding: const EdgeInsets.only(top: HyphenTokens.sp2),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Column(
              children: [
                AchievementBadge(
                  code: catalog.code,
                  rarity: catalog.rarity,
                  icon: catalog.icon,
                  size: 64,
                  locked: !unlocked,
                  hidden: hidden,
                ),
                const SizedBox(height: HyphenTokens.sp1 + 2),
                // 마침표 3분류: 그리드 타일 = 단어 라벨 → 마침표 없음.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HyphenTokens.sp1,
                  ),
                  child: Text(
                    hidden ? '???' : AchievementCard.displayTitle(catalog),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: HyphenTokens.micro.copyWith(
                      color: unlocked ? HyphenTokens.fg : HyphenTokens.muted,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            if (unlocked)
              const Positioned(
                right: HyphenTokens.sp2,
                top: 0,
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: HyphenTokens.success,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
