// v1.22: Inbox → NOTICE 단일 피드 (날짜순). ALL/NOTES/ASSIGNMENTS/OUTBOX 4탭 폐지.
//
// 톤: 흑백·전사·Obsession.
// Coach Dossier 카드: 좌 4px accent stripe + 이니셜 모노그램.
// 미읽음: stripe accent + 굵은 폰트.
// 읽음: stripe muted + 보통 폰트.

import 'dart:async';
import '../../widgets/hkit.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/futures.dart';
import '../../core/haptic.dart';
import '../../core/sse_client.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../models/chat_message.dart';
import '../../models/coach_note.dart';
import '../../widgets/avatar.dart';
import '../announcements/announcements_state.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import 'inbox_repository.dart';
import 'inbox_state.dart';
import 'note_detail_screen.dart';
import '../../core/app_clock.dart';
import 'new_note_screen.dart';

// v3.2 (2026-08-20 사용자 지시 "깨끗하게 다 지워"): 구 Notice 탭의 InboxScreen
// (재활 가이드 전담)은 셸에서 빠진 뒤 도달 불가 — rehab 일체와 함께 삭제.
// 대장 = README.md §제거된 기능 대장.

/// 외부에서도 재사용 (홈 화면 미읽음 카드 노출 등).
class CoachDossierTile extends StatelessWidget {
  final CoachNote note;
  const CoachDossierTile({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final isUnread = note.my?.isUnread ?? false;
    final stripeColor = isUnread ? HyphenTokens.accent : HyphenTokens.muted;
    final dueLabel = _dueLabel(note.dueDate);
    final senderLabel = note.displayLabel();

    return InkWell(
      onTap: () async {
        Haptic.light();
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: note.id)),
        );
        if (context.mounted) {
          await context.read<InboxState>().refresh();
        }
      },
      child: HkCard(
        padding: EdgeInsets.zero,
        radius: HyphenTokens.r2,
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: stripeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(HyphenTokens.sp3),
                  child: _buildBody(
                    stripeColor,
                    dueLabel,
                    senderLabel,
                    isUnread,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    Color stripeColor,
    _DueBadge? dueLabel,
    String senderLabel,
    bool isUnread,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(
          hash: note.senderShort,
          displayName: note.senderName,
          colorHex: note.senderColor,
        ),
        const SizedBox(width: HyphenTokens.sp3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    note.isAuto
                        ? '자동'
                        : (note.kind == 'assignment' ? '숙제' : '쪽지'),
                    style: HyphenTokens.microLabel.copyWith(
                      color: note.isAuto ? HyphenTokens.success : stripeColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: HyphenTokens.sp2),
                  Flexible(
                    child: Text(
                      '코치 · ${senderLabel.toUpperCase()}',
                      style: HyphenTokens.microLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text(_agoLabel(note.createdAt), style: HyphenTokens.micro),
                ],
              ),
              if (note.title.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp1),
                Text(
                  note.title,
                  style: HyphenTokens.body.copyWith(
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                    color: HyphenTokens.fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  note.body,
                  style: HyphenTokens.caption.copyWith(
                    color: isUnread ? HyphenTokens.fg : HyphenTokens.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.kind == 'assignment') ...[
                const SizedBox(height: HyphenTokens.sp2),
                Row(
                  children: [
                    if (dueLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HyphenTokens.sp2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: dueLabel.color),
                          borderRadius: BorderRadius.circular(HyphenTokens.r1),
                        ),
                        child: Text(
                          dueLabel.text,
                          style: HyphenTokens.micro.copyWith(
                            color: dueLabel.color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    const SizedBox(width: HyphenTokens.sp2),
                    if (note.my != null)
                      Text(
                        note.my!.status.toUpperCase(),
                        style: HyphenTokens.micro.copyWith(
                          color: _statusColor(note.my!.status),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return HyphenTokens.success;
      case 'accepted':
        return HyphenTokens.fg;
      case 'declined':
        return HyphenTokens.muted;
      case 'read':
        return HyphenTokens.muted;
      case 'sent':
      default:
        return HyphenTokens.accent;
    }
  }

  static _DueBadge? _dueLabel(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return null;
    final due = DateTime.tryParse('${dueDate}T00:00:00');
    if (due == null) return null;
    final now = appClock.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return _DueBadge('OVERDUE', color: HyphenTokens.overdue);
    if (diff == 0) return _DueBadge('TODAY', color: HyphenTokens.accent);
    if (diff <= 3) return _DueBadge('D-$diff', color: HyphenTokens.accent);
    return _DueBadge('D-$diff', color: HyphenTokens.muted);
  }

  static String _agoLabel(DateTime created) {
    final now = appClock.now().toUtc();
    final d = now.difference(created.isUtc ? created : created.toUtc());
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    final l = created.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    if (l.year != appClock.now().year) {
      return '${l.year}-$mm-$dd';
    }
    return '$mm/$dd';
  }
}

class _DueBadge {
  final String text;
  final Color color;
  const _DueBadge(this.text, {required this.color});
}

// ─── 회원 ↔ 코치 양방향 대화 (v1.25) ──────────────────────────────────────────

/// 말풍선 — mine(보낸 것)=우측 accent, 받은 것=좌측 surface.
class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final mine = msg.mine;
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 4),
              child: Text(
                msg.isAuto ? '자동' : (msg.senderName ?? '코치').toUpperCase(),
                style: HyphenTokens.microLabel.copyWith(
                  color: msg.isAuto ? HyphenTokens.success : HyphenTokens.muted,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: HyphenTokens.sp3,
                vertical: HyphenTokens.sp2 + 2,
              ),
              decoration: BoxDecoration(
                color: mine ? HyphenTokens.accent : HyphenTokens.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(HyphenTokens.r3),
                  topRight: const Radius.circular(HyphenTokens.r3),
                  bottomLeft: Radius.circular(
                    mine ? HyphenTokens.r3 : HyphenTokens.r1,
                  ),
                  bottomRight: Radius.circular(
                    mine ? HyphenTokens.r1 : HyphenTokens.r3,
                  ),
                ),
                border: mine ? null : Border.all(color: HyphenTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.title.isNotEmpty) ...[
                    Text(
                      msg.title,
                      style: HyphenTokens.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: HyphenTokens.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    msg.body,
                    style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(_timeLabel(msg.createdAt), style: HyphenTokens.micro),
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime t) {
    final now = appClock.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$mo/$d';
  }
}

/// 상단 핀 공지 — 최신 1건 요약. 새 소식 제일 위 노출.
/// 목록이 비면 같은 카드 골격에 '등록된 공지 없음.' — 자리(높이)는 그대로다.
class _PinnedAnnouncement extends StatelessWidget {
  final List<GymAnnouncement> announcements;
  const _PinnedAnnouncement({required this.announcements});

  @override
  Widget build(BuildContext context) {
    final latest = announcements.isEmpty ? null : announcements.first;
    final more = announcements.length - 1;
    return HkCard(
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      margin: const EdgeInsets.fromLTRB(
        HyphenTokens.sp4,
        HyphenTokens.sp3,
        HyphenTokens.sp4,
        0,
      ),
      width: double.infinity,
      radius: HyphenTokens.r2,
      borderColor: latest?.isUrgent == true
          ? HyphenTokens.accent
          : HyphenTokens.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '공지',
                style: HyphenTokens.microLabel.copyWith(
                  color: latest?.isUrgent == true
                      ? HyphenTokens.accent
                      : HyphenTokens.muted,
                ),
              ),
              if (more > 0) ...[
                const Spacer(),
                Text('+$more', style: HyphenTokens.micro),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (latest == null)
            const Text('등록된 공지 없음.', style: HyphenTokens.caption)
          else ...[
            if (latest.title.isNotEmpty)
              // v3.42 — 긴 제목은 흐른다 (HkMarquee). 본문 2줄은 그대로.
              HkMarquee(
                latest.title,
                style: HyphenTokens.body.copyWith(fontWeight: FontWeight.w700),
              ),
            if (latest.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  latest.body,
                  style: HyphenTokens.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// 하단 입력바 — 쪽지 발신. 전송 버튼은 입력창 suffixIcon 으로.
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final String hint;
  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    this.hint = '메시지…',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ChatThreadScreen.kInputBar,
      padding: const EdgeInsets.fromLTRB(
        HyphenTokens.sp3,
        HyphenTokens.sp2,
        HyphenTokens.sp3,
        HyphenTokens.sp2,
      ),
      decoration: const BoxDecoration(
        color: HyphenTokens.bg,
        border: Border(top: BorderSide(color: HyphenTokens.border, width: 1)),
      ),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 4,
        maxLength: 500,
        style: HyphenTokens.body,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => onSend(),
        decoration: InputDecoration(
          hintText: hint,
          // v3.24: 테두리·채움·안내 글꼴은 테마 한 벌 — 채팅칸은 촘촘한 패딩만 고유.
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(
            HyphenTokens.sp3,
            HyphenTokens.sp2 + 2,
            HyphenTokens.sp1,
            HyphenTokens.sp2 + 2,
          ),
          // D118 — 전송 중에도 **버튼 자리 그대로** 안에서 스피너만 돈다
          // (HkButton(busy:) 와 같은 결). 종전엔 버튼(48×48)을 `HkLoading()` 으로
          // 통째 갈아 끼웠는데, 그 스피너는 Center 라 가로폭을 전부 먹어 글자
          // 칸이 0 이 됐다 — 네 줄로 접히며 입력바가 65 → 129 로 부풀고 위
          // 대화 목록이 64px 깎였다.
          suffixIcon: IconButton(
            key: ChatThreadScreen.kSendSlot,
            icon: sending
                ? const HkLoading.icon(color: HyphenTokens.accent)
                : const Icon(Icons.arrow_upward, color: HyphenTokens.accent),
            onPressed: sending ? null : onSend,
          ),
        ),
      ),
    );
  }
}

String _shortTime(DateTime t) {
  final now = appClock.now();
  if (t.year == now.year && t.month == now.month && t.day == now.day) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  final mo = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '$mo/$d';
}

/// v1.25: 새 쪽지 SSE(note.new) 구독 → 디바운스 후 onReload. 대화 자동 갱신.
StreamSubscription<SseEvent> _listenNoteNew(
  BuildContext context,
  void Function() onReload,
) {
  Timer? debounce;
  return context.read<SseClient>().events.listen((ev) {
    if (ev.type != 'note.new') return;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), onReload);
  });
}

// ─── 메시징 피드 ─────────────────────────────────────────────────────────

/// v1.26 (2026-06-11): 쪽지·공지 진입을 종(벨)으로 일원화 — 벨 탭 시 이 화면.
/// (구 v1.24 Attend 캘린더 밑 임베드는 ClassesSection 으로 대체됨.)
/// v3.4 (2026-08-21): 코치 셸 쪽지 탭으로도 임베드 — 탭 문맥에선 제목만 '쪽지'.
class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key, this.title = '쪽지함', this.embedded = false});

  final String title;

  /// 코치 셸에 얹힐 때는 자기 AppBar 를 그리지 않는다 (v3.23 — 상단바는 셸 하나).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 쪽지·숙제·공지가 함께 쌓이는 화면이라 '공지' 는 내용과 불일치 (2026-08-06).
      appBar: embedded ? null : HkAppBar(title: title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp4),
          children: const [MessagingFeed()],
        ),
      ),
    );
  }
}

/// 공지 + 코치/회원 대화목록 + 작성 진입을 한 덩어리로 묶은 임베드 위젯.
/// Scaffold 없이 스크롤 부모(ListView) 안에 들어가도록 자체 스크롤을 쓰지 않는다.
///
/// D72 (2026-08-29 사용자 지시) — **회원은 '코치' / '활동' 두 칸**이다.
/// > "쪽지는 쪽지고(코치와 대화), 업적알림 가입 예약완료 등등 이런건 활동로그
/// >  이런걸 만들어서 거기에 그냥 쌓이게 하면 안돼?"
/// 코치 칸 = 사람이 쓴 대화. 활동 칸 = 자동 통보(예약·결제·회원권·업적·가입).
/// 나누는 판정은 **서버 한 곳**(coach_note._is_conversation)이라 겹치거나 새지 않는다.
/// 코치 셸에는 칸을 두지 않는다 — 코치가 보는 것은 회원과의 대화뿐이다.
class MessagingFeed extends StatefulWidget {
  // ── 레이아웃 안정성 앵커·자리 (v3.33 · 2026-08-27) ─────────────────────────
  // 회귀 게이트 = test/golden/stability_coach_inbox_test.dart.

  /// 공지 배너가 들어올 **예약된 자리** (공간 예약 / space reservation).
  static const Key kAnnouncementSlot = Key('inbox-announcement-slot');

  /// 밀리면 안 되는 것 — 그 바로 아래 대화 목록.
  static const Key kThreadList = Key('inbox-thread-list');

  /// 공지 카드의 **가장 긴 경우** 높이 — 위 여백 + 라벨 줄 + 제목 1줄 + 본문 2줄
  /// (제목·본문 모두 maxLines 로 잘려 이보다 커지지 않는다. 실측값 —
  /// stability_coach_inbox_test 의 '공지 긴 본문' 이 지킨다).
  /// 공지가 없어도 이만큼은 자리를 지킨다 — 최초 로딩이 끝나거나 SSE 로 새 공지가
  /// 들어와도 대화 목록이 통째로 내려가지 않는다.
  static const double announcementSlotH = 123;

  /// 칸 전환 — 골든·회귀 테스트가 이 키로 칸을 누른다.
  static const Key kPaneSwitch = Key('inbox-pane-switch');

  /// 칸 이름 (§0-B — 화면·테스트가 같은 문자열을 쓴다).
  static const String paneCoach = '코치';
  static const String paneActivity = '활동';

  const MessagingFeed({super.key});

  @override
  State<MessagingFeed> createState() => _MessagingFeedState();
}

class _MessagingFeedState extends State<MessagingFeed> {
  bool _activity = false;

  void _selectPane(int i) {
    final activity = i == 1;
    if (activity == _activity) return;
    Haptic.light();
    setState(() => _activity = activity);
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final isCoach = gs.isOwner;
    final gymId = gs.membership.gym?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            HyphenTokens.sp4,
            0,
            HyphenTokens.sp4,
            HyphenTokens.sp2,
          ),
          child: Row(
            children: [
              const HkSectionLabel('메시지'),
              const Spacer(),
              if (gymId != null) ..._actions(context, gs, isCoach, gymId),
            ],
          ),
        ),
        if (gymId == null)
          const Padding(
            padding: EdgeInsets.fromLTRB(
              HyphenTokens.sp4,
              HyphenTokens.sp2,
              HyphenTokens.sp4,
              HyphenTokens.sp4,
            ),
            child: Text('가입 승인 후 코치 쪽지·공지 사용 가능.', style: HyphenTokens.caption),
          )
        else ...[
          // 공지 자리 — 공지가 있든 없든 높이가 같다. 전엔 최초 로딩이 끝나는
          // 순간·SSE 로 새 공지가 도착하는 순간 없던 배너가 생겨, 바로 아래
          // 대화 목록이 통째로 밀렸다 (DESIGN-SSOT §레이아웃 안정성).
          HkReservedSlot(
            key: MessagingFeed.kAnnouncementSlot,
            minHeight: MessagingFeed.announcementSlotH,
            child: Consumer<AnnouncementsState>(
              // 비어 있어도 **빈 구멍이 아니라 빈 카드**를 둔다 — 자리만 남기고
              // 아무것도 그리지 않으면 그 자리가 고장 난 여백으로 읽힌다
              // (DESIGN-SSOT §레이아웃 안정성 "색이 사라지면 없어진 것으로 읽힌다").
              builder: (ctx, ann, _) =>
                  _PinnedAnnouncement(announcements: ann.items),
            ),
          ),
          // 회원만 두 칸 — 코치는 회원과의 대화 하나뿐이라 칸을 두지 않는다.
          if (!isCoach) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HyphenTokens.sp4, HyphenTokens.sp2, HyphenTokens.sp4, 0),
              child: HkSegment(
                key: MessagingFeed.kPaneSwitch,
                labels: const [
                  MessagingFeed.paneCoach,
                  MessagingFeed.paneActivity,
                ],
                selected: _activity ? 1 : 0,
                onSelected: _selectPane,
              ),
            ),
            const SizedBox(height: HyphenTokens.sp2),
          ],
          if (isCoach || !_activity)
            _EmbeddedThreadList(
              key: MessagingFeed.kThreadList,
              gymId: gymId,
              emptyHint: isCoach ? '회원 쪽지 도착 시 표시.' : '코치 쪽지 도착 시 표시.',
            )
          else
            _ActivityList(key: MessagingFeed.kThreadList, gymId: gymId),
        ],
      ],
    );
  }

  List<Widget> _actions(
    BuildContext context,
    GymState gs,
    bool isCoach,
    int gymId,
  ) {
    if (isCoach) {
      return [
        // v3.28 (2026-08-25 사용자 지시): '그룹' 삭제. '새 쪽지' 는 회원 목록에서
        // 받을 사람을 고르면 그 회원과의 대화로 — 대상·종류·제목 같은 칸 없음.
        _FeedAction(
          icon: Icons.edit_outlined,
          label: '새 쪽지',
          onTap: () async {
            Haptic.light();
            await Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const NewNoteScreen()),
            );
            if (context.mounted) {
              await context.read<InboxState>().refresh();
            }
          },
        ),
      ];
    }
    // 회원 — 코치에게 먼저 쪽지 시작.
    if (gs.membership.gym?.ownerHash == null) return const [];
    return [
      _FeedAction(
        icon: Icons.edit_outlined,
        label: '코치에게 쪽지',
        onTap: () {
          Haptic.light();
          final gymv = gs.membership.gym!;
          final coachName = gs.coaches.isNotEmpty
              ? gs.coaches.first.name
              : ((gymv.profile?.coachName ?? '').trim().isNotEmpty
                    ? gymv.profile!.coachName!.trim()
                    : '코치');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatThreadScreen(
                gymId: gymv.id,
                peerHash: gymv.ownerHash!,
                peerName: coachName,
              ),
            ),
          );
        },
      ),
    ];
  }
}

class _FeedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeedAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(HyphenTokens.r1),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HyphenTokens.sp2,
          vertical: HyphenTokens.sp1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: HyphenTokens.accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: HyphenTokens.micro.copyWith(color: HyphenTokens.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 스크롤 부모(ListView) 안에 들어가는 대화 목록 — 자체 스크롤 X, Column 으로 렌더.
class _EmbeddedThreadList extends StatefulWidget {
  final int gymId;
  final String emptyHint;
  const _EmbeddedThreadList({
    super.key,
    required this.gymId,
    required this.emptyHint,
  });

  @override
  State<_EmbeddedThreadList> createState() => _EmbeddedThreadListState();
}

class _EmbeddedThreadListState extends State<_EmbeddedThreadList> {
  late final InboxRepository _repo;
  Future<List<CoachThread>>? _future;
  StreamSubscription<SseEvent>? _sseSub;

  @override
  void initState() {
    super.initState();
    _repo = InboxRepository(context.read<ApiClient>());
    _future = _repo.listThreads(widget.gymId);
    _sseSub = _listenNoteNew(context, () {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repo.listThreads(widget.gymId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoachThread>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const HkLoading.slot();
        }
        if (snap.hasError) {
          return HkErrorState.fromError(snap.error, onRetry: _reload);
        }
        final threads = snap.data ?? const <CoachThread>[];
        if (threads.isEmpty) {
          // D117 — 빈 상태만 자리를 안 잡아 로딩(132) → 빈(43) 으로 89px 줄었다.
          // 로딩·에러와 같은 바닥을 갖는다 (문구 모양은 그대로 — 왼쪽 정렬 캡션).
          return HkReservedSlot(
            minHeight: HyphenTokens.stateSlotH,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                HyphenTokens.sp4,
                HyphenTokens.sp2,
                HyphenTokens.sp4,
                HyphenTokens.sp4,
              ),
              child: Text(widget.emptyHint, style: HyphenTokens.caption),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < threads.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: HyphenTokens.border,
                  indent: HyphenTokens.sp4,
                  endIndent: HyphenTokens.sp4,
                ),
              _ThreadRow(
                thread: threads[i],
                gymId: widget.gymId,
                onReturn: _reload,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 활동 칸 — 자동 통보만 시간순 (D72 · 2026-08-29).
///
/// 숨은 칸이라 처음 열릴 때 FutureBuilder 가 늦게 붙는다 — 에러가 unhandled 로
/// 새지 않게 `retainError` 로 감싼다 (CLAUDE.md §골든 캡처).
class _ActivityList extends StatefulWidget {
  final int gymId;
  const _ActivityList({super.key, required this.gymId});

  @override
  State<_ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<_ActivityList> {
  late final InboxRepository _repo;
  Future<InboxResult>? _future;
  StreamSubscription<SseEvent>? _sseSub;

  @override
  void initState() {
    super.initState();
    _repo = InboxRepository(context.read<ApiClient>());
    _future = retainError(_repo.listActivity(widget.gymId));
    _sseSub = _listenNoteNew(context, () {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = retainError(_repo.listActivity(widget.gymId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InboxResult>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const HkLoading.slot();
        }
        // 실패를 '아직 활동 없음.' 으로 그리면 안 된다 (2026-09-02 검증 — 조회가
        // 실패해도 빈 문구가 나와 쪽지 무음 실패와 구분이 불가능했다).
        if (snap.hasError) {
          return HkErrorState.fromError(snap.error, onRetry: _reload);
        }
        final items = snap.data?.items ?? const <CoachNote>[];
        if (items.isEmpty) {
          // D117 — 대화 목록과 같은 바닥 (로딩·에러와 높이 일치).
          return const HkReservedSlot(
            minHeight: HyphenTokens.stateSlotH,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                HyphenTokens.sp4,
                HyphenTokens.sp2,
                HyphenTokens.sp4,
                HyphenTokens.sp4,
              ),
              child: Text('아직 활동 없음.', style: HyphenTokens.caption),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: HyphenTokens.border,
                  indent: HyphenTokens.sp4,
                  endIndent: HyphenTokens.sp4,
                ),
              _ActivityRow(note: items[i], onReturn: _reload),
            ],
          ],
        );
      },
    );
  }
}

/// 활동 1줄 — 시각 · 제목 · 본문 한 줄. 안 읽었으면 굵게.
class _ActivityRow extends StatelessWidget {
  final CoachNote note;
  final VoidCallback onReturn;
  const _ActivityRow({required this.note, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final unread = note.my?.isUnread ?? false;
    return InkWell(
      onTap: () async {
        Haptic.light();
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: note.id)),
        );
        onReturn();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HyphenTokens.sp4,
          vertical: HyphenTokens.sp3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안읽음 점 — 자리는 늘 잡아 둔다 (읽으면 색만 빠진다).
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 6, right: HyphenTokens.sp3),
              decoration: BoxDecoration(
                color: unread ? HyphenTokens.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.trim().isNotEmpty ? note.title : '알림',
                    style: HyphenTokens.body.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: HyphenTokens.sp1),
                  Text(
                    note.body.trim(),
                    style: HyphenTokens.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Text(CoachDossierTile._agoLabel(note.createdAt),
                style: HyphenTokens.micro),
          ],
        ),
      ),
    );
  }
}

/// 대화 목록 1줄 — 회원 이름 · 마지막 메시지 · 시각 · 안읽음.
class _ThreadRow extends StatelessWidget {
  final CoachThread thread;
  final int gymId;
  final VoidCallback onReturn;
  const _ThreadRow({
    required this.thread,
    required this.gymId,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final raw = (thread.peerName ?? '').trim();
    final name = raw.isNotEmpty
        ? raw
        : (thread.peerHash.isNotEmpty
              ? thread.peerHash.substring(
                  0,
                  thread.peerHash.length < 6 ? thread.peerHash.length : 6,
                )
              : 'MEMBER');
    final unread = thread.unread > 0;
    return InkWell(
      onTap: () async {
        Haptic.light();
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              gymId: gymId,
              peerHash: thread.peerHash,
              peerName: name,
            ),
          ),
        );
        onReturn();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HyphenTokens.sp4,
          vertical: HyphenTokens.sp3,
        ),
        child: Row(
          children: [
            Avatar(
              hash: thread.peerHash,
              displayName: name,
              colorHex: thread.peerColor,
            ),
            const SizedBox(width: HyphenTokens.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: HyphenTokens.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: HyphenTokens.fg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _shortTime(thread.lastAt),
                        style: HyphenTokens.micro,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.lastBody,
                    style: HyphenTokens.caption.copyWith(
                      color: unread ? HyphenTokens.fg : HyphenTokens.muted,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: HyphenTokens.sp2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: HyphenTokens.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${thread.unread}',
                  style: HyphenTokens.micro.copyWith(
                    color: HyphenTokens.fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 코치 ↔ 특정 회원 1:1 채팅 화면. 말풍선 + 입력바(개별 발신).
class ChatThreadScreen extends StatefulWidget {
  final int gymId;
  final String peerHash;
  final String peerName;
  const ChatThreadScreen({
    super.key,
    required this.gymId,
    required this.peerHash,
    required this.peerName,
  });

  // ── 레이아웃 안정성 앵커 (D118 · 2026-09-05) ────────────────────────────────
  // 입력바는 Column 의 마지막 칸이고 위는 Expanded 다 — 바가 1px 두꺼워지면
  // 대화 목록이 그만큼 깎인다. 전송 중에도 바의 y·높이가 같아야 한다.
  // 회귀 게이트 = test/golden/stability_inbox_test.dart.
  static const Key kInputBar = Key('chat-input-bar');
  static const Key kSendSlot = Key('chat-send-slot');

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  late final InboxRepository _repo;
  late final GymRepository _gymRepo;
  final _ctrl = TextEditingController();
  Future<List<ChatMessage>>? _future;
  bool _sending = false;
  StreamSubscription<SseEvent>? _sseSub;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _repo = InboxRepository(api);
    _gymRepo = GymRepository(api);
    _future = _repo.listMessages(widget.gymId, peer: widget.peerHash);
    // 열자마자 읽음으로 — 화면에 떠 있는 동안 새로 오는 것도 _reload 가 처리한다.
    _markVisibleRead();
    _sseSub = _listenNoteNew(context, () {
      if (mounted) _reload();
    });
  }

  void _reload() {
    setState(() {
      _future = _repo.listMessages(widget.gymId, peer: widget.peerHash);
    });
    _markVisibleRead();
  }

  /// 이 대화에서 **내가 받은 안 읽은 쪽지**를 읽음으로 넘긴다 (2026-08-28).
  /// 종전엔 대화를 다 읽고 나와도 벨의 빨간 등이 남았다 — 읽음 처리가 쪽지
  /// 상세 화면에만 있었기 때문. 회원이 실제로 쓰는 길은 이 대화 화면이다.
  Future<void> _markVisibleRead() async {
    final msgs = await _future;
    if (msgs == null || !mounted) return;
    final unreadIds = msgs
        .where((m) => !m.mine && m.status == 'sent')
        .map((m) => m.id)
        .toList();
    if (unreadIds.isEmpty) return;
    await context.read<InboxState>().markThreadRead(unreadIds);
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty || _sending) return;
    Haptic.light();
    final isOwner = context.read<GymState>().isOwner;
    setState(() => _sending = true);
    try {
      if (isOwner) {
        // 코치 → 회원: 개별 note.
        await _repo.postNote(
          gymId: widget.gymId,
          targetType: 'individual',
          targetId: widget.peerHash,
          kind: 'note',
          title: '',
          body: msg,
        );
      } else {
        // 회원 → 코치: member-report 로 그 코치에게.
        await _gymRepo.memberReport(
          gymId: widget.gymId,
          message: msg,
          to: widget.peerHash,
        );
      }
      _ctrl.clear();
      _reload();
    } catch (_) {
      if (mounted) {
        HkSnack.error(context, '전송 실패. 다시 시도.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<GymState>().isOwner;
    return Scaffold(
      appBar: HkAppBar(title: widget.peerName),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<List<ChatMessage>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const HkLoading.slot();
                  }
                  final msgs = snap.data ?? const <ChatMessage>[];
                  if (msgs.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text('첫 쪽지 작성.', style: HyphenTokens.caption),
                        ),
                      ],
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: HyphenTokens.sp4,
                        vertical: HyphenTokens.sp3,
                      ),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) => _ChatBubble(msg: msgs[i]),
                    ),
                  );
                },
              ),
            ),
            _ChatInputBar(
              controller: _ctrl,
              sending: _sending,
              onSend: _send,
              hint: isOwner ? '회원에게 쪽지…' : '코치에게 쪽지…',
            ),
          ],
        ),
      ),
    );
  }
}
