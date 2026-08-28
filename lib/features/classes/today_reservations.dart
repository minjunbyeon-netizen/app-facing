import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_clock.dart';
import '../../core/futures.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../widgets/hkit.dart';
import '../../models/class_session.dart';
import 'classes_repository.dart';

/// 홈 맨 위 "오늘 내 예약" — 테스터 지시 (2026-08-28).
///
/// > "예약을 하면 내가 오늘 어떤 수업에 예약했는지 바로 확인할 수 있는 칸이 있으면
/// >  좋을 것 같음 … 오늘 몇 시 예약했더라 하고 까먹을 수도 있기 때문"
///
/// 회원이 앱을 여는 이유 1번이 "내가 몇 시에 가야 하지" 인데, 종전엔 수업 탭으로
/// 옮겨 그 주 보드에서 오늘 줄을 눌러야 알 수 있었다. 홈 첫 화면에서 바로 답한다.
///
/// 규칙:
/// - **오늘 것만** 보여 준다. 내일 예약은 오늘의 질문이 아니다.
/// - 이미 끝난 수업은 뺀다 (지나간 것을 '예정' 처럼 보이면 그것도 거짓말이다).
/// - 대기도 함께 — 자리를 잡은 것과 구분해서 적는다.
///
/// **자리는 항상 지킨다** (DESIGN-SSOT §레이아웃 안정성 · AchievementSection 선례).
/// 예약은 화면이 뜬 뒤에 도착하므로, 없을 때 숨겼다가 도착해서 나타나면 그 아래가
/// 통째로 밀린다. 로딩·빈·데이터·실패 네 상태가 같은 높이([kHeight])를 쓴다.
/// 빈 상태에도 값이 있다 — "오늘 예약 없음" 은 회원이 물은 것에 대한 진짜 답이다.
///
/// 표가 아니라 **한 줄 띠**인 이유 (2026-08-28 실측): 두 줄짜리 카드로 만들었더니
/// 이 화면의 맨 아래 앵커가 뷰포트 밖으로 밀려나 안정성 게이트가 걸렸다. 이 정보는
/// "몇 시에 가면 되지" 한 마디면 끝나므로, 자리를 크게 먹을 이유가 없다.
class TodayReservationsCard extends StatefulWidget {
  const TodayReservationsCard({super.key});

  /// 레이아웃 안정성 앵커 — 상태가 바뀌어도 이 카드의 y 는 같아야 한다.
  static const Key kCard = Key('home-today-reservations');

  /// 상태와 무관하게 지키는 높이 — 한 줄 띠.
  static const double kHeight = 34;

  /// 한 줄에 이름까지 적는 예약 수. 나머지는 `+N` 으로 센다.
  ///
  /// 1인 이유 (2026-08-28 실측): 2건을 적었더니 360dp 폭에서 두 번째가 잘려
  /// "21:00 Olympic …" 이 됐다 — 시각을 알려주려는 칸에서 시각이 잘리면 그 칸은
  /// 제 일을 못 한다. 회원이 지금 묻는 것은 "다음에 언제" 하나이므로 **다음 1건**을
  /// 온전히 적고, 더 있으면 `+N` 으로 있다는 사실만 전한다.
  static const int kShown = 1;

  @override
  State<TodayReservationsCard> createState() => _TodayReservationsCardState();
}

class _TodayReservationsCardState extends State<TodayReservationsCard> {
  Future<List<MyReservationItem>>? _future;

  @override
  void initState() {
    super.initState();
    // FutureBuilder 가 늦게 붙는 자리라 retainError 로 감싼다 (CLAUDE.md 골든 규칙).
    _future = retainError(
      ClassesRepository(context.read<ApiClient>()).listMyReservations(),
    );
    _restoreReminders();
  }

  Future<void> _restoreReminders() async {
    try {
      final all = await _future;
      if (all == null) return;
      await restoreClassReminders(all);
    } catch (_) {
      // 알림 복원 실패가 화면을 막지 않는다.
    }
  }

  /// 오늘 아직 안 끝난 내 예약·대기만, 시간 순.
  List<MyReservationItem> _todayUpcoming(List<MyReservationItem> all) {
    final now = appClock.now();
    return all.where((r) {
      final s = r.startAt.toLocal();
      if (s.year != now.year || s.month != now.month || s.day != now.day) {
        return false;
      }
      return s.add(Duration(minutes: r.durationMinutes)).isAfter(now);
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  /// 한 줄 요약 — "20:00 WOD Class · 21:00 대기".
  String _line(List<MyReservationItem> items) {
    final shown = items.take(TodayReservationsCard.kShown).map((r) {
      final t = hhmm(r.startAt.toLocal());
      return r.isWaitlist ? '$t ${r.title} (대기)' : '$t ${r.title}';
    }).toList();
    final rest = items.length - shown.length;
    return rest > 0 ? '${shown.join('  ·  ')}  +$rest건' : shown.join('  ·  ');
  }

  Widget _content(AsyncSnapshot<List<MyReservationItem>> snap) {
    if (snap.connectionState != ConnectionState.done) {
      // 로딩도 같은 높이 — 글자만 비운다 (스켈레톤 한 줄은 이 크기에선 과하다).
      return const SizedBox.shrink();
    }
    // 실패를 '없음' 으로 뭉개지 않는다 — 없는 것과 못 읽은 것은 다르다.
    if (snap.hasError || !snap.hasData) {
      return Text('예약을 불러오지 못했습니다',
          style: HyphenTokens.caption, maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    final items = _todayUpcoming(snap.data!);
    if (items.isEmpty) {
      return Text('오늘 예약 없음',
          style: HyphenTokens.caption, maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    return Text(
      _line(items),
      style: HyphenTokens.body.copyWith(fontWeight: FontWeight.w700),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: TodayReservationsCard.kCard,
      height: TodayReservationsCard.kHeight,
      child: Row(
        children: [
          const HkSectionLabel('오늘 내 예약'),
          const SizedBox(width: HyphenTokens.sp2),
          Expanded(
            child: FutureBuilder<List<MyReservationItem>>(
              future: _future,
              builder: (context, snap) => Align(
                alignment: Alignment.centerRight,
                child: _content(snap),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 앞으로의 예약에 1시간 전 알림을 **다시 건다**.
///
/// 알림은 기기에 저장되므로, 예약할 때 한 번 거는 것만으로는 다음 경우에 사라진다:
/// 앱 재설치·기기 변경·알림 권한을 나중에 허용·'알림 받기'를 껐다 켬·다른 기기에서
/// 한 예약. 같은 id 로 덮어쓰므로 여러 번 돌려도 중복되지 않는다.
///
/// **절차를 한 곳에 두는 이유**: 홈 진입([TodayReservationsCard])과 내 정보의
/// '알림 받기' 재활성이 같은 일을 한다. 두 벌로 두면 한쪽만 고쳐진다 (§0-B).
Future<void> restoreClassReminders(List<MyReservationItem> reservations) async {
  final now = appClock.now();
  for (final r in reservations) {
    if (r.isWaitlist) continue; // 대기는 아직 내 자리가 아니다
    final start = r.startAt.toLocal();
    if (!start.isAfter(now)) continue; // 지난 수업은 알릴 것이 없다
    await NotificationService.instance.scheduleClassReminder(
      reservationId: r.id,
      title: r.title,
      startAt: start,
    );
  }
}

/// 내 예약을 새로 받아 [restoreClassReminders] 를 돌린다 — 목록을 손에 안 든
/// 화면용 (내 정보에서 '알림 받기'를 다시 켰을 때). 셸은 탭을 살려 두므로
/// (IndexedStack) 홈이 다시 initState 를 타지 않는다 — 켠 자리에서 직접 건다.
/// 실패해도 조용히 넘어간다: 알림은 못 걸려도 예약 자체는 서버에 그대로다.
Future<void> refetchAndRestoreClassReminders(ApiClient api) async {
  try {
    await restoreClassReminders(
      await ClassesRepository(api).listMyReservations(),
    );
  } catch (_) {
    // 복원 실패가 스위치 조작을 막지 않는다.
  }
}
