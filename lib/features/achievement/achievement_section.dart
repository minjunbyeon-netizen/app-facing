import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../../widgets/fkit.dart';
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
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      default:
        return FacingTokens.muted;
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
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FacingTokens.r3)),
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
            const Expanded(child: FkSectionLabel('업적')),
            Text('$unlockedCount / $totalVisible', style: FacingTokens.caption),
            const SizedBox(width: FacingTokens.sp2),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: FacingTokens.accent,
                padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp2),
              ),
              onPressed: () => _goAll(context),
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp2),

        if (unlockedList.isEmpty)
          // 빈 상태 — 아직 해금 없음
          _EmptyState(onTap: () => _goAll(context))
        else
          FkRowCard(
            rows: [
              for (final c in displayItems)
                FkListRow(
                  icon: _iconFor(c.code),
                  iconColor: _rarityColor(c.rarity),
                  title: _rowTitle(c),
                  subtitle: c.description,
                  trailing: c.rarity.toUpperCase(),
                  trailingColor: _rarityColor(c.rarity),
                  onTap: () => _showDetail(context, c, snap.unlocked[c.code]),
                ),
              if (hasOverflow)
                FkListRow(
                  icon: Icons.more_horiz,
                  title: '그 외 $overflowCount개',
                  trailing: '전체 보기',
                  trailingColor: FacingTokens.accent,
                  onTap: () => _goAll(context),
                ),
            ],
          ),
      ],
    );
  }

  /// 행 제목 — 한글 칭호 우선, 없으면 업적 고유명(영문).
  static String _rowTitle(AchievementCatalog c) {
    final ko = AchievementCard.koreanTitle(c.code);
    return ko.isEmpty ? AchievementCard.gridLabel(c.name) : ko;
  }

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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp4),
        decoration: BoxDecoration(
          border: Border.all(color: FacingTokens.border, width: 0.8),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        child: Column(
          children: [
            Icon(Icons.military_tech_outlined,
                size: 28, color: FacingTokens.muted),
            const SizedBox(height: FacingTokens.sp2),
            Text(
              '아직 업적 없음.',
              style: FacingTokens.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'WOD를 완료하면 해금됩니다.',
              style: FacingTokens.micro,
              textAlign: TextAlign.center,
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
          FacingTokens.sp5,
          FacingTokens.sp4,
          FacingTokens.sp5,
          FacingTokens.sp5,
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
                  color: FacingTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: FacingTokens.sp4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                    border: Border.all(color: rarityColor, width: 1.5),
                  ),
                  child: Icon(icon, size: 28, color: rarityColor),
                ),
                const SizedBox(width: FacingTokens.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상세 시트 타이틀 = 선언형 고유명("First Ten.") 유지.
                      Text(
                        catalog.name,
                        style: FacingTokens.h3.copyWith(
                          color: FacingTokens.fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (AchievementCard.koreanTitle(catalog.code)
                          .isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(AchievementCard.koreanTitle(catalog.code),
                            style: FacingTokens.caption),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: FacingTokens.sp2, vertical: 4),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FacingTokens.r1),
                  ),
                  child: Text(
                    catalog.rarity.toUpperCase(),
                    style: FacingTokens.micro.copyWith(
                      color: rarityColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FacingTokens.sp4),
            Container(height: 1, color: FacingTokens.border),
            const SizedBox(height: FacingTokens.sp4),
            Text(
              isUnlocked ? catalog.description : _hint(),
              style: FacingTokens.body,
            ),
            if (isUnlocked) ...[
              const SizedBox(height: FacingTokens.sp3),
              Text(
                '${_fmt(unlock!.unlockedAt)} 해금',
                style: FacingTokens.caption.copyWith(color: FacingTokens.accent),
              ),
            ],
            const SizedBox(height: FacingTokens.sp2),
          ],
        ),
      ),
    );
  }

  String _hint() => catalog.isHidden
      ? '· · · (조건 공개 안 됨)'
      : AchievementCard.triggerHint(catalog.code);

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }
}
