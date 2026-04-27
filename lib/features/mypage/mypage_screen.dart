import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/athletes.dart';
import '../../core/haptic.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/ui_prefs_state.dart';
import '../../core/unit_state.dart';
import '../../core/weak_insight.dart';
import '../../core/worn_title_store.dart';
import '../../models/achievement.dart';
import '../achievement/achievement_card.dart';
import '../achievement/achievement_section.dart';
import '../achievement/achievement_state.dart';
import '../inbox/inbox_screen.dart';
import '../inbox/inbox_state.dart';
import '../../widgets/tier_badge.dart';
import '../auth/auth_state.dart';
import '../goals/goals_screen.dart';
import '../gym/coach_dashboard_screen.dart';
import '../gym/gym_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';
import 'algorithm_screen.dart';
import 'import_screen.dart';
import 'privacy_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
          children: const [
            _TierSnapshot(),
            _WornTitleLine(),
            _InboxEntry(),
            _SectionDivider(),
            _TierRoadmap(),
            _SectionDivider(),
            _EngineTrend(),
            _SectionDivider(),
            _RoleModelCard(),
            _SectionDivider(),
            _CategoryTiers(),
            _SectionDivider(),
            _RecentRecords(),
            _SectionDivider(),
            AchievementSection(),
            _SectionDivider(),
            _MyBoxSection(),
            _SectionDivider(),
            _BodyStats(),
            _SectionDivider(),
            _SettingsSection(),
            _SectionDivider(),
            _ActionsSection(),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: Divider(height: 1, color: FacingTokens.border),
      );
}

/// v1.16: 한 줄로 축소 — 큰 숫자는 Trends로 이관. 여기는 간결 요약.
class _TierSnapshot extends StatelessWidget {
  const _TierSnapshot();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final g = p.gradeResult;
    final num? n = g?['overall_number'] is num ? g!['overall_number'] as num : null;
    final tier = Tier.fromOverallNumber(n);
    final rawScore = g?['overall_score'];
    final score100 = engineScoreTo100(rawScore);
    final topPct = engineScoreToTopPercent(rawScore);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT TIER', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          if (n == null)
            const Text('데이터 없음. 온보딩 완료 후 표시.',
                style: FacingTokens.caption)
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TierBadge(tier: tier, fontSize: 16),
                const SizedBox(width: FacingTokens.sp3),
                Text('$score100 / 100',
                    style: FacingTokens.h3.copyWith(
                      fontFeatures: FacingTokens.tabular,
                    )),
                const SizedBox(width: FacingTokens.sp3),
                Text(
                  formatTopPercentMock(topPct),
                  style: FacingTokens.caption.copyWith(
                    color: FacingTokens.muted,
                    fontWeight: FontWeight.w700,
                    fontFeatures: FacingTokens.tabular,
                  ),
                ),
              ],
            ),
            // v1.16 Sprint 7a: Masters 연령 분류 배지.
            Builder(builder: (ctx) {
              final label = mastersLabel(p.ageYears);
              if (label == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: FacingTokens.sp2),
                child: Text(
                  label,
                  style: FacingTokens.micro.copyWith(
                    color: FacingTokens.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// v1.15.3: 카테고리별(5개) Tier + Score(0~100) + Top%(백분위 근사).
/// 각 카테고리는 `gradeResult[key] = {number, score, items_used, missing}`.
class _CategoryTiers extends StatelessWidget {
  const _CategoryTiers();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final g = p.gradeResult;
    if (g == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('CATEGORY TIERS', style: FacingTokens.sectionLabel),
            SizedBox(height: FacingTokens.sp2),
            Text('온보딩 완료 후 표시.', style: FacingTokens.caption),
          ],
        ),
      );
    }
    final specs = <(String, String)>[
      ('POWER', 'power'),
      ('OLYMPIC', 'olympic'),
      ('GYMNASTICS', 'gymnastics'),
      ('CARDIO', 'cardio'),
      ('METCON', 'metcon'),
    ];
    final rows = <Widget>[];
    for (final (title, key) in specs) {
      final data = g[key];
      if (data is! Map) continue;
      final num? scoreNum = data['score'] is num ? data['score'] as num : null;
      if (scoreNum == null) continue;
      // v1.16 버그 fix: 백엔드 누락·구버전 저장본 대비 number/grade/score fallback.
      final catNum = resolveCategoryNumber(data);
      rows.add(_CategoryTierRow(
        title: title,
        tier: Tier.fromOverallNumber(catNum),
        score100: engineScoreTo100(scoreNum),
        topPct: engineScoreToTopPercent(scoreNum),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CATEGORY TIERS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp1),
          Text('백분위는 CrossFit 커뮤니티 분포 근사값',
              style: FacingTokens.caption),
          const SizedBox(height: FacingTokens.sp3),
          if (rows.isEmpty)
            const Text('카테고리 데이터 없음', style: FacingTokens.caption)
          else
            ...rows,
        ],
      ),
    );
  }
}

class _CategoryTierRow extends StatelessWidget {
  final String title;
  final Tier tier;
  final int score100;
  final double topPct;
  const _CategoryTierRow({
    required this.title,
    required this.tier,
    required this.score100,
    required this.topPct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: FacingTokens.sectionLabel),
              ),
              TierBadge(tier: tier),
              const SizedBox(width: FacingTokens.sp3),
              Text(
                formatTopPercent(topPct),
                style: FacingTokens.caption.copyWith(
                  color: FacingTokens.fg,
                  fontWeight: FontWeight.w700,
                  fontFeatures: FacingTokens.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  '$score100',
                  style: FacingTokens.lead.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: FacingTokens.tabular,
                  ),
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(FacingTokens.r1),
                  child: Stack(
                    children: [
                      Container(height: 6, color: FacingTokens.border),
                      FractionallySizedBox(
                        widthFactor: (score100 / 100).clamp(0.02, 1.0),
                        child: Container(height: 6, color: tier.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// v1.15.3: 소속 박스 요약. owner면 'Manage Members' 버튼 노출.
class _MyBoxSection extends StatelessWidget {
  const _MyBoxSection();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MY BOX', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          if (gym == null)
            const Text('박스 미가입. WOD 탭에서 Find Box.',
                style: FacingTokens.caption)
          else ...[
            Text(gym.name,
                style: FacingTokens.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '${gs.isOwner ? 'OWNER' : 'MEMBER'} · ${gs.membership.status ?? '-'} · ${gym.memberCount} members',
              style: FacingTokens.caption,
            ),
            if (gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp3),
              OutlinedButton(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CoachDashboardScreen(),
                  ));
                },
                child: const Text('Manage Members'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// v1.16: Engine 점수 + delta + 5축 radar 차트 (POWER·OLYMPIC·GYMNASTICS·CARDIO·METCON).
class _EngineTrend extends StatefulWidget {
  const _EngineTrend();

  @override
  State<_EngineTrend> createState() => _EngineTrendState();
}

class _EngineTrendState extends State<_EngineTrend> {
  Future<List<EngineSnapshotRecord>>? _future;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _future = repo.listEngineSnapshots(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();
    final grade = profile.gradeResult;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ENGINE SCORE', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          FutureBuilder<List<EngineSnapshotRecord>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Text('Loading.', style: FacingTokens.caption);
              }
              final records = snap.data ?? const [];
              // Overall 숫자·delta는 history snapshot에서, radar 값은 gradeResult에서.
              final latest = records.isNotEmpty ? records.first : null;
              final prev = records.length > 1 ? records[1] : null;
              final current = latest == null
                  ? 0
                  : engineScoreTo100(latest.overallScore);
              final delta = (latest != null && prev != null)
                  ? current - engineScoreTo100(prev.overallScore)
                  : 0;

              // Radar 데이터 (5축) — gradeResult에서 카테고리 score 추출.
              final radarValues = <_RadarAxis>[
                _RadarAxis('POWER', _catScore(grade, 'power')),
                _RadarAxis('OLYMPIC', _catScore(grade, 'olympic')),
                _RadarAxis('GYMNASTICS', _catScore(grade, 'gymnastics')),
                _RadarAxis('CARDIO', _catScore(grade, 'cardio')),
                _RadarAxis('METCON', _catScore(grade, 'metcon')),
              ];
              final hasRadarData = radarValues.any((a) => a.value > 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$current', style: FacingTokens.displayCompact),
                      const SizedBox(width: FacingTokens.sp2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('/ 100', style: FacingTokens.caption),
                      ),
                      const Spacer(),
                      if (prev != null)
                        Text(
                          delta > 0
                              ? '▲ +$delta'
                              : (delta < 0 ? '▼ $delta' : 'Hold.'),
                          style: FacingTokens.caption.copyWith(
                            color: delta > 0
                                ? FacingTokens.success
                                : (delta < 0
                                    ? FacingTokens.warning
                                    : FacingTokens.muted),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp4),
                  if (!hasRadarData)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: FacingTokens.sp4),
                      child: Text('카테고리 데이터 없음.',
                          style: FacingTokens.caption),
                    )
                  else ...[
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: CustomPaint(
                        painter: _RadarPainter(axes: radarValues),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // v1.16 Sprint 7b U4: 약점 자동 강조 + mock AI 코멘트.
                    const SizedBox(height: FacingTokens.sp3),
                    Builder(builder: (ctx) {
                      final insight = analyzeWeakness({
                        for (final a in radarValues) a.label: a.value,
                      });
                      if (insight == null) return const SizedBox.shrink();
                      final isBalanced =
                          insight.weakestCategory == 'BALANCED';
                      return Container(
                        padding: const EdgeInsets.fromLTRB(
                          FacingTokens.sp3,
                          FacingTokens.sp3,
                          FacingTokens.sp3,
                          FacingTokens.sp3,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isBalanced
                                  ? FacingTokens.success
                                  : FacingTokens.accent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBalanced
                                  ? 'BALANCED'
                                  : '${insight.weakestCategory} · WEAKEST',
                              style: FacingTokens.micro.copyWith(
                                color: isBalanced
                                    ? FacingTokens.success
                                    : FacingTokens.accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: FacingTokens.sp1),
                            Text(insight.comment,
                                style: FacingTokens.caption),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// gradeResult[key].score → 0~100 환산.
  int _catScore(Map<String, dynamic>? grade, String key) {
    if (grade == null) return 0;
    final data = grade[key];
    if (data is! Map) return 0;
    final s = data['score'];
    if (s is! num) return 0;
    return engineScoreTo100(s);
  }
}

class _RadarAxis {
  final String label;
  final int value; // 0~100
  const _RadarAxis(this.label, this.value);
}

/// v1.16: N축 radar 차트 (기본 5축 pentagon).
/// - 배경 polygon 3단계 (33/66/100%)
/// - 축선 5개
/// - 사용자 폴리곤 (accent fill + stroke)
/// - 각 꼭짓점에 레이블
class _RadarPainter extends CustomPainter {
  final List<_RadarAxis> axes;
  _RadarPainter({required this.axes});

  static const double _topAngle = -3.14159265 / 2; // 정상(위)부터 시작

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;
    final center = Offset(size.width / 2, size.height / 2);
    // 레이블 여유 공간 고려해 반경 축소.
    final radius = size.shortestSide / 2 - 28;
    final angleStep = 2 * 3.14159265 / n;

    // 1) 배경 polygon — 3단계 (33 · 66 · 100).
    final bgPaint = Paint()
      ..color = FacingTokens.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final ratio in [0.33, 0.66, 1.0]) {
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = _topAngle + angleStep * i;
        final x = center.dx + radius * ratio * math.cos(angle);
        final y = center.dy + radius * ratio * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, bgPaint);
    }

    // 2) 축 선 (center → 꼭짓점)
    final axisPaint = Paint()
      ..color = FacingTokens.border
      ..strokeWidth = 1;
    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // 3) 사용자 폴리곤
    final userPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      final ratio = (axes[i].value / 100).clamp(0.02, 1.0);
      final x = center.dx + radius * ratio * math.cos(angle);
      final y = center.dy + radius * ratio * math.sin(angle);
      if (i == 0) {
        userPath.moveTo(x, y);
      } else {
        userPath.lineTo(x, y);
      }
    }
    userPath.close();
    canvas.drawPath(
      userPath,
      Paint()
        ..color = FacingTokens.accent.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      userPath,
      Paint()
        ..color = FacingTokens.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // 꼭짓점 작은 원
    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      final ratio = (axes[i].value / 100).clamp(0.02, 1.0);
      final x = center.dx + radius * ratio * math.cos(angle);
      final y = center.dy + radius * ratio * math.sin(angle);
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = FacingTokens.accent,
      );
    }

    // 4) 레이블
    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      final lx = center.dx + (radius + 16) * math.cos(angle);
      final ly = center.dy + (radius + 16) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: axes[i].label,
          style: const TextStyle(
            fontFamily: FacingTokens.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: FacingTokens.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 80);
      final offset = Offset(lx - tp.width / 2, ly - tp.height / 2);
      tp.paint(canvas, offset);
      // 값 한 줄 아래
      final vp = TextPainter(
        text: TextSpan(
          text: '${axes[i].value}',
          style: const TextStyle(
            fontFamily: FacingTokens.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: FacingTokens.fg,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final vOffset = Offset(lx - vp.width / 2, ly + tp.height / 2 + 1);
      vp.paint(canvas, vOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) {
    if (old.axes.length != axes.length) return true;
    for (int i = 0; i < axes.length; i++) {
      if (old.axes[i].value != axes[i].value) return true;
      if (old.axes[i].label != axes[i].label) return true;
    }
    return false;
  }
}

/// v1.16: 최근 측정 기록 — Trends에서 이관. 깔끔 row 5개.
class _RecentRecords extends StatefulWidget {
  const _RecentRecords();

  @override
  State<_RecentRecords> createState() => _RecentRecordsState();
}

class _RecentRecordsState extends State<_RecentRecords> {
  Future<List<EngineSnapshotRecord>>? _future;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _future = repo.listEngineSnapshots(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECENT RECORDS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          FutureBuilder<List<EngineSnapshotRecord>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Text('Loading.', style: FacingTokens.caption);
              }
              final records = snap.data ?? const [];
              if (records.isEmpty) {
                return const Text('기록 없음.', style: FacingTokens.caption);
              }
              return Column(
                children: records
                    .map((r) => _RecordRow(r: r))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final EngineSnapshotRecord r;
  const _RecordRow({required this.r});

  @override
  Widget build(BuildContext context) {
    final tier = Tier.fromOverallNumber(r.overallNumber);
    final d = r.scoredAt.toLocal();
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final score100 = engineScoreTo100(r.overallScore);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Row(
        children: [
          Expanded(
            child: Text(date, style: FacingTokens.body),
          ),
          TierBadge(tier: tier),
          const SizedBox(width: FacingTokens.sp3),
          SizedBox(
            width: 40,
            child: Text('$score100',
                textAlign: TextAlign.right,
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: FacingTokens.tabular,
                )),
          ),
        ],
      ),
    );
  }
}

class _BodyStats extends StatelessWidget {
  const _BodyStats();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final unit = context.watch<UnitState>();
    final weightDisplay = p.bodyWeightKg == null
        ? '-'
        : '${_fmt(unit.kgToDisplay(p.bodyWeightKg!)!)} ${unit.weightSuffix}';
    final height = p.heightCm == null ? '-' : '${_fmt(p.heightCm!)} cm';
    final age = p.ageYears == null ? '-' : '${_fmt(p.ageYears!)} yr';
    final sex = p.gender == 'female' ? 'Female' : 'Male';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BODY', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          _Kv(label: 'Weight', value: weightDisplay),
          _Kv(label: 'Height', value: height),
          _Kv(label: 'Age', value: age),
          _Kv(label: 'Sex', value: sex),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  const _Kv({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: FacingTokens.caption)),
          Expanded(
            flex: 5,
            child: Text(value,
                style: FacingTokens.body.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SETTINGS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            children: [
              const Expanded(child: Text('Unit', style: FacingTokens.body)),
              Consumer<UnitState>(
                builder: (ctx, u, _) => _UnitToggle(u: u),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          // v1.16 Sprint 9a: 폰트 확대 옵션 (Masters 접근성).
          Consumer<UiPrefsState>(
            builder: (ctx, ui, _) => Row(
              children: [
                const Expanded(
                    child: Text('Font Size', style: FacingTokens.body)),
                _TextScaleToggle(current: ui.textScale, state: ui),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// v1.16 Sprint 9a: 폰트 확대 3단계 토글 (100/115/130%).
class _TextScaleToggle extends StatelessWidget {
  final double current;
  final UiPrefsState state;
  const _TextScaleToggle({required this.current, required this.state});

  @override
  Widget build(BuildContext context) {
    const options = [(1.0, 'A'), (1.15, 'A+'), (1.30, 'A++')];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final selected = (current - o.$1).abs() < 0.01;
        return Padding(
          padding: const EdgeInsets.only(left: FacingTokens.sp1),
          child: InkWell(
            onTap: () {
              Haptic.light();
              state.setTextScale(o.$1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp3,
                vertical: FacingTokens.sp2,
              ),
              decoration: BoxDecoration(
                color: selected ? FacingTokens.fg : FacingTokens.bg,
                border: Border.all(
                  color: selected ? FacingTokens.fg : FacingTokens.border,
                ),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              child: Text(
                o.$2,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final UnitState u;
  const _UnitToggle({required this.u});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(label: 'kg', selected: u.isKg, onTap: () {
          if (!u.isKg) u.toggle();
        }),
        const SizedBox(width: FacingTokens.sp2),
        _Pill(label: 'lb', selected: !u.isKg, onTap: () {
          if (u.isKg) u.toggle();
        }),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // v1.15 P1-3/P1-4: Semantics + 48dp 터치.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FacingTokens.r4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FacingTokens.touchMin),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp4,
              vertical: FacingTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: selected ? FacingTokens.fg : Colors.transparent,
              borderRadius: BorderRadius.circular(FacingTokens.r4),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.muted,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // v1.16: 계정 섹션 (로그인 상태 표시 + 로그아웃)
          Consumer<AuthState>(
            builder: (ctx, auth, _) {
              if (!auth.isSignedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${auth.provider?.toUpperCase() ?? '-'} · ${auth.displayName ?? ''}',
                        style: FacingTokens.caption,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                      ),
                      onPressed: () => _confirmSignOut(context),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
            },
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/onboarding/basic'),
            child: const Text('Edit Profile'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/history'),
            child: const Text('View History'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          // v1.16 Sprint 7b U2: 프라이버시 정책 + 탈퇴 진입점.
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PrivacyScreen(),
            )),
            child: const Text('Privacy Policy'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          // v1.16 Sprint 8 U5: Import 진입점.
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ImportScreen(),
            )),
            child: const Text('Import Data'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          // v1.16 Sprint 13: 목표 관리 (P1-P4 공통).
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const GoalsScreen(),
            )),
            child: const Text('Goals'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          // v1.16 Sprint 11: Engine 계산식 투명성 (P9 Q9-Q15).
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AlgorithmScreen(),
            )),
            child: const Text('Algorithm'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: FacingTokens.accent,
            ),
            onPressed: () => _confirmReset(context),
            child: const Text('Reset data'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('Reset data?'),
        content: const Text(
          '프로필·등급·벤치마크를 전부 삭제합니다.\n'
          '되돌릴 수 없습니다.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('로그아웃'),
        content: const Text(
          '로그아웃해도 프로필·기록은 이 기기에 그대로 유지됩니다.\n'
          '같은 provider로 다시 로그인하면 모든 데이터 복구.\n'
          '계정 자체를 지우려면 Privacy Policy → 계정 탈퇴.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.muted),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/signup', (_) => false);
  }
}

/// v1.16 Sprint 13: Tier 승급 로드맵 (P3/P6 요구).
/// 현재 Engine score → 다음 Tier 임계까지 필요 점수 + 약한 카테고리 표시.
class _TierRoadmap extends StatelessWidget {
  const _TierRoadmap();

  // overallNumber 1-6 → next threshold (backend scale 1.0-6.0).
  // UI 100-point mapping: 1→0-17, 2→17-33, 3→33-50, 4→50-67, 5→67-83, 6→83-100.
  static const List<int> _tierThresholds = [17, 33, 50, 67, 83, 100];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final g = p.gradeResult;
    final num? n =
        g?['overall_number'] is num ? g!['overall_number'] as num : null;
    if (n == null) return const SizedBox.shrink();
    final rawScore = g?['overall_score'];
    final currentScore100 = engineScoreTo100(rawScore);
    final current = Tier.fromOverallNumber(n);
    final nextIdx = n.toInt().clamp(1, 5);
    final nextThreshold = _tierThresholds[nextIdx - 1];
    final nextTierLabel = Tier.fromOverallNumber(nextIdx + 1).label;
    final gap = (nextThreshold - currentScore100).clamp(0, 100);

    // 약점 카테고리 표시 (weak_insight 재활용).
    final categoryScores = <String, int>{
      'POWER': engineScoreTo100(g?['power_score']),
      'OLYMPIC': engineScoreTo100(g?['olympic_score']),
      'GYMNASTICS': engineScoreTo100(g?['gymnastics_score']),
      'CARDIO': engineScoreTo100(g?['cardio_score']),
      'METCON': engineScoreTo100(g?['metcon_score']),
    };
    final weak = analyzeWeakness(categoryScores);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIER ROADMAP', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          if (n >= 6)
            Text(
              '최고 Tier Games 도달. 유지에 집중.',
              style: FacingTokens.body.copyWith(
                color: FacingTokens.tierGames,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TierBadge(tier: current, fontSize: 12),
                const SizedBox(width: FacingTokens.sp2),
                const Icon(Icons.arrow_forward,
                    size: 16, color: FacingTokens.muted),
                const SizedBox(width: FacingTokens.sp2),
                Text(
                  nextTierLabel,
                  style: FacingTokens.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: FacingTokens.accent,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '+$gap',
                  style: FacingTokens.h3.copyWith(
                    fontFeatures: FacingTokens.tabular,
                    color: FacingTokens.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FacingTokens.sp1),
            Text('$currentScore100 / $nextThreshold 까지', style: FacingTokens.caption),
            const SizedBox(height: FacingTokens.sp2),
            ClipRRect(
              borderRadius: BorderRadius.circular(FacingTokens.r1),
              child: Stack(
                children: [
                  Container(height: 6, color: FacingTokens.border),
                  FractionallySizedBox(
                    widthFactor: (currentScore100 / nextThreshold).clamp(0, 1),
                    child: Container(height: 6, color: FacingTokens.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FacingTokens.sp3),
            if (weak != null) ...[
              Text('FOCUS · ${weak.weakestCategory.toUpperCase()}',
                  style: FacingTokens.micro.copyWith(
                    color: FacingTokens.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  )),
              const SizedBox(height: 2),
              Text(weak.comment, style: FacingTokens.caption),
            ],
            const SizedBox(height: FacingTokens.sp2),
            Text(
              '* 가상. Tier 도달 추정. 실제 진도는 주간 세션·약점 집중에 따라 변동.',
              style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// v1.16 Sprint 13: 롤모델 (P9 요구).
/// SharedPreferences로 즐겨찾기 1명 · 철학·대표 WOD 카드 표시.
class _RoleModelCard extends StatefulWidget {
  const _RoleModelCard();

  @override
  State<_RoleModelCard> createState() => _RoleModelCardState();
}

class _RoleModelCardState extends State<_RoleModelCard> {
  Athlete? _selected;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await FavoriteAthleteStore.get();
    if (!mounted) return;
    setState(() {
      _selected = a;
      _loaded = true;
    });
  }

  Future<void> _openPicker() async {
    Haptic.light();
    final picked = await showModalBottomSheet<Athlete>(
      context: context,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(FacingTokens.sp4),
              child: Text('SELECT ROLE MODEL',
                  style: FacingTokens.sectionLabel),
            ),
            ...kAthletes.map(
              (a) => ListTile(
                title: Text(a.name,
                    style: FacingTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                subtitle: Text(a.tier, style: FacingTokens.caption),
                onTap: () => Navigator.of(ctx).pop(a),
              ),
            ),
            const SizedBox(height: FacingTokens.sp3),
          ],
        ),
      ),
    );
    if (picked != null) {
      await FavoriteAthleteStore.set(picked.id);
      if (!mounted) return;
      setState(() => _selected = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final a = _selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('MY ROLE MODEL', style: FacingTokens.sectionLabel),
              const Spacer(),
              TextButton(
                onPressed: _openPicker,
                child: Text(a == null ? 'Select' : 'Change'),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          if (a == null)
            const Text(
              '엘리트 선수 선택 · 철학과 대표 WOD 참고.',
              style: FacingTokens.caption,
            )
          else ...[
            Text(a.name,
                style: FacingTokens.h3.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 2),
            Text(a.tier,
                style: FacingTokens.caption.copyWith(
                  color: FacingTokens.accent,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: FacingTokens.sp2),
            Text('"${a.philosophy}"',
                style: FacingTokens.body
                    .copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: FacingTokens.sp3),
            Container(
              padding: const EdgeInsets.all(FacingTokens.sp3),
              decoration: BoxDecoration(
                color: FacingTokens.surfaceOverlay,
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                border: Border.all(color: FacingTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SIGNATURE WOD',
                      style: FacingTokens.micro.copyWith(
                        color: FacingTokens.muted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      )),
                  const SizedBox(height: 2),
                  Text(a.signatureWod, style: FacingTokens.caption),
                ],
              ),
            ),
            const SizedBox(height: FacingTokens.sp2),
            Text(
              '* 가상. 공개 브랜드·HWPO·CompTrain 기반 큐레이션.',
              style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// v1.16 Sprint 14: 프로필 프로필 옆 착용 칭호 한 줄. 탭 시 해금 칭호 picker.
class _WornTitleLine extends StatefulWidget {
  const _WornTitleLine();

  @override
  State<_WornTitleLine> createState() => _WornTitleLineState();
}

class _WornTitleLineState extends State<_WornTitleLine> {
  String? _code;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await WornTitleStore.get();
    if (!mounted) return;
    setState(() {
      _code = c;
      _loaded = true;
    });
  }

  Future<void> _openPicker() async {
    Haptic.light();
    final state = context.read<AchievementState>();
    final catalog = state.snapshot.catalog;
    final unlocked =
        catalog.where((c) => state.isUnlockedInUi(c.code)).toList();
    unlocked.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(FacingTokens.sp4),
              child: Text('CHOOSE TITLE', style: FacingTokens.sectionLabel),
            ),
            ListTile(
              title: const Text('해제 (No Title)', style: FacingTokens.body),
              onTap: () => Navigator.of(ctx).pop('__none__'),
            ),
            if (unlocked.isEmpty)
              const Padding(
                padding: EdgeInsets.all(FacingTokens.sp4),
                child: Text('해금된 칭호 없음. Engine 측정·세션 누적 후 잠금 해제.',
                    style: FacingTokens.caption),
              )
            else
              ...unlocked.map(
                (c) => ListTile(
                  title: Text(
                    AchievementCard.koreanTitle(c.code),
                    style: FacingTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(c.name, style: FacingTokens.caption),
                  trailing: Text(
                    c.rarity.toUpperCase(),
                    style: FacingTokens.micro.copyWith(
                      color: FacingTokens.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onTap: () => Navigator.of(ctx).pop(c.code),
                ),
              ),
            const SizedBox(height: FacingTokens.sp3),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (picked == '__none__') {
      await WornTitleStore.clear();
      if (!mounted) return;
      setState(() => _code = null);
    } else {
      await WornTitleStore.set(picked);
      if (!mounted) return;
      setState(() => _code = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final state = context.watch<AchievementState>();
    AchievementCatalog? current;
    if (_code != null) {
      for (final c in state.snapshot.catalog) {
        if (c.code == _code) {
          current = c;
          break;
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4,
        FacingTokens.sp3,
        FacingTokens.sp4,
        0,
      ),
      child: InkWell(
        onTap: _openPicker,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                'WORN TITLE',
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Text(
                current == null
                    ? '칭호 선택 · 해금 시 노출'
                    : AchievementCard.koreanTitle(current.code),
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: current == null
                      ? FacingTokens.muted
                      : FacingTokens.accent,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: FacingTokens.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// v1.18 Sprint 19: Inbox 진입 카드 — 미읽음 카운트 카톡식 빨간 dot.
class _InboxEntry extends StatelessWidget {
  const _InboxEntry();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InboxState>();
    final unread = state.unreadCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4,
        FacingTokens.sp3,
        FacingTokens.sp4,
        0,
      ),
      child: InkWell(
        onTap: () {
          Haptic.light();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const InboxScreen(),
          ));
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: unread > 0 ? FacingTokens.accent : FacingTokens.border,
              width: unread > 0 ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp3,
            vertical: FacingTokens.sp3,
          ),
          child: Row(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 20,
                color: unread > 0 ? FacingTokens.accent : FacingTokens.muted,
              ),
              const SizedBox(width: FacingTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INBOX',
                        style: FacingTokens.sectionLabel.copyWith(
                          color: unread > 0
                              ? FacingTokens.accent
                              : FacingTokens.muted,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      unread > 0
                          ? '코치 쪽지 · 박스 공지'
                          : '코치 쪽지 · 박스 공지',
                      style: FacingTokens.caption,
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  // v1.19 페르소나 P1-16 (M3 윤): dot 8 → 12 + textScale 동기.
                  // textScaleFactor 적용으로 폰트 확대 시 dot 도 같이 커짐.
                  padding: EdgeInsets.symmetric(
                    horizontal: 7 *
                        MediaQuery.of(context).textScaler.scale(1.0),
                    vertical: 2,
                  ),
                  constraints: BoxConstraints(
                    minWidth:
                        20 * MediaQuery.of(context).textScaler.scale(1.0),
                    minHeight:
                        20 * MediaQuery.of(context).textScaler.scale(1.0),
                  ),
                  decoration: const BoxDecoration(
                    color: FacingTokens.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      fontFamily: FacingTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: FacingTokens.fg,
                      height: 1.0,
                    ),
                  ),
                ),
              const SizedBox(width: FacingTokens.sp1),
              const Icon(Icons.chevron_right,
                  color: FacingTokens.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
