import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'achievements_screen.dart';

/// v1.16: Profile 탭 하단 ACHIEVEMENTS 섹션. 기본 collapsed.
class AchievementSection extends StatefulWidget {
  const AchievementSection({super.key});

  @override
  State<AchievementSection> createState() => _AchievementSectionState();
}

class _AchievementSectionState extends State<AchievementSection> {
  bool _expanded = false;
  bool _showLocked = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;
    final total = snap.visibleCount;
    final unlocked = snap.unlockedCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Haptic.light();
                    setState(() => _expanded = !_expanded);
                  },
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('ACHIEVEMENTS',
                            style: FacingTokens.sectionLabel),
                      ),
                      Text('$unlocked / $total',
                          style: FacingTokens.caption),
                      const SizedBox(width: FacingTokens.sp2),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: FacingTokens.muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: FacingTokens.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: FacingTokens.sp2,
                  ),
                ),
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AchievementsScreen(),
                  ));
                },
                child: const Text('View All'),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: FacingTokens.sp3),
            ..._buildCards(snap),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCards(AchievementSnapshot snap) {
    if (snap.catalog.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: FacingTokens.sp2),
          child: Text('카탈로그 로딩 중.', style: FacingTokens.caption),
        ),
      ];
    }
    // 해금 먼저(unlocked_at DESC), 미해금 뒤(sort_order ASC).
    final unlockedCards = <Widget>[];
    final lockedCards = <Widget>[];
    final unlockedList = snap.catalog
        .where((c) => snap.isUnlocked(c.code))
        .toList()
      ..sort((a, b) => snap.unlocked[b.code]!.unlockedAt
          .compareTo(snap.unlocked[a.code]!.unlockedAt));
    final lockedList = snap.catalog
        .where((c) => !snap.isUnlocked(c.code))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final c in unlockedList) {
      unlockedCards.add(AchievementCard(catalog: c, unlock: snap.unlocked[c.code]));
    }
    for (final c in lockedList) {
      lockedCards.add(AchievementCard(catalog: c));
    }
    final out = <Widget>[];
    out.addAll(unlockedCards);
    if (lockedList.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: FacingTokens.muted,
            alignment: Alignment.centerLeft,
          ),
          onPressed: () {
            Haptic.light();
            setState(() => _showLocked = !_showLocked);
          },
          child: Text(
            _showLocked
                ? 'Hide locked'
                : 'Show locked (${lockedList.length})',
          ),
        ),
      ));
      if (_showLocked) out.addAll(lockedCards);
    }
    return out;
  }
}
