import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../../widgets/hkit.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'achievements_screen.dart';
import 'hyphen_pictogram.dart';

/// 업적 섹션 — 최근 해금 최대 5줄 표 (v1.30: 색 타일 3열 그리드 → 한 줄 한 항목).
/// 5개 초과 시 마지막 줄이 "그 외 N개" → 전체 보기.
/// Locked 항목은 이 섹션에서 제거 → AchievementsScreen 전용.
class AchievementSection extends StatelessWidget {
  const AchievementSection({super.key});



  void _showDetail(
    BuildContext context,
    AchievementCatalog catalog,
    AchievementUnlock? unlock,
  ) {
    Haptic.light();
    HkSheet.show(
      context,
      builder: (_) => _DetailSheet(
        catalog: catalog,
        unlock: unlock,
        rarityColor: RarityPalette.of(catalog.rarity).light,
      ),
    );
  }

  void _goAll(BuildContext context) {
    Haptic.light();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AchievementsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;
    final totalVisible = snap.visibleCount;
    final unlockedCount = snap.unlockedCount;

    // 최근 해금 순 정렬
    final unlockedList = snap.catalog
        .where((c) => snap.isUnlocked(c.code))
        .toList()
      ..sort((a, b) {
        final ua = snap.unlocked[a.code]?.unlockedAt;
        final ub = snap.unlocked[b.code]?.unlockedAt;
        if (ua == null && ub == null) return 0;
        if (ua == null) return 1;
        if (ub == null) return -1;
        return ub.compareTo(ua);
      });

    // 5줄 고정: 초과분은 마지막 "그 외 N개" 줄로 접는다.
    const int kMax = 5;
    final bool hasOverflow = unlockedList.length > kMax;
    final displayItems =
        hasOverflow ? unlockedList.take(kMax).toList() : unlockedList;
    final overflowCount = unlockedCount - kMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 헤더
        Row(
          children: [
            const Expanded(child: HkSectionLabel('업적')),
            Text('$unlockedCount / $totalVisible', style: HyphenTokens.caption),
            const SizedBox(width: HyphenTokens.sp2),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: HyphenTokens.accent,
                padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp2),
              ),
              onPressed: () => _goAll(context),
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: HyphenTokens.sp2),

        if (unlockedList.isEmpty)
          // 빈 상태 — 아직 해금 없음
          _EmptyState(onTap: () => _goAll(context))
        else
          HkRowCard(
            rows: [
              for (final c in displayItems)
                HkListRow(
                  leadingWidget: AchievementBadge(
                    code: c.code,
                    rarity: c.rarity,
                    icon: c.icon,
                    size: 32,
                    locked: snap.unlocked[c.code] == null,
                    hidden: c.isHidden && snap.unlocked[c.code] == null,
                  ),
                  title: _rowTitle(c),
                  subtitle: c.description,
                  trailing: c.rarity.toUpperCase(),
                  trailingColor: RarityPalette.of(c.rarity).light,
                  onTap: () => _showDetail(context, c, snap.unlocked[c.code]),
                ),
              if (hasOverflow)
                HkListRow(
                  icon: Icons.more_horiz,
                  title: '그 외 $overflowCount개',
                  trailing: '전체 보기',
                  trailingColor: HyphenTokens.accent,
                  onTap: () => _goAll(context),
                ),
            ],
          ),
      ],
    );
  }

  /// 행 제목 — 한글 칭호 우선, 없으면 업적 고유명(영문). 표기 정본 = AchievementCard.
  static String _rowTitle(AchievementCatalog c) =>
      AchievementCard.displayTitle(c);

  // 부제 = 업적 설명(한글). 해금일은 행에 싣지 않고 상세 시트에서만 노출.
}

// ─── 빈 상태 ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // v2.5 (2026-08-12 사용자 지시): 아이콘 + 두 줄 세로 스택이 120 을 먹었다.
      // 한 줄로 눕혀 절반 이하로 (내용은 그대로).
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: HyphenTokens.sp2,
          horizontal: HyphenTokens.sp3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: HyphenTokens.border, width: 0.8),
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
        ),
        child: Row(
          children: [
            const Icon(Icons.military_tech_outlined,
                size: 18, color: HyphenTokens.muted),
            const SizedBox(width: HyphenTokens.sp2),
            const Expanded(
              child: Text(
                '아직 업적 없음. 수업 기록을 저장하면 해금됩니다.',
                style: HyphenTokens.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 상세 바텀시트 ────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  final Color rarityColor;

  const _DetailSheet({
    required this.catalog,
    required this.unlock,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = unlock != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          HyphenTokens.sp5,
          HyphenTokens.sp4,
          HyphenTokens.sp5,
          HyphenTokens.sp5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: HyphenTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: HyphenTokens.sp4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2026-08-21 픽토그램 팩 — AchievementBadge 가 판까지 그린다.
                // 감싸던 원형 컨테이너는 제거 (안 지우면 판이 두 겹).
                AchievementBadge(
                  code: catalog.code,
                  rarity: catalog.rarity,
                  icon: catalog.icon,
                  size: 52,
                  locked: unlock == null,
                  hidden: catalog.isHidden && unlock == null,
                ),
                const SizedBox(width: HyphenTokens.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상세 시트 타이틀 = 선언형 고유명("First Ten.") 유지.
                      Text(
                        catalog.name,
                        style: HyphenTokens.h3.copyWith(
                          color: HyphenTokens.fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (AchievementCard.koreanTitle(catalog.code)
                          .isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(AchievementCard.koreanTitle(catalog.code),
                            style: HyphenTokens.caption),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: HyphenTokens.sp2, vertical: 4),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(HyphenTokens.r1),
                  ),
                  child: Text(
                    catalog.rarity.toUpperCase(),
                    style: HyphenTokens.micro.copyWith(
                      color: rarityColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: HyphenTokens.sp4),
            Container(height: 1, color: HyphenTokens.border),
            const SizedBox(height: HyphenTokens.sp4),
            Text(
              isUnlocked ? catalog.description : _hint(),
              style: HyphenTokens.body,
            ),
            if (isUnlocked) ...[
              const SizedBox(height: HyphenTokens.sp3),
              Text(
                '${_fmt(unlock!.unlockedAt)} 해금',
                style: HyphenTokens.caption.copyWith(color: HyphenTokens.accent),
              ),
            ],
            const SizedBox(height: HyphenTokens.sp2),
          ],
        ),
      ),
    );
  }

  String _hint() => AchievementCard.lockedHint(catalog);

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }
}
