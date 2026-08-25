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
import 'wod_type_label.dart';

/// v2.4 (2026-08-12): box_wod_screen.dart 에서 분리.
/// 주간 보드(week_board.dart)와 WOD 보드가 같은 행 규격을 쓴다 — 같은 역할의
/// 위젯을 두 벌 만들지 않기 위한 분리 (§3 코드 SSOT).

/// locked 수업 카드 — 회원권 만료 시 내용 숨김 + 자물쇠 배너.
/// (미래 게시물 '당일 공개' 잠금은 2026-08-23 폐지 — 잠금 사유는 회원권 만료뿐.)
class LockedWodBanner extends StatelessWidget {
  final String dateLabel;
  final String wodType;

  /// 날짜를 함께 보일지. 주간 보드처럼 날짜가 이미 위에 있으면 false.
  final bool showDate;

  const LockedWodBanner({
    super.key,
    required this.dateLabel,
    required this.wodType,
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
                  wodTypeLabel(wodType),
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

  const WodRow({
    super.key,
    required this.wod,
    required this.dateLabel,
    required this.isToday,
    this.initiallyExpanded,
    this.showDate = true,
  });

  @override
  State<WodRow> createState() => _WodRowState();
}

class _WodRowState extends State<WodRow> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded ?? widget.isToday;
  }

  void _toggle() {
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // v1.22 rev2: 항상 toggle. Detail은 명시 버튼만.
        onTap: _toggle,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: HyphenTokens.border, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isMinimal ? HyphenTokens.sp2 : HyphenTokens.sp3,
            horizontal: 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 row — past/future는 일자 prefix + type · time · rounds · chevron
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
                  Text(
                    wodTypeLabel(wod.wodType),
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
                const SizedBox(height: HyphenTokens.sp2),
                Text(
                  wod.content,
                  style: HyphenTokens.body.copyWith(color: fgColor),
                ),
                // v2.3: 라운드가 하나뿐이면 그 내용은 바로 위 본문과 같은 말이다
                // ('21-15-9 Thruster + Pull-up' 이 두 번). 카드 길이만 늘리고
                // 읽을 것은 안 늘어나므로 여러 라운드일 때만 펼친다.
                if (wod.roundsData.length > 1) ...[
                  ...wod.roundsData.asMap().entries.map((e) {
                    final i = e.key;
                    final r = e.value;
                    final label = r.label.isEmpty
                        ? 'R${i + 1}'
                        : r.label.toUpperCase();
                    return _kv(
                      label,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.content, style: HyphenTokens.caption),
                          if (r.timeCapSec != null)
                            Text(
                              'cap ${r.timeCapSec! ~/ 60}:${(r.timeCapSec! % 60).toString().padLeft(2, '0')}',
                              style: HyphenTokens.micro,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
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
            '${wodTypeLabel(widget.wod.wodType)} · ${widget.wod.postDate}',
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
          _sending
              ? const HkLoading()
              : HkButton.primary('보내기', onPressed: _send),
        ],
      ),
    );
  }
}
