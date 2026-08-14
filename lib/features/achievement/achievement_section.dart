import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../../widgets/hkit.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'achievements_screen.dart';

/// 업적 섹션 — 최근 해금 최대 5줄 표 (v1.30: 색 타일 3열 그리드 → 한 줄 한 항목).
/// 5개 초과 시 마지막 줄이 "그 외 N개" → 전체 보기.
/// Locked 항목은 이 섹션에서 제거 → AchievementsScreen 전용.
class AchievementSection extends StatelessWidget {
  const AchievementSection({super.key});

  static IconData _iconFor(String code) {
    if (code == 'FIRST_ENGINE') return Icons.bolt_outlined;
    if (code == 'ALL_CAT_80') return Icons.all_inclusive_outlined;
    if (code == 'WOD_50') return Icons.fitness_center_outlined;
    if (code.startsWith('REACH_')) return Icons.military_tech_outlined;
    if (code.startsWith('SCORE_')) return Icons.analytics_outlined;
    if (code.startsWith('STREAK_')) return Icons.local_fire_department_outlined;
    if (code.startsWith('GIRLS_')) return Icons.emoji_events_outlined;
    if (code.startsWith('HEROES_')) return Icons.shield_outlined;
    if (code.startsWith('GAMES_')) return Icons.sports_score_outlined;
    if (code.startsWith('TITLE_')) return Icons.workspace_premium_outlined;
    if (code.startsWith('SEASON_')) return Icons.wb_sunny_outlined;
    if (code.startsWith('EGG_')) return Icons.auto_awesome_outlined;
    if (code.startsWith('PR_')) return Icons.trending_up_outlined;
    if (code.startsWith('VOL_')) return Icons.bar_chart_outlined;
    return Icons.star_outline;
  }

  static Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'Rare':
        return HyphenTokens.accent;
      case 'Epic':
        return HyphenTokens.tierElite;
      case 'Legendary':
        return HyphenTokens.tierGames;
      default:
        return HyphenTokens.muted;
    }
  }

  void _showDetail(
    BuildContext context,
    AchievementCatalog catalog,
    AchievementUnlock? unlock,
  ) {
    Haptic.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: HyphenTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HyphenTokens.r3)),
      ),
      builder: (_) => _DetailSheet(
        catalog: catalog,
        unlock: unlock,
        icon: _iconFor(catalog.code),
        rarityColor: _rarityColor(catalog.rarity),
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
                  icon: _iconFor(c.code),
                  iconColor: _rarityColor(c.rarity),
                  title: _rowTitle(c),
                  subtitle: c.description,
                  trailing: c.rarity.toUpperCase(),
                  trailingColor: _rarityColor(c.rarity),
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
  final IconData icon;
  final Color rarityColor;

  const _DetailSheet({
    required this.catalog,
    required this.unlock,
    required this.icon,
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(HyphenTokens.r2),
                    border: Border.all(color: rarityColor, width: 1.5),
                  ),
                  child: Icon(icon, size: 28, color: rarityColor),
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
