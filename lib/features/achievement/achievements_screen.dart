// v1.17 Sprint 18: Achievements grid screen — FIFA-style 3x3 + featured panel.
//
// 레이아웃 차용 (FIFA Online):
//  - 좌측 대형 featured 배지 + 한글/영문 라벨 + 조건/날짜
//  - 우측 3열 grid 카드 (체크 / 진행 / 잠금)
//  - 카테고리 필터 chip row
//
// 비주얼 톤 (hyphen 흑백·Obsession):
//  - surface #141414 카드 + border 1px
//  - 단색 outline 아이콘 (Material Icons.outlined)
//  - 완료 체크 = success #22C55E, locked 카드 opacity 0.35
//  - rarity 4-tier 컬러 thin bar (Common=muted, Rare=accent, Epic=tierElite, Legendary=tierGames)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import 'hyphen_pictogram.dart';
import '../../models/achievement.dart';
import '../../widgets/hkit.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'panel_b_screen.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _filter = 'ALL';
  String? _featuredCode;

  // v1.29 한글 기본 — PR 은 도메인 고정어라 영문 유지.
  // v3.2 (2026-08-20): Tier·Engine·히든 탭 삭제 — 백엔드 카탈로그 대수술로
  // 해당 그룹 업적이 전부 사라져 (달성 불가 트리거 삭제) 빈 탭만 남았었다.
  static const List<(String, String)> _filters = [
    ('ALL', '전체'),
    ('STREAK', '연속'),
    ('PR', 'PR'),
    ('SEASON', '시즌'),
    ('VOLUME', '누적'),
  ];

  /// v1.30: TIER 가 잡동사니 통이던 문제 해소 — Engine 점수·카테고리 숙련은
  /// 별도 ENGINE 으로 분리하고, 시즌 이벤트(CF_*)는 SEASON 으로 넣는다.
  static String _category(String code) {
    if (code.startsWith('REACH_') || code == 'TITLE_POLYMATH') return 'TIER';
    if (code.startsWith('SCORE_') ||
        code.startsWith('ALL_CAT_') ||
        code.startsWith('CAT_') ||
        code == 'HOLY_TRINITY' ||
        code == 'VOL_EQUAL' ||
        code == 'FIRST_ENGINE' ||
        code == 'TITLE_SCHOLAR') {
      return 'ENGINE';
    }
    if (code.startsWith('STREAK_') ||
        code == 'TITLE_OBSESSED' ||
        code == 'TITLE_RELENTLESS' ||
        code == 'VOL_TRIPLE_STREAK' ||
        code == 'VOL_QUINTUPLE_STREAK' ||
        code.startsWith('VOL_COMEBACK')) {
      return 'STREAK';
    }
    if (code.startsWith('PR_')) return 'PR';
    if (code.startsWith('SEASON_') || code.startsWith('CF_')) return 'SEASON';
    if (code.startsWith('EGG_')) return 'EASTER';
    if (code.startsWith('VOL_') ||
        code.startsWith('WOD_') ||
        code == 'TITLE_UNDEFEATED') {
      return 'VOLUME';
    }
    if (code.startsWith('GIRLS_') ||
        code.startsWith('HEROES_') ||
        code == 'GAMES_1') {
      return 'VOLUME';
    }
    return 'TIER';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;
    final all = snap.catalog;
    final filtered = _filter == 'ALL'
        ? all
        : all.where((c) => _category(c.code) == _filter).toList();
    final unlockedCount =
        all.where((c) => state.isUnlockedInUi(c.code)).length;
    final totalCount = all.length;

    // featured: 명시 선택 → 없으면 첫 잠금해제 → 없으면 첫 카탈로그.
    AchievementCatalog featured = const AchievementCatalog(
      code: '',
      name: '',
      description: '',
      rarity: 'Common',
      isHidden: false,
      sortOrder: 0,
    );
    if (_featuredCode != null) {
      for (final c in all) {
        if (c.code == _featuredCode) {
          featured = c;
          break;
        }
      }
    }
    if (featured.code.isEmpty && all.isNotEmpty) {
      featured = all.firstWhere(
        (c) => state.isUnlockedInUi(c.code),
        orElse: () => all.first,
      );
    }

    // /go 전수조사: 로딩/에러 분기 — 이전엔 빈 catalog 로 stats '0/0' 표시되어
    // 사용자가 '업적 없음' 으로 오해.
    final isLoading = state.isLoading && all.isEmpty;
    final hasError = state.error != null && all.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('업적'),
        actions: [
          // v1.20 Phase 2.5: Panel B 20-title 진입.
          IconButton(
            tooltip: '칭호',
            icon: const Icon(Icons.workspace_premium_outlined, size: 20),
            onPressed: () => openPanelB(context),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: HyphenTokens.muted),
                ),
              )
            : hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(HyphenTokens.sp5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('업적 로딩 실패',
                              style: HyphenTokens.sectionLabel),
                          const SizedBox(height: HyphenTokens.sp2),
                          Text(state.error!, style: HyphenTokens.caption),
                          const SizedBox(height: HyphenTokens.sp3),
                          OutlinedButton(
                            onPressed: () => state.load(),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
          children: [
            _StatsHeader(unlocked: unlockedCount, total: totalCount),
            _FilterRow(
              current: _filter,
              filters: _filters,
              onTap: (v) {
                Haptic.selection();
                setState(() => _filter = v);
              },
            ),
            const Divider(height: 1, color: HyphenTokens.border),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('아직 업적 없음.',
                          style: HyphenTokens.caption),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: featured.code.isEmpty
                              ? const SizedBox.shrink()
                              : _FeaturedPanel(
                                  catalog: featured,
                                  unlock: snap.unlocked[featured.code],
                                  unlockedInUi:
                                      state.isUnlockedInUi(featured.code),
                                ),
                        ),
                        const VerticalDivider(
                            width: 1, color: HyphenTokens.border),
                        Expanded(
                          flex: 7,
                          child: _Grid(
                            items: filtered,
                            state: state,
                            featuredCode: featured.code,
                            onTap: (code) {
                              Haptic.light();
                              setState(() => _featuredCode = code);
                            },
                          ),
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

class _StatsHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  const _StatsHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (unlocked / total).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HyphenTokens.sp4,
        HyphenTokens.sp3,
        HyphenTokens.sp4,
        HyphenTokens.sp2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$unlocked', style: HyphenTokens.display),
              const SizedBox(width: HyphenTokens.sp1),
              Text('/ $total',
                  style: HyphenTokens.h3.copyWith(color: HyphenTokens.muted)),
              const Spacer(),
              // 진척률은 성과·경고 강조 대상 아님 → muted (실기기 QA).
              Text(
                '${(pct * 100).toInt()}%',
                style: HyphenTokens.h3.copyWith(
                  fontFeatures: HyphenTokens.tabular,
                  color: HyphenTokens.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: HyphenTokens.sp1),
          Text('달성', style: HyphenTokens.sectionLabel),
          const SizedBox(height: HyphenTokens.sp2),
          ClipRRect(
            borderRadius: BorderRadius.circular(HyphenTokens.r1),
            child: Stack(children: [
              Container(height: 4, color: HyphenTokens.border),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(height: 4, color: HyphenTokens.accent),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String current;
  final List<(String, String)> filters;
  final void Function(String) onTap;
  const _FilterRow({
    required this.current,
    required this.filters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: HyphenTokens.sp4,
          vertical: HyphenTokens.sp2,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: HyphenTokens.sp2),
        itemBuilder: (ctx, i) {
          final (code, label) = filters[i];
          final selected = current == code;
          return HkBadge(
            label,
            color: HyphenTokens.fg,
            selected: selected,
            onTap: () => onTap(code),
          );
        },
      ),
    );
  }
}

class _FeaturedPanel extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  final bool unlockedInUi;
  const _FeaturedPanel({
    required this.catalog,
    required this.unlock,
    required this.unlockedInUi,
  });

  @override
  Widget build(BuildContext context) {
    final color = RarityPalette.of(catalog.rarity).light;
    final isHidden = catalog.isHidden && !unlockedInUi;
    return Padding(
      padding: const EdgeInsets.all(HyphenTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2026-08-21 — 픽토그램 팩 v1.0. AchievementBadge 가 판까지 그리므로
          // 아이콘을 감싸던 테두리 컨테이너는 걷었다 (안 걷으면 판이 두 겹).
          Center(
            child: AchievementBadge(
              code: catalog.code,
              rarity: catalog.rarity,
              icon: catalog.icon,
              size: 128,
              locked: !unlockedInUi,
              hidden: isHidden,
            ),
          ),
          const SizedBox(height: HyphenTokens.sp3),
          Text(
            catalog.rarity.toUpperCase(),
            style: HyphenTokens.microLabel.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: HyphenTokens.sp1),
          // v1.30: 한글 칭호가 제목, 영문 고유명이 부제 (홈 표와 표기 통일).
          Text(
            isHidden ? '???' : AchievementCard.displayTitle(catalog),
            style: HyphenTokens.h3.copyWith(
              color: unlockedInUi ? HyphenTokens.fg : HyphenTokens.muted,
            ),
          ),
          if (!isHidden &&
              AchievementCard.koreanTitle(catalog.code).isNotEmpty) ...[
            const SizedBox(height: HyphenTokens.sp1),
            Text(
              AchievementCard.gridLabel(catalog.name),
              style: HyphenTokens.caption,
            ),
          ],
          const SizedBox(height: HyphenTokens.sp3),
          Text(
            isHidden
                ? '· · · 조건 비공개. 해금 후 공개.'
                : (unlockedInUi
                    ? catalog.description
                    : AchievementCard.lockedHint(catalog)),
            style: HyphenTokens.caption,
          ),
          const Spacer(),
          if (unlockedInUi && unlock != null) ...[
            const Divider(height: 1, color: HyphenTokens.border),
            const SizedBox(height: HyphenTokens.sp2),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 14, color: HyphenTokens.success),
                const SizedBox(width: HyphenTokens.sp1),
                // 좁은 좌측 패널에서 가로 오버플로우 나던 자리 — Expanded 로 고정.
                Expanded(
                  child: Text(
                    '달성 · ${_formatDate(unlock!.unlockedAt)}',
                    style: HyphenTokens.micro.copyWith(
                      color: HyphenTokens.success,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else if (unlockedInUi) ...[
            // demoUnlocked (백엔드 trigger 미연동) — 'Demo' 표시.
            const Divider(height: 1, color: HyphenTokens.border),
            const SizedBox(height: HyphenTokens.sp2),
            Text('데모 달성.', style: HyphenTokens.micro),
          ] else ...[
            const Divider(height: 1, color: HyphenTokens.border),
            const SizedBox(height: HyphenTokens.sp2),
            Text('미달성',
                style: HyphenTokens.microLabel.copyWith(
                  fontWeight: FontWeight.w800,
                )),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }
}

class _Grid extends StatelessWidget {
  final List<AchievementCatalog> items;
  final AchievementState state;
  final String? featuredCode;
  final void Function(String) onTap;
  const _Grid({
    required this.items,
    required this.state,
    required this.featuredCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      // 실기기 QA: 3열은 셀 폭 부족으로 라벨이 단어 중간에서 개행
      // ("RX STA NDARD") → 2열로 가독 확보.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: HyphenTokens.sp2,
        crossAxisSpacing: HyphenTokens.sp2,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final c = items[i];
        final unlocked = state.isUnlockedInUi(c.code);
        final selected = c.code == featuredCode;
        return _GridCell(
          catalog: c,
          unlocked: unlocked,
          selected: selected,
          onTap: () => onTap(c.code),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  final AchievementCatalog catalog;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;
  const _GridCell({
    required this.catalog,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = RarityPalette.of(catalog.rarity).light;
    final isHidden = catalog.isHidden && !unlocked;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: HyphenTokens.surface,
          border: Border.all(
            // badge-lint: ignore — 배지가 아니라 선택 상태를 갖는 카드(그리드 칸).
            color: selected ? HyphenTokens.fg : HyphenTokens.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: AchievementBadge(
                      code: catalog.code,
                      rarity: catalog.rarity,
                      icon: catalog.icon,
                      size: 56,
                      locked: !unlocked,
                      hidden: isHidden,
                    ),
                  ),
                  if (unlocked)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(Icons.check_circle,
                          size: 14, color: HyphenTokens.success),
                    ),
                ],
              ),
            ),
            Container(height: 2, color: color),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HyphenTokens.sp1,
                vertical: HyphenTokens.sp1,
              ),
              // 마침표 3분류: 그리드 타일 = 단어 라벨 → 마침표 없음.
              // toUpperCase 제거 — 좁은 셀에서 대문자 폭 증가로 단어 중간 개행 유발.
              child: Text(
                isHidden ? '???' : AchievementCard.displayTitle(catalog),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: HyphenTokens.micro.copyWith(
                  color: unlocked ? HyphenTokens.fg : HyphenTokens.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

