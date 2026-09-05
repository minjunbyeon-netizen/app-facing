// v3.35 (2026-08-28 사용자 확정 "E 안"): 업적 화면 = **분류별 목록 → 트로피 룸** 2단.
//
// 구 v1.17 FIFA 식 좌우 분할(왼쪽 큰 배지 패널 + 오른쪽 2열 그리드)은 폐기 —
// 오른쪽 폭이 좁아 라벨이 잘리고, 왼쪽 패널 아래가 비고, 잠긴 업적의 조건이 눌러야
// 보였다. 시안 비교 = docs/design/achievements-redesign-2026-08-28.html.
//
// 화면 1 (이 파일) — 위에서 아래로, 전부 **높이 고정** (DESIGN-SSOT §레이아웃 안정성):
//  - 요약 카드 112 — 달성 n / 전체, 최근 달성, 원형 진척률
//  - 3칸 전환 40 — 전체 / 진행 중 / 완료 (퀘스트 요소)
//  - 분류 라벨 40 + 행 64×n — 배지 44 · 제목 + 확인 방식 태그 · 조건 ·
//    오른쪽은 완료면 달성 도장, 아니면 희귀도
// 행을 누르면 화면 2 = TrophyRoomScreen (같은 AchievementState — 추가 호출 없음).
//
// 로딩은 같은 자리에 스켈레톤을 깐다 — 스피너 하나로 두면 완료 순간 화면 전체가
// 교체된다(시프트). 회귀 게이트 = test/golden/achievements_stability_test.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/achievement.dart';
import '../../widgets/hkit.dart';
import 'achievement_card.dart';
import 'achievement_group.dart';
import 'achievement_state.dart';
import 'hyphen_pictogram.dart';
import 'trophy_room_screen.dart';

/// 레이아웃 안정성 테스트가 잡는 앵커 — 로딩·완료 두 상태에 같은 키가 있다.
class AchievementsAnchors {
  const AchievementsAnchors._();
  static const Key summary = Key('ach-summary');
  static const Key segment = Key('ach-segment');
  static const Key firstGroup = Key('ach-group-0');
  static const Key firstRow = Key('ach-row-0');
}

enum _Filter { all, todo, done }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  _Filter _filter = _Filter.all;

  /// 행 높이 — 배지 44(+판 두께 2.4) + 상하 sp2. 스켈레톤이 같은 값을 쓴다.
  static const double kRowH = 64;

  /// 도장·요약·분류 라벨·진열대와 같은 말 — "달성 / 미달성" (문구 조정 2).
  static const List<String> _filterLabels = ['전체', '미달성', '달성'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;
    final all = snap.catalog;

    // /go 전수조사: 로딩/에러 분기 — 이전엔 빈 catalog 로 stats '0/0' 표시되어
    // 사용자가 '업적 없음' 으로 오해.
    final isLoading = state.isLoading && all.isEmpty;
    final hasError = state.error != null && all.isEmpty;

    return Scaffold(
      appBar: HkAppBar(
        title: '업적',
      ),
      body: SafeArea(
        child: hasError
            // 문구 조정 3: "업적 로딩 실패" 라벨 삭제 — 메시지 + 다시 시도 공통 규격.
            ? HkErrorState(message: state.error!, onRetry: () => state.load())
            : isLoading
            ? const _SkeletonBody()
            : all.isEmpty
            ? const HkEmptyState(title: '아직 업적 없음')
            : _ListBody(
                snap: snap,
                filter: _filter,
                onFilter: (i) {
                  Haptic.selection();
                  setState(() => _filter = _Filter.values[i]);
                },
              ),
      ),
    );
  }
}

// ─── 완료 ────────────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  final AchievementSnapshot snap;
  final _Filter filter;
  final ValueChanged<int> onFilter;
  const _ListBody({
    required this.snap,
    required this.filter,
    required this.onFilter,
  });

  bool _pass(AchievementCatalog c) {
    final open = snap.isUnlocked(c.code);
    return switch (filter) {
      _Filter.all => true,
      _Filter.todo => !open,
      _Filter.done => open,
    };
  }

  @override
  Widget build(BuildContext context) {
    final all = snap.catalog;
    final unlockedCount = all.where((c) => snap.isUnlocked(c.code)).length;

    // 최근 달성 — 해금일 최신.
    AchievementCatalog? last;
    DateTime? lastAt;
    for (final c in all) {
      final at = snap.unlocked[c.code]?.unlockedAt;
      if (at == null) continue;
      if (lastAt == null || at.isAfter(lastAt)) {
        last = c;
        lastAt = at;
      }
    }

    final groups = <Widget>[];
    var groupIndex = 0;
    var rowIndex = 0;
    for (final (key, label) in AchievementGroup.ordered) {
      final members = all.where((c) => AchievementGroup.of(c.code) == key);
      if (members.isEmpty) continue;
      final shown = members.where(_pass).toList();
      if (shown.isEmpty) continue;
      final n = members.where((c) => snap.isUnlocked(c.code)).length;
      groups.add(
        AchievementGroupLabel(
          key: groupIndex == 0 ? AchievementsAnchors.firstGroup : null,
          label: label,
          unlocked: n,
          total: members.length,
        ),
      );
      groups.add(
        HkRowCard(
          margin: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
          rows: [
            for (final c in shown)
              _Row(
                key: rowIndex++ == 0 ? AchievementsAnchors.firstRow : null,
                catalog: c,
                unlock: snap.unlocked[c.code],
              ),
          ],
        ),
      );
      groupIndex++;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp5),
      children: [
        _Summary(
          key: AchievementsAnchors.summary,
          unlocked: unlockedCount,
          total: all.length,
          last: last,
          lastAt: lastAt,
        ),
        Padding(
          key: AchievementsAnchors.segment,
          padding: const EdgeInsets.fromLTRB(
            HyphenTokens.sp4,
            HyphenTokens.sp3,
            HyphenTokens.sp4,
            0,
          ),
          child: HkSegment(
            labels: _AchievementsScreenState._filterLabels,
            selected: filter.index,
            onSelected: onFilter,
          ),
        ),
        if (groups.isEmpty)
          // 문구 조정 5: 칸 이름을 그대로 받아 쓴다.
          HkEmptyState(
            title: filter == _Filter.done ? '달성한 업적 없음' : '미달성 업적 없음',
          )
        else
          ...groups,
      ],
    );
  }
}

/// 요약 카드 — 달성 n / 전체 · 최근 달성 · 원형 진척률. 높이 [height] 고정.
class _Summary extends StatelessWidget {
  static const double height = 112;
  final int unlocked;
  final int total;
  final AchievementCatalog? last;
  final DateTime? lastAt;
  const _Summary({
    super.key,
    required this.unlocked,
    required this.total,
    required this.last,
    required this.lastAt,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (unlocked / total).clamp(0, 1).toDouble();
    final recent = last == null || lastAt == null
        ? '최근 달성 없음'
        : '최근 · ${AchievementCard.displayTitle(last!)} · '
              '${lastAt!.gym().month}월 ${lastAt!.gym().day}일';
    return SizedBox(
      height: height,
      child: HkCard(
        margin: const EdgeInsets.fromLTRB(
          HyphenTokens.sp4,
          HyphenTokens.sp4,
          HyphenTokens.sp4,
          0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: HyphenTokens.sp4 + 2,
          vertical: HyphenTokens.sp3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HkSectionLabel('달성'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$unlocked',
                        style: HyphenTokens.h1.copyWith(
                          fontFeatures: HyphenTokens.tabular,
                        ),
                      ),
                      const SizedBox(width: HyphenTokens.sp1),
                      Text(
                        '/ $total',
                        style: HyphenTokens.body.copyWith(
                          color: HyphenTokens.muted,
                          fontFeatures: HyphenTokens.tabular,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    recent,
                    style: HyphenTokens.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: HyphenTokens.sp3),
            _Ring(fraction: pct),
          ],
        ),
      ),
    );
  }
}

/// 원형 진척률 64 — 테두리 6, 배경 border 색 위에 accent 호.
class _Ring extends StatelessWidget {
  static const double size = 64;
  final double fraction;
  const _Ring({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _RingPainter(fraction),
          ),
          Text(
            '${(fraction * 100).round()}%',
            style: HyphenTokens.micro.copyWith(
              color: HyphenTokens.fg,
              fontWeight: FontWeight.w700,
              fontFeatures: HyphenTokens.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  const _RingPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = HyphenTokens.border;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = HyphenTokens.accent;
    canvas.drawArc(rect, 0, 6.283185307, false, track);
    if (fraction > 0) {
      canvas.drawArc(rect, -1.5707963, 6.283185307 * fraction, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

/// 목록 행 — 높이 [_AchievementsScreenState.kRowH] 고정.
class _Row extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  const _Row({super.key, required this.catalog, required this.unlock});

  @override
  Widget build(BuildContext context) {
    final open = unlock != null;
    final hidden = catalog.isHidden && !open;
    final pal = RarityPalette.of(catalog.rarity);
    final shape = HyphenPictogram.shapeFor(catalog.code);

    final Widget trailing = open
        ? AchievementStamp(date: unlock!.unlockedAt)
        : HkBadge(pal.ko, color: pal.text);

    return SizedBox(
      height: _AchievementsScreenState.kRowH,
      child: Center(
        child: HkListRow(
          leadingWidget: AchievementBadge(
            code: catalog.code,
            rarity: catalog.rarity,
            icon: catalog.icon,
            size: 44,
            locked: !open,
            hidden: hidden,
          ),
          title: hidden ? '???' : AchievementCard.displayTitle(catalog),
          titleBadge: HkBadge(
            hidden ? '숨김' : HyphenPictogram.shapeLabel(shape),
          ),
          subtitle: hidden
              ? '조건 비공개 · 달성하면 공개'
              : (open ? catalog.description : AchievementCard.lockedHint(catalog)),
          // 오른쪽에 값(도장·희귀도)이 있는 행은 화살표를 붙이지 않는다 (HkListRow
          // 규칙) — 360 폭에서 제목·태그 자리를 지키는 쪽이 우선.
          trailingWidget: trailing,
          onTap: () {
            Haptic.light();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrophyRoomScreen(code: catalog.code),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 달성 도장 — accent 배지를 살짝 기울인 것 (퀘스트 요소). 목록 행·트로피 룸 공용.
/// 새 배지 variant 가 아니라 [HkBadge] 그대로에 회전만 얹는다 (§3 코드·클래스 SSOT).
class AchievementStamp extends StatelessWidget {
  final DateTime date;
  final Color color;
  const AchievementStamp({
    super.key,
    required this.date,
    this.color = HyphenTokens.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.105,
      child: HkBadge('달성 ${mdShort(date.gym())}', color: color),
    );
  }
}

// ─── 로딩 ────────────────────────────────────────────────────────────────────

/// 스켈레톤 — 완료 화면과 **같은 자리, 같은 높이**. 요약 카드 → 3칸 → 분류 라벨 →
/// 행 3 → 라벨 → 행 2. 깜빡임 없음 (HkSkeletonRow 규약).
class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    const row = HkSkeletonRow(
      leading: true,
      height: _AchievementsScreenState.kRowH,
      leadingSize: 44,
    );
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp5),
      children: [
        SizedBox(
          key: AchievementsAnchors.summary,
          height: _Summary.height,
          child: HkCard(
            margin: const EdgeInsets.fromLTRB(
              HyphenTokens.sp4,
              HyphenTokens.sp4,
              HyphenTokens.sp4,
              0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: HyphenTokens.sp4 + 2,
              vertical: HyphenTokens.sp3,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HkSkeletonBar(width: 28, height: 10),
                      SizedBox(height: HyphenTokens.sp2),
                      HkSkeletonBar(width: 86, height: 26),
                      SizedBox(height: HyphenTokens.sp2),
                      HkSkeletonBar(width: 150, height: 11),
                    ],
                  ),
                ),
                const SizedBox(width: HyphenTokens.sp3),
                HkSkeletonBar(
                  width: _Ring.size,
                  height: _Ring.size,
                  radius: _Ring.size / 2,
                ),
              ],
            ),
          ),
        ),
        Padding(
          key: AchievementsAnchors.segment,
          padding: const EdgeInsets.fromLTRB(
            HyphenTokens.sp4,
            HyphenTokens.sp3,
            HyphenTokens.sp4,
            0,
          ),
          child: const HkSkeletonBar(
            width: double.infinity,
            height: HkSegment.height,
          ),
        ),
        const _SkeletonGroupLabel(key: AchievementsAnchors.firstGroup, w: 64),
        const HkRowCard(
          margin: EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
          rows: [
            KeyedSubtree(key: AchievementsAnchors.firstRow, child: row),
            row,
            row,
          ],
        ),
        const _SkeletonGroupLabel(w: 48),
        const HkRowCard(
          margin: EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
          rows: [row, row],
        ),
      ],
    );
  }
}

class _SkeletonGroupLabel extends StatelessWidget {
  final double w;
  const _SkeletonGroupLabel({super.key, required this.w});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AchievementGroupLabel.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          HyphenTokens.sp4,
          0,
          HyphenTokens.sp4,
          HyphenTokens.sp1 + 2,
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: HkSkeletonBar(width: w, height: 12),
        ),
      ),
    );
  }
}

