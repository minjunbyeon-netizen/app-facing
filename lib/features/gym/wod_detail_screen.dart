// v1.16 Sprint 16: 박스 WOD 상세 — 버전 선택 + 리더보드 + 댓글.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/mascot.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/coach_feedback.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../wod_session/wod_session_screen.dart';
import 'gym_repository.dart';
import 'gym_state.dart';
import 'wod_type_label.dart';
import '../../core/time_format.dart';

enum _ScaleLevel { rx, scaled, beginner }

class WodDetailScreen extends StatefulWidget {
  final GymWodPost wod;
  const WodDetailScreen({super.key, required this.wod});

  // ── 레이아웃 안정성 앵커 (v3.34 · 2026-08-27) ──────────────────────────────
  // 네 구역이 각자 다른 시점에 도착해도 y 가 움직이면 안 되는 요소들.
  // 회귀 게이트가 이 키로 잰다 (test/golden/stability_wod_test.dart).
  // 이름을 바꾸면 그 테스트도 같이 바꾼다 (글로벌 §0-B 이름 일원화).
  static const Key kFeedbackLabel = Key('wod-detail-feedback-label');
  static const Key kLeaderboardLabel = Key('wod-detail-leaderboard-label');
  static const Key kHistoryLabel = Key('wod-detail-history-label');
  static const Key kCommentsLabel = Key('wod-detail-comments-label');
  static const Key kCommentInput = Key('wod-detail-comment-input');

  // ── 구역별 예약 높이 (공간 예약 — DESIGN-SSOT §레이아웃 안정성) ─────────────
  // 값 = 그 구역 **한 줄**의 실측 높이. 로딩 스켈레톤·'없음' 문구·내용이 이
  // 자리를 함께 쓴다. 한 줄로 잡은 이유: 넷을 두 줄씩 잡으면 다 비었을 때
  // 화면 절반이 빈 칸이 된다 (스켈레톤은 내용보다 커지면 안 된다).
  // 두 줄 이상 도착하는 구역은 그만큼 한 번 늘어난다 — 순차 도착 밀림(넷)이
  // 한 번으로 줄어드는 것이 이 예약의 목적이다.
  static const double slotFeedbackH = 75;
  static const double slotLeaderboardH = 57;
  static const double slotHistoryH = 45;
  static const double slotCommentsH = 69;

  @override
  State<WodDetailScreen> createState() => _WodDetailScreenState();
}

class _WodDetailScreenState extends State<WodDetailScreen> {
  _ScaleLevel _level = _ScaleLevel.rx;
  Future<List<GymWodResult>>? _resultsFuture;
  Future<List<GymWodComment>>? _commentsFuture;
  Future<List<CoachFeedback>>? _feedbackFuture;
  // Q3 (v3.4) — 같은 수업(시그니처 그룹)의 내 과거 기록.
  Future<({String kind, List<WodMyHistoryItem> items})>? _historyFuture;
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) return;
    final repo = context.read<GymRepository>();
    setState(() {
      _resultsFuture = repo.listWodResults(gym.id, widget.wod.id);
      _commentsFuture = repo.listWodComments(gym.id, widget.wod.id);
      _feedbackFuture = repo.listCoachFeedback(gym.id, widget.wod.id);
      _historyFuture = repo.wodMyHistory(gym.id, widget.wod.id);
    });
  }

  // QA A-10: 사용 안 되는 _leaveCoachNote 제거.
  // 코치는 Coach Dashboard 멤버 sheet에서 노트 작성. 리더보드 행에는 진입점 없음.

  Future<void> _sendRequest() async {
    Haptic.medium();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    // 결함 수정 5 — 빈 전송 안내. 스낵바는 모달 시트 '뒤' Scaffold 에 그려져
    // 안 보인다 (실기 확인) → 시트 안 인라인 에러로 표시.
    String? sheetError;
    // QA B-GYM-2: 모달 닫힌 후 controller dispose 보장.
    try {
      await HkSheet.show<void>(
        context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: HyphenTokens.sp4,
              right: HyphenTokens.sp4,
              top: HyphenTokens.sp4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + HyphenTokens.sp4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HkSectionLabel('코치에게 요청'),
                const SizedBox(height: HyphenTokens.sp1),
                const Text(
                  '이 수업 내용 관련 조정·대체 요청. 예: "어깨 수술 이력 있어 Thruster 대체 부탁".',
                  style: HyphenTokens.caption,
                ),
                const SizedBox(height: HyphenTokens.sp3),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: '제목'),
                  maxLength: 120,
                ),
                TextField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    hintText: '상황·원하는 대체 동작·비고',
                  ),
                  maxLines: 5,
                  maxLength: 2000,
                ),
                if (sheetError != null) ...[
                  Text(
                    sheetError!,
                    style: HyphenTokens.caption.copyWith(
                      color: HyphenTokens.warning,
                    ),
                  ),
                  const SizedBox(height: HyphenTokens.sp1),
                ],
                const SizedBox(height: HyphenTokens.sp3),
                HkButton.primary(
                  '보내기',
                  onPressed: () async {
                    final body = bodyCtrl.text.trim();
                    if (body.isEmpty) {
                      setSheet(() => sheetError = '내용을 입력해 주세요.');
                      return;
                    }
                    final gs = context.read<GymState>();
                    final gym = gs.membership.gym;
                    if (gym == null) return;
                    try {
                      await context.read<GymRepository>().sendMemberRequest(
                        gymId: gym.id,
                        subject: subjectCtrl.text.trim(),
                        body: body,
                        wodPostId: widget.wod.id,
                      );
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      // QA A-11: 부모 context는 ctx.mounted로는 보호 불가. ScaffoldMessenger를 ctx 기준으로 사용.
                      HkSnack.show(
                        ctx,
                        '건의 전송. 코치 응답 대기.',
                        mood: MascotMood.happy,
                      );
                    } on AppException catch (e) {
                      if (!ctx.mounted) return;
                      HkSnack.error(ctx, '실패: ${e.messageKo}');
                    } catch (e) {
                      // /go Tier 3: generic catch.
                      debugPrint('[WodDetail._sendRequest] $e');
                      if (!ctx.mounted) return;
                      HkSnack.error(ctx, '전송 실패. 다시 시도.');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      subjectCtrl.dispose();
      bodyCtrl.dispose();
    }
  }

  Future<void> _sendComment() async {
    final body = _commentCtrl.text.trim();
    if (body.isEmpty) {
      // 결함 수정 5 — 빈 전송 무반응 → 안내.
      HkSnack.error(context, '댓글 내용을 입력해 주세요.');
      return;
    }
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) return;
    setState(() => _sendingComment = true);
    Haptic.medium();
    try {
      await context.read<GymRepository>().postWodComment(
        gymId: gym.id,
        wodId: widget.wod.id,
        body: body,
      );
      _commentCtrl.clear();
      _reload();
    } on AppException catch (e) {
      if (!mounted) return;
      HkSnack.error(context, '댓글 실패: ${e.messageKo}');
    } catch (e) {
      // /go Tier 3: generic catch.
      debugPrint('[WodDetail._sendComment] $e');
      if (!mounted) return;
      HkSnack.error(context, '댓글 실패. 다시 시도.');
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  String _displayContent() {
    switch (_level) {
      case _ScaleLevel.scaled:
        final s = widget.wod.scaledVersion;
        return (s == null || s.isEmpty) ? widget.wod.content : s;
      case _ScaleLevel.beginner:
        final b = widget.wod.beginnerVersion;
        return (b == null || b.isEmpty) ? widget.wod.content : b;
      case _ScaleLevel.rx:
        return widget.wod.content;
    }
  }

  void _startSession() {
    Haptic.medium();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WodSessionScreen(wod: widget.wod)),
    );
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      HkSnack.error(context, '영상 열기 실패.');
    }
  }

  /// rounds_data 의 movements 를 라운드별 동작 행으로 렌더.
  /// movements 가 하나도 없으면 빈 리스트 반환(구버전 WOD 영향 0).
  List<Widget> _buildMovementRounds(GymWodPost wod) {
    final rounds = wod.roundsData.where((r) => r.hasMovements).toList();
    if (rounds.isEmpty) return const [];
    final widgets = <Widget>[const SizedBox(height: HyphenTokens.sp3)];
    for (final r in rounds) {
      widgets.add(
        HkCard(
          padding: const EdgeInsets.all(HyphenTokens.sp3),
          margin: const EdgeInsets.only(bottom: HyphenTokens.sp2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
                  child: HkSectionLabel(r.label),
                ),
              ...r.movements.map(
                (m) => _MovementRow(
                  movement: m,
                  onVideo: m.hasVideo ? () => _openVideo(m.videoUrl) : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final wod = widget.wod;
    final hasScaled =
        wod.scaledVersion != null && wod.scaledVersion!.isNotEmpty;
    final hasBeginner =
        wod.beginnerVersion != null && wod.beginnerVersion!.isNotEmpty;

    return Scaffold(
      appBar: HkAppBar(
        title: wodTypeLabel(wod.wodType),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HyphenTokens.sp4),
          children: [
            // 버전 선택 토글
            if (hasScaled || hasBeginner)
              SegmentedButton<_ScaleLevel>(
                segments: [
                  const ButtonSegment(value: _ScaleLevel.rx, label: Text('RX')),
                  if (hasScaled)
                    const ButtonSegment(
                      value: _ScaleLevel.scaled,
                      label: Text('Scaled'),
                    ),
                  if (hasBeginner)
                    const ButtonSegment(
                      value: _ScaleLevel.beginner,
                      label: Text('Beginner'),
                    ),
                ],
                selected: {_level},
                onSelectionChanged: (s) {
                  Haptic.selection();
                  setState(() => _level = s.first);
                },
              ),
            if (hasScaled || hasBeginner)
              const SizedBox(height: HyphenTokens.sp3),
            // 본문
            HkCard(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _levelLabel(),
                    style: HyphenTokens.sectionLabel.copyWith(
                      color: HyphenTokens.accent,
                    ),
                  ),
                  const SizedBox(height: HyphenTokens.sp2),
                  Text(_displayContent(), style: HyphenTokens.body),
                ],
              ),
            ),
            // #3 (v1.25): 동작 레벨 구조화 — 라운드별 동작 행(sets·reps·load·rest·영상).
            // rounds_data 에 movements 가 있을 때만 노출. RX 본문 아래 보강 표시.
            ..._buildMovementRounds(wod),
            const SizedBox(height: HyphenTokens.sp3),
            // 결함 수정 1 (2026-08-20 실기 발견): Strength(무게 측정일)는 타이머가
            // 무의미하고, 세션 화면이 For Time 스톱워치로 돌아 시간 기록을
            // 저장해 버린다 — 진입 자체를 숨긴다 (기록은 완료 표시 시트가 정본).
            if (wod.wodType.toLowerCase() != 'strength') ...[
              HkButton.primary(
                '타이머 시작',
                icon: Icons.play_arrow,
                onPressed: _startSession,
              ),
              const SizedBox(height: HyphenTokens.sp3),
            ],
            // v1.16 Sprint 17: 멤버 건의 버튼.
            Builder(
              builder: (ctx) {
                // QA (2026-06-11): 물음표(help) 아이콘 → 전송 아이콘 (의미 일치).
                return HkButton.secondary(
                  '코치에게 요청',
                  icon: Icons.send_outlined,
                  onPressed: _sendRequest,
                );
              },
            ),
            const SizedBox(height: HyphenTokens.sp5),

            // v1.16 Sprint 17: 코치 피드백.
            //
            // 네 구역(피드백·리더보드·내 이전 기록·댓글)은 _reload() 에서 동시에
            // 나가지만 도착은 제각각이다. 전에는 도착할 때마다 그 아래가 밀렸고,
            // 피드백·이전 기록은 로딩 중에도 '없음' 을 먼저 보여 준 뒤 내용이
            // 튀어나왔다 — 아직 모르는 것과 없는 것을 같은 화면으로 그린 탓이다.
            // 이제 셋(로딩·없음·내용)이 HkSectionSlot 한 자리를 쓴다
            // (DESIGN-SSOT §레이아웃 안정성). 부르는 것·시점은 그대로다.
            const HkSectionLabel(
              '코치 피드백',
              key: WodDetailScreen.kFeedbackLabel,
            ),
            const SizedBox(height: HyphenTokens.sp2),
            FutureBuilder<List<CoachFeedback>>(
              future: _feedbackFuture,
              builder: (ctx, snap) {
                final list = snap.data ?? const <CoachFeedback>[];
                return HkSectionSlot(
                  minHeight: WodDetailScreen.slotFeedbackH,
                  loading: snap.connectionState != ConnectionState.done,
                  empty: snap.hasError ? '피드백 불러오기 실패.' : '아직 피드백 없음.',
                  child: list.isEmpty
                      ? null
                      : Column(
                          children: list
                              .map((f) => _FeedbackCard(fb: f))
                              .toList(),
                        ),
                );
              },
            ),
            const SizedBox(height: HyphenTokens.sp5),

            // Leaderboard
            const HkSectionLabel(
              '리더보드',
              key: WodDetailScreen.kLeaderboardLabel,
            ),
            const SizedBox(height: HyphenTokens.sp2),
            FutureBuilder<List<GymWodResult>>(
              future: _resultsFuture,
              builder: (ctx, snap) {
                final list = snap.data ?? const <GymWodResult>[];
                // 구 HkEmptyState(가운데 정렬 2줄, sp5 패딩)는 다른 세 구역의
                // '없음' 한 줄보다 훨씬 커서 이 구역만 자리가 달랐다 — 네 구역
                // 모두 같은 한 줄 문구로 맞춘다 (문구 뜻은 그대로).
                return HkSectionSlot(
                  minHeight: WodDetailScreen.slotLeaderboardH,
                  loading: snap.connectionState != ConnectionState.done,
                  empty: snap.hasError
                      ? '기록 불러오기 실패.'
                      : '아직 기록 없음. 타이머 완료 시 첫 기록 자동 제출.',
                  child: list.isEmpty
                      ? null
                      : Column(
                          children: list
                              .map((r) => _ResultRow(result: r))
                              .toList(),
                        ),
                );
              },
            ),
            const SizedBox(height: HyphenTokens.sp5),

            // Q3 (v3.4 승인): 같은 수업(벤치마크·리프트)의 내 과거 기록 —
            // "전과 비교해 발전했는가"를 저장 순간 스낵바 밖에서도 보여준다.
            const HkSectionLabel(
              '내 이전 기록',
              key: WodDetailScreen.kHistoryLabel,
            ),
            const SizedBox(height: HyphenTokens.sp2),
            FutureBuilder<({String kind, List<WodMyHistoryItem> items})>(
              future: _historyFuture,
              builder: (ctx, snap) {
                final items = snap.data?.items ?? const <WodMyHistoryItem>[];
                return HkSectionSlot(
                  minHeight: WodDetailScreen.slotHistoryH,
                  loading: snap.connectionState != ConnectionState.done,
                  empty: snap.hasError
                      ? '기록 불러오기 실패.'
                      : '같은 수업의 기록이 아직 없습니다.',
                  child: items.isEmpty
                      ? null
                      : Column(
                          children: [
                            for (final it in items) _HistoryRow(item: it),
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: HyphenTokens.sp5),

            // Comments
            const HkSectionLabel('댓글', key: WodDetailScreen.kCommentsLabel),
            const SizedBox(height: HyphenTokens.sp2),
            FutureBuilder<List<GymWodComment>>(
              future: _commentsFuture,
              builder: (ctx, snap) {
                final list = snap.data ?? const <GymWodComment>[];
                return HkSectionSlot(
                  minHeight: WodDetailScreen.slotCommentsH,
                  loading: snap.connectionState != ConnectionState.done,
                  empty: snap.hasError ? '댓글 불러오기 실패.' : '첫 댓글 작성.',
                  child: list.isEmpty
                      ? null
                      : Column(
                          children: list
                              .map((c) => _CommentRow(comment: c))
                              .toList(),
                        ),
                );
              },
            ),
            const SizedBox(height: HyphenTokens.sp3),
            Row(
              key: WodDetailScreen.kCommentInput,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      hintText: '댓글 입력.',
                      isDense: true,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 500,
                  ),
                ),
                const SizedBox(width: HyphenTokens.sp2),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: HyphenTokens.accent,
                  onPressed: _sendingComment ? null : _sendComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _levelLabel() {
    switch (_level) {
      case _ScaleLevel.rx:
        return 'RX';
      case _ScaleLevel.scaled:
        return 'SCALED';
      case _ScaleLevel.beginner:
        return 'BEGINNER';
    }
  }
}

class _ResultRow extends StatelessWidget {
  final GymWodResult result;
  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final mine = result.isMine;
    final isTop = result.rank <= 3;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      decoration: BoxDecoration(
        color: mine
            ? HyphenTokens.accent.withValues(alpha: 0.12)
            : HyphenTokens.surface,
        border: Border.all(
          color: mine ? HyphenTokens.accent : HyphenTokens.border,
          width: mine ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${result.rank}${_suffix(result.rank)}',
              style: HyphenTokens.h3.copyWith(
                color: isTop ? HyphenTokens.accent : HyphenTokens.fg,
                fontWeight: FontWeight.w800,
                fontFeatures: HyphenTokens.tabular,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mine ? 'You' : 'user:${result.deviceHashPrefix}',
                  style: HyphenTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (result.scaleLevel != 'rx')
                  Text(
                    result.scaleLevel.toUpperCase(),
                    style: HyphenTokens.microLabel,
                  ),
              ],
            ),
          ),
          Text(
            result.display,
            style: HyphenTokens.h3.copyWith(
              fontFeatures: HyphenTokens.tabular,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _suffix(int rank) {
    if (rank == 1) return 'st';
    if (rank == 2) return 'nd';
    if (rank == 3) return 'rd';
    return 'th';
  }
}

class _FeedbackCard extends StatelessWidget {
  final CoachFeedback fb;
  const _FeedbackCard({required this.fb});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      decoration: BoxDecoration(
        color: HyphenTokens.surfaceOverlay,
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
        border: const Border(
          left: BorderSide(color: HyphenTokens.accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fb.isMine ? 'COACH → YOU' : 'COACH → ${fb.memberHashPrefix}',
                style: HyphenTokens.microLabel.copyWith(
                  color: HyphenTokens.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                mdHm(fb.updatedAt.toLocal()),
                style: HyphenTokens.micro.copyWith(color: HyphenTokens.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(fb.body, style: HyphenTokens.body),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final GymWodComment comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
      padding: const EdgeInsets.all(HyphenTokens.sp2),
      decoration: BoxDecoration(
        color: comment.isMine
            ? HyphenTokens.accent.withValues(alpha: 0.10)
            : HyphenTokens.surface,
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
        border: Border.all(color: HyphenTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.isMine ? 'You' : 'user:${comment.authorPrefix}',
                style: HyphenTokens.microLabel.copyWith(
                  color: comment.isMine
                      ? HyphenTokens.accent
                      : HyphenTokens.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                mdHm(comment.createdAt.toLocal()),
                style: HyphenTokens.micro.copyWith(color: HyphenTokens.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(comment.body, style: HyphenTokens.body),
        ],
      ),
    );
  }
}

/// #3 (v1.25): WOD 동작 1줄 — 동작명·sets×reps·load·rest + 영상 링크.
/// 매그넘 레퍼런스의 동작 행을 hyphen 톤(영문 라벨·무채색 ▶)으로 재해석.
class _MovementRow extends StatelessWidget {
  final WodMovementItem movement;
  final VoidCallback? onVideo;
  const _MovementRow({required this.movement, this.onVideo});

  @override
  Widget build(BuildContext context) {
    final detail = movement.displayLine
        .replaceFirst(movement.name, '')
        .replaceFirst(' · ', '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.name, style: HyphenTokens.body),
                if (detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(detail, style: HyphenTokens.micro),
                  ),
              ],
            ),
          ),
          if (onVideo != null)
            InkWell(
              onTap: onVideo,
              child: Padding(
                padding: const EdgeInsets.only(left: HyphenTokens.sp2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 18,
                      color: HyphenTokens.muted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '데모',
                      style: HyphenTokens.micro.copyWith(
                        color: HyphenTokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Q3 (v3.4) — 내 이전 기록 1줄: 날짜 · 기록 라벨 · PR 배지 (표시 전용).
class _HistoryRow extends StatelessWidget {
  final WodMyHistoryItem item;
  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp1),
      padding: const EdgeInsets.symmetric(
        horizontal: HyphenTokens.sp3,
        vertical: HyphenTokens.sp2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: HyphenTokens.border),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Row(
        children: [
          Text(item.date, style: HyphenTokens.caption),
          const Spacer(),
          Text(
            item.label,
            style: HyphenTokens.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (item.isPr) ...[
            const SizedBox(width: HyphenTokens.sp2),
            const HkBadge('PR', color: HyphenTokens.primary),
          ],
        ],
      ),
    );
  }
}
