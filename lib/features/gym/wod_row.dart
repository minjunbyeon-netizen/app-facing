import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/fkit.dart';
import 'gym_repository.dart';
import 'gym_state.dart';
import 'wod_detail_screen.dart';
import 'wod_result_sheet.dart';
import 'wod_type_label.dart';

/// v2.4 (2026-08-12): box_wod_screen.dart 에서 분리.
/// 주간 보드(week_board.dart)와 WOD 보드가 같은 행 규격을 쓴다 — 같은 역할의
/// 위젯을 두 벌 만들지 않기 위한 분리 (§3 코드 SSOT).

/// locked WOD 카드 — 회원권 만료 시 내용 숨김 + 자물쇠 배너.
class LockedWodBanner extends StatelessWidget {
  final String dateLabel;
  final String wodType;

  /// true=회원권 만료, false=아직 공개 전인 미래 WOD.
  final bool isMembershipExpired;

  /// 날짜를 함께 보일지. 주간 보드처럼 날짜가 이미 위에 있으면 false.
  final bool showDate;

  const LockedWodBanner({
    super.key,
    required this.dateLabel,
    required this.wodType,
    required this.isMembershipExpired,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(
          vertical: FacingTokens.sp3, horizontal: FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            color:
                isMembershipExpired ? FacingTokens.warning : FacingTokens.border,
          ),
          const SizedBox(width: FacingTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate) ...[
                  Text(
                    dateLabel,
                    style: FacingTokens.microLabel
                        .copyWith(color: FacingTokens.muted),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  wodTypeLabel(wodType),
                  style: FacingTokens.body.copyWith(
                    color: FacingTokens.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    isMembershipExpired
                        ? '회원권 만료. 갱신 후 열람.'
                        : '당일 공개.',
                    style: FacingTokens.caption.copyWith(
                      color: isMembershipExpired
                          ? FacingTokens.warning
                          : FacingTokens.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isMembershipExpired ? Icons.lock : Icons.lock_outline,
            size: 16,
            color:
                isMembershipExpired ? FacingTokens.warning : FacingTokens.muted,
          ),
        ],
      ),
    );
  }
}

/// WOD 한 건 — 접힘 1줄 / 펼침 전체. 오늘 것은 진하게, 지난 것은 muted.
class WodRow extends StatefulWidget {
  final GymWodPost wod;
  final String dateLabel;
  final bool canDelete;

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
    required this.canDelete,
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
        child: Text('·',
            style: FacingTokens.caption.copyWith(color: FacingTokens.muted)),
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
              style: FacingTokens.microLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: FacingTokens.sp2),
          Expanded(child: value),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Haptic.light();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WodDetailScreen(wod: widget.wod),
    ));
  }

  void _openMsgSheet(BuildContext context) {
    final gs = context.read<GymState>();
    final gymId = gs.membership.gym?.id;
    if (gymId == null) return;
    Haptic.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r3)),
      ),
      builder: (_) => _MsgCoachSheet(
        gymId: gymId,
        wod: widget.wod,
      ),
    );
  }

  /// v1.20: Start 버튼 없이 바로 결과 입력.
  void _openResultSheet(BuildContext context) {
    Haptic.medium();
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WodResultSheet(wod: widget.wod),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wod = widget.wod;
    final isMinimal = !widget.isToday;
    final fgColor = isMinimal ? FacingTokens.muted : FacingTokens.fg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // v1.22 rev2: 항상 toggle. Detail은 명시 버튼만.
        onTap: _toggle,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: FacingTokens.border, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isMinimal ? FacingTokens.sp2 : FacingTokens.sp3,
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
                      style: FacingTokens.microLabel.copyWith(
                        color: FacingTokens.muted,
                      ),
                    ),
                    _dot(),
                  ],
                  Text(
                    wodTypeLabel(wod.wodType),
                    style: FacingTokens.sectionLabel.copyWith(
                      color:
                          isMinimal ? FacingTokens.muted : FacingTokens.accent,
                    ),
                  ),
                  if (wod.timeCapSec != null) ...[
                    _dot(),
                    Text(wod.timeCapDisplay, style: FacingTokens.caption),
                  ],
                  if (wod.rounds != null) ...[
                    _dot(),
                    Text('${wod.rounds} rounds', style: FacingTokens.caption),
                  ],
                  const Spacer(),
                  if (widget.canDelete && _expanded)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: FacingTokens.muted,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () async {
                        final ok = await _confirmDelete(context);
                        if (ok == true && context.mounted) {
                          Haptic.medium();
                          await context.read<GymState>().deleteWod(wod.id);
                        }
                      },
                    ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: FacingTokens.muted,
                  ),
                ],
              ),
              // 본 콘텐츠 — 접힘 1줄 / 펼침 full.
              if (!_expanded) ...[
                const SizedBox(height: 4),
                Text(
                  wod.content,
                  style: FacingTokens.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_expanded) ...[
                const SizedBox(height: FacingTokens.sp2),
                Text(
                  wod.content,
                  style: FacingTokens.body.copyWith(color: fgColor),
                ),
                // v2.3: 라운드가 하나뿐이면 그 내용은 바로 위 본문과 같은 말이다
                // ('21-15-9 Thruster + Pull-up' 이 두 번). 카드 길이만 늘리고
                // 읽을 것은 안 늘어나므로 여러 라운드일 때만 펼친다.
                if (wod.roundsData.length > 1) ...[
                  ...wod.roundsData.asMap().entries.map((e) {
                    final i = e.key;
                    final r = e.value;
                    final label =
                        r.label.isEmpty ? 'R${i + 1}' : r.label.toUpperCase();
                    return _kv(
                      label,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.content, style: FacingTokens.caption),
                          if (r.timeCapSec != null)
                            Text(
                              'cap ${r.timeCapSec! ~/ 60}:${(r.timeCapSec! % 60).toString().padLeft(2, '0')}',
                              style: FacingTokens.micro,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                if (wod.scaleGuide != null && wod.scaleGuide!.isNotEmpty)
                  _kv(
                    'SCALE',
                    Text(wod.scaleGuide!, style: FacingTokens.caption),
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
                      style: FacingTokens.caption.copyWith(
                        color: FacingTokens.fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: FacingTokens.sp2),
                // v2.2 액션 위계 — 주 동작만 채움 버튼, 나머지는 글자 버튼.
                // v2.4: 두 줄(채움 + 글자줄)이 100px 를 먹어 그 밑 수업이 화면
                // 밖으로 밀렸다. 한 줄로 합쳐 주 동작은 그대로 채움으로 남긴다.
                Row(
                  children: [
                    // v2.5: 가로 꽉 채운 채움 버튼이 한 줄을 통째로 먹었다.
                    // 글자 폭만 차지하는 컴팩트 버튼으로 (사용자 지시).
                    FkButton.primary(
                      '완료 표시',
                      icon: Icons.check,
                      expand: false,
                      onPressed: () => _openResultSheet(context),
                    ),
                    const Spacer(),
                    // 회원 전용: 코치에게 메시지 (owner는 숨김)
                    if (!context.watch<GymState>().isOwner)
                      FkButton.tertiary(
                        '메시지',
                        neutral: true,
                        onPressed: () => _openMsgSheet(context),
                      ),
                    // v1.29 한글 기본 — 'Detail' 은 도메인 고정어가 아니다.
                    FkButton.tertiary(
                      '자세히',
                      neutral: true,
                      onPressed: () => _openDetail(context),
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

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        title: const Text('WOD를 삭제할까요?'),
        content:
            const Text('멤버에게 더 이상 보이지 않음.', style: FacingTokens.caption),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코치에게 전송됨.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전송 실패. 다시 시도.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(FacingTokens.sp4, FacingTokens.sp4,
          FacingTokens.sp4, FacingTokens.sp4 + bottomInset),
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
          const Text('코치에게 메시지', style: FacingTokens.sectionLabel),
          const SizedBox(height: 4),
          Text(
            '${wodTypeLabel(widget.wod.wodType)} · ${widget.wod.postDate}',
            style: FacingTokens.caption,
          ),
          const SizedBox(height: FacingTokens.sp3),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            style: FacingTokens.body,
            decoration: InputDecoration(
              hintText: '오늘 무릎 통증 있어서 스케일드로 할게요.',
              hintStyle: FacingTokens.caption,
              filled: true,
              fillColor: FacingTokens.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                borderSide: const BorderSide(color: FacingTokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                borderSide: const BorderSide(color: FacingTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                borderSide:
                    const BorderSide(color: FacingTokens.accent, width: 1.5),
              ),
              counterStyle: FacingTokens.micro,
            ),
          ),
          const SizedBox(height: FacingTokens.sp3),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: FacingTokens.accent,
              foregroundColor: FacingTokens.fg,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
            ),
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: FacingTokens.fg, strokeWidth: 2),
                  )
                : const Text('보내기'),
          ),
        ],
      ),
    );
  }
}
