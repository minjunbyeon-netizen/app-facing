import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import 'gym_repository.dart';
import 'gym_state.dart';
import 'wod_detail_screen.dart';
import 'wod_result_sheet.dart';

/// v2.4 (2026-08-12): box_wod_screen.dart 에서 분리.
/// 주간 보드(week_board.dart)와 WOD 보드가 같은 행 규격을 쓴다 — 같은 역할의
/// 위젯을 두 벌 만들지 않기 위한 분리 (§3 코드 SSOT).

/// locked 수업 카드 — 회원권 만료 시 내용 숨김 + 자물쇠 배너.
/// (미래 게시물 '당일 공개' 잠금은 2026-08-23 폐지 — 잠금 사유는 회원권 만료뿐.)
class LockedWodBanner extends StatelessWidget {
  final String dateLabel;

  /// 종류 라벨 — 서버 `wod_type_label` 그대로 (D124 · 앱 조립 금지).
  final String typeLabel;

  /// 날짜를 함께 보일지. 주간 보드처럼 날짜가 이미 위에 있으면 false.
  final bool showDate;

  const LockedWodBanner({
    super.key,
    required this.dateLabel,
    required this.typeLabel,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    return HkCard(
      padding: const EdgeInsets.symmetric(
        vertical: HyphenTokens.sp3,
        horizontal: HyphenTokens.sp3,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      radius: HyphenTokens.r2,
      child: Row(
        children: [
          Container(width: 3, height: 36, color: HyphenTokens.warning),
          const SizedBox(width: HyphenTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate) ...[
                  Text(
                    dateLabel,
                    style: HyphenTokens.microLabel.copyWith(
                      color: HyphenTokens.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  typeLabel,
                  style: HyphenTokens.body.copyWith(
                    color: HyphenTokens.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '회원권 만료. 갱신 후 열람.',
                    style: HyphenTokens.caption.copyWith(
                      color: HyphenTokens.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, size: 16, color: HyphenTokens.warning),
        ],
      ),
    );
  }
}

/// WOD 한 건 — 접힘 1줄 / 펼침 전체. 오늘 것은 진하게, 지난 것은 muted.
class WodRow extends StatefulWidget {
  final GymWodPost wod;
  final String dateLabel;

  /// 진하게 표시할지 (오늘 WOD). false 면 muted 1줄 요약 톤.
  final bool isToday;

  /// 처음부터 펼쳐둘지. 기본은 isToday 를 따른다.
  final bool? initiallyExpanded;

  /// 헤더에 날짜를 prefix 로 붙일지. 주간 보드처럼 날짜가 이미 있으면 false.
  final bool showDate;

  /// D111 (2026-09-04) — 수업 줄 아래 **본문만** 붙일 때. 이름표 머리·접기 토글·
  /// 아래 테두리가 없고 항상 펼쳐져 있다 — 어느 수업의 글인지는 위의 수업 줄이
  /// 이미 말했다 (같은 말을 두 번 적지 않는다).
  final bool headerless;

  const WodRow({
    super.key,
    required this.wod,
    required this.dateLabel,
    required this.isToday,
    this.initiallyExpanded,
    this.showDate = true,
    this.headerless = false,
  });

  @override
  State<WodRow> createState() => _WodRowState();
}

class _WodRowState extends State<WodRow> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded =
        widget.headerless || (widget.initiallyExpanded ?? widget.isToday);
  }

  void _toggle() {
    if (widget.headerless) return; // 본문만 있는 글은 접히지 않는다
    Haptic.light();
    setState(() => _expanded = !_expanded);
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '·',
      style: HyphenTokens.caption.copyWith(color: HyphenTokens.muted),
    ),
  );

  /// 라벨(좌) + 값(우) 한 줄. 라벨 폭 72 는 'A. METCON'·'VERSIONS' 를 못 담아
  /// 두 줄로 쪼개졌다 — 세로로 흐트러진 라벨은 그 자체로 오류처럼 보인다.
  /// 92 로 넓히고 간격을 명시해 한 줄 안에 들어오게 한다 (v2.2).
  Widget _kv(String label, Widget value) {
    return Padding(
      // v2.3: 줄 사이가 벌어져 카드가 길어 보였다. 6 → 3.
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: HyphenTokens.microLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: HyphenTokens.sp2),
          Expanded(child: value),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Haptic.light();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WodDetailScreen(wod: widget.wod)));
  }

  void _openMsgSheet(BuildContext context) {
    final gs = context.read<GymState>();
    final gymId = gs.membership.gym?.id;
    if (gymId == null) return;
    Haptic.light();
    HkSheet.show(
      context,
      builder: (_) => _MsgCoachSheet(gymId: gymId, wod: widget.wod),
    );
  }

  /// 2026-09-02 — 완료가 막힌 이유를 그 자리에서 말한다 (시트 열고 나서
  /// 거절하지 않는다). 문구 정본 = 서버 completion_gate.MESSAGES.
  void _showBlocked(BuildContext context) {
    Haptic.light();
    HkSnack.show(
      context,
      widget.wod.completionBlockedMessage ?? '지금은 완료할 수 없습니다.',
      mood: MascotMood.sad,
    );
  }

  /// v1.20: Start 버튼 없이 바로 결과 입력.
  /// v3.17: 시트가 저장 성공 시 pop(true) — 받아서 수업 목록 재조회.
  /// 배지(week_board 카드·이 행 둘 다)의 원천이 GymState.wods 라 여기 한 곳이면 된다.
  Future<void> _openResultSheet(BuildContext context) async {
    Haptic.medium();
    final saved = await HkSheet.show<bool>(
      context,
      transparent: true,
      builder: (_) => WodResultSheet(wod: widget.wod),
    );
    if (saved == true && context.mounted) {
      await context.read<GymState>().loadMine();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wod = widget.wod;
    final isMinimal = !widget.isToday;
    final fgColor = isMinimal ? HyphenTokens.muted : HyphenTokens.fg;
    final headerless = widget.headerless;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // v1.22 rev2: 항상 toggle. Detail은 명시 버튼만.
        onTap: headerless ? null : _toggle,
        child: Container(
          decoration: headerless
              ? null
              : const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: HyphenTokens.border, width: 1),
                  ),
                ),
          padding: headerless
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                  vertical: isMinimal ? HyphenTokens.sp2 : HyphenTokens.sp3,
                  horizontal: 2,
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 row — past/future는 일자 prefix + type · time · rounds · chevron
              if (!headerless)
              Row(
                children: [
                  if (isMinimal && widget.showDate) ...[
                    Text(
                      widget.dateLabel,
                      style: HyphenTokens.microLabel.copyWith(
                        color: HyphenTokens.muted,
                      ),
                    ),
                    _dot(),
                  ],
                  // v3.41 (2026-08-29) — 어느 수업의 프로그램인지 먼저 적는다.
                  // 회원이 아는 이름은 AWAKE·SWEAT·BUILD 이고, FOR TIME·AMRAP 은
                  // 그 안에서 오늘 무엇을 하느냐다. 수업 종류에 안 붙은 단발 글은
                  // 종전대로 종류만 적는다.
                  // 이름표는 서버 display_name 그대로 (D109: 세션 꼬리 없음).
                  if ((wod.displayName ?? wod.templateName ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    Text(
                      (wod.displayName ?? wod.templateName)!.trim(),
                      style: HyphenTokens.sectionLabel.copyWith(
                        color: isMinimal
                            ? HyphenTokens.muted
                            : HyphenTokens.fg,
                      ),
                    ),
                    // D109 — 파트가 둘 이상이면 머리에 종류·캡·라운드를 적지
                    // 않는다 (전체를 대표하는 종류가 없다 — 파트마다 제 머리줄이
                    // 있다). 이름표 뒤 점도 같이 뺀다.
                    if (!wod.isMultiPart) _dot(),
                  ],
                  if (!wod.isMultiPart) ...[
                    Text(
                      wod.wodTypeLabel,
                      style: HyphenTokens.sectionLabel.copyWith(
                        color: isMinimal
                            ? HyphenTokens.muted
                            : HyphenTokens.accent,
                      ),
                    ),
                    if (wod.timeCapSec != null) ...[
                      _dot(),
                      Text(wod.timeCapDisplay, style: HyphenTokens.caption),
                    ],
                    if (wod.rounds != null) ...[
                      _dot(),
                      Text('${wod.rounds} rounds', style: HyphenTokens.caption),
                    ],
                  ],
                  const Spacer(),
                  // v3.20: 수업 내용 삭제 버튼 제거 — 게시가 PC 몫이 되면서
                  // 삭제도 PC 로 넘겼다 (README §제거된 기능 대장 16).
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: HyphenTokens.muted,
                  ),
                ],
              ),
              // 본 콘텐츠 — 접힘 1줄 / 펼침 full.
              if (!_expanded) ...[
                const SizedBox(height: 4),
                Text(
                  wod.content,
                  style: HyphenTokens.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_expanded) ...[
                if (!headerless) const SizedBox(height: HyphenTokens.sp2),
                // D109 (2026-09-04 사용자 "60분 운동에서 A세션때 15분 B세션때 20분
                // 이런식으로 보기 쉬우라는 거지. 다른 운동이 아님") — 파트가 둘
                // 이상이면 파트마다 서버 머리줄(title)을 섹션 라벨로, 그 아래 동작
                // 줄(lines)을 세로로, 끝에 메모. 글자는 전부 서버가 그린 것이고
                // 앱은 놓기만 한다 (6-b). 파트 하나면 종전대로 본문 한 덩이 —
                // 구 "여러 라운드면 _kv 로 한 번 더" 블록은 같은 말을 두 번 적던
                // 것이라 지웠다.
                if (wod.isMultiPart) ...[
                  for (var i = 0; i < wod.roundsData.length; i++) ...[
                    if (i > 0) const SizedBox(height: HyphenTokens.sp2),
                    HkSectionLabel(
                      wod.roundsData[i].title.isNotEmpty
                          ? wod.roundsData[i].title
                          : wod.roundsData[i].label,
                    ),
                    if (wod.roundsData[i].lines.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          wod.roundsData[i].lines.join('\n'),
                          style: HyphenTokens.body.copyWith(color: fgColor),
                        ),
                      ),
                  ],
                  if (wod.memo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: HyphenTokens.sp2),
                      child: Text(wod.memo, style: HyphenTokens.caption),
                    ),
                ] else
                  Text(
                    wod.content,
                    style: HyphenTokens.body.copyWith(color: fgColor),
                  ),
                if (wod.scaleGuide != null && wod.scaleGuide!.isNotEmpty)
                  _kv(
                    'SCALE',
                    Text(wod.scaleGuide!, style: HyphenTokens.caption),
                  ),
                if (wod.hasVersions)
                  _kv(
                    'VERSIONS',
                    Text(
                      [
                        'RX',
                        if (wod.scaledVersion != null &&
                            wod.scaledVersion!.isNotEmpty)
                          'SCALED',
                        if (wod.beginnerVersion != null &&
                            wod.beginnerVersion!.isNotEmpty)
                          'BEGINNER',
                      ].join(' · '),
                      style: HyphenTokens.caption.copyWith(
                        color: HyphenTokens.fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // v2.2 액션 위계 — 주 동작만 채움 버튼, 나머지는 글자 버튼.
                // v2.4: 두 줄(채움 + 글자줄)이 100px 를 먹어 그 밑 수업이 화면
                // 밖으로 밀렸다. 한 줄로 합쳐 주 동작은 그대로 채움으로 남긴다.
                // v2.6 (2026-08-12 사용자 지시 "지금도 좀 커서 거북하다"):
                // 세 동작을 전부 HkBadge 한 규격으로 내렸다 — 바로 아래 수업 줄의
                // 예약·대기 배지와 같은 크기다. 주 동작(완료 표시)만 면 채움으로
                // 남겨 위계는 유지하고, 손가락 영역 48 은 HkBadge 가 내부에서
                // 확보하므로 터치 기준은 그대로다 (DESIGN-SSOT §3).
                Row(
                  children: [
                    // v3.28: 코치 가드(isOwner) 제거 — 이 화면은 회원만 본다.
                    // 결함 수정 4 (2026-08-20): 기록한 수업은 카드에서 바로 보이게 —
                    // 배지가 '기록 105kg'(성공색)로 바뀐다. 탭하면 수정 시트(프리필).
                    // 2026-09-02 사용자 보고 "다 입력하고 저장을 눌러야 403" —
                    // 예약이 없거나 수업 시작 전이면 '완료 표시' 대신 이유 배지.
                    // 판정은 서버 completion_blocked (제출 게이트와 같은 함수),
                    // 탭하면 서버 문구 그대로 스낵바 — 시트를 열지 않는다.
                    if (wod.myResult == null && wod.completionBlocked != null)
                      HkBadge(
                        wod.completionBlocked == 'CLASS_NOT_STARTED'
                            ? '수업 시작 전'
                            : '예약 필요',
                        color: HyphenTokens.muted,
                        onTap: () => _showBlocked(context),
                      )
                    else
                      HkBadge(
                        wod.myResult != null
                            ? '기록 ${wod.myResult!.display}'.trim()
                            : '완료 표시',
                        color: wod.myResult != null
                            ? HyphenTokens.success
                            : HyphenTokens.primary,
                        selected: true,
                        onTap: () => _openResultSheet(context),
                      ),
                    const Spacer(),
                    HkBadge(
                      '메시지',
                      color: HyphenTokens.fgSecondary,
                      onTap: () => _openMsgSheet(context),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    // v1.29 한글 기본 — 'Detail' 은 도메인 고정어가 아니다.
                    HkBadge(
                      '자세히',
                      color: HyphenTokens.fgSecondary,
                      onTap: () => _openDetail(context),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 회원 → 코치 메시지 바텀시트 ───────────────────────────────────────────────

class _MsgCoachSheet extends StatefulWidget {
  final int gymId;
  final GymWodPost wod;
  const _MsgCoachSheet({required this.gymId, required this.wod});

  @override
  State<_MsgCoachSheet> createState() => _MsgCoachSheetState();
}

class _MsgCoachSheetState extends State<_MsgCoachSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      final repo = GymRepository(context.read<ApiClient>());
      await repo.memberReport(
        gymId: widget.gymId,
        message: msg,
        wodId: widget.wod.id,
      );
      if (!mounted) return;
      Navigator.pop(context);
      HkSnack.show(context, '코치에게 전송됨.', mood: MascotMood.happy);
    } catch (e) {
      if (!mounted) return;
      HkSnack.error(context, '전송 실패. 다시 시도.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        HyphenTokens.sp4,
        HyphenTokens.sp4,
        HyphenTokens.sp4,
        HyphenTokens.sp4 + bottomInset,
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
          const HkSectionLabel('코치에게 메시지'),
          const SizedBox(height: 4),
          Text(
            '${widget.wod.wodTypeLabel} · ${widget.wod.postDate}',
            style: HyphenTokens.caption,
          ),
          const SizedBox(height: HyphenTokens.sp3),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            style: HyphenTokens.body,
            // v3.24: 테두리·채움은 테마 한 벌 (inputDecorationTheme) — 여기선 문구만.
            decoration: const InputDecoration(
              hintText: '오늘 무릎 통증 있어서 스케일드로 할게요.',
              counterStyle: HyphenTokens.micro,
            ),
          ),
          const SizedBox(height: HyphenTokens.sp3),
          // D117 — 같은 22↔36 스왑. 시트 전체 높이가 바뀌던 것을 자리 그대로 busy 로.
          HkButton.primary('보내기', busy: _sending, onPressed: _send),
        ],
      ),
    );
  }
}
