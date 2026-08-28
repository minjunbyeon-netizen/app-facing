import 'package:flutter/material.dart';

import '../../core/app_clock.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/notification_service.dart';
import '../../core/time_format.dart';
import '../../models/class_session.dart';
import '../../widgets/hkit.dart';
import '../../widgets/mascot.dart';
import 'classes_repository.dart';

/// 수업 예약·취소 흐름 — 화면 밖 함수 두 개.

/// 회원이 스스로 취소할 수 있는 마지막 시점 (분). 서버
/// `api/_membership.py CANCEL_DEADLINE_MINUTES` 와 같은 값 —
/// **판정은 서버가 하고 여기서는 버튼을 미리 잠그고 이유를 적는다.**
/// 눌러 봐야 실패하는 버튼보다 왜 못 누르는지 먼저 말하는 편이 낫다.
const int kCancelDeadlineMinutes = 60;

/// 지금 이 수업을 회원이 취소할 수 있나 (시작 60분 전을 안 지났나).
bool canMemberCancel(ClassSessionDto c) => appClock
    .now()
    .isBefore(c.startAt.subtract(const Duration(minutes: kCancelDeadlineMinutes)));

// v2.4 (2026-08-12): 예약 로직이 두 벌이 되면 정책이 갈라진다 (§3 코드 SSOT).
// v3.25 (2026-08-25): 구 `/classes` 화면(classes_screen.dart)을 지우면서 이 둘만
// 남겼다 — 회원이 예약하는 자리는 수업 탭 주간보드 하나다.

/// 예약 실행 — 성공/대기 등록 시 스낵바 + true, 실패 시 에러 스낵바 + false.
Future<bool> reserveClassFlow(
  BuildContext context,
  ClassesRepository repo,
  ClassSessionDto c,
) async {
  Haptic.medium();
  final messenger = HkSnack.of(context);
  try {
    final result = await repo.reserve(c.id);
    final status = (result['status'] ?? '').toString();
    // 테스터 지시 (2026-08-28) — "오늘 몇 시 예약했더라 하고 까먹을 수도 있기
    // 때문". 자리를 잡은 예약만 1시간 전 알림을 건다 (대기는 아직 내 자리가 아니다).
    final rid = result['reservation_id'];
    if (status != 'waitlisted' && rid is int) {
      await NotificationService.instance.scheduleClassReminder(
        reservationId: rid,
        title: c.title,
        startAt: c.startAt.toLocal(),
      );
    }
    messenger.info(
      status == 'waitlisted' ? '대기열 ${result['position']}번 등록.' : '예약 완료.',
      mood: MascotMood.happy,
    );
    return true;
  } on AppException catch (e) {
    messenger.fail(e.messageKo);
    return false;
  }
}

/// 예약 취소 — 확인 다이얼로그 → 취소. 취소가 성사되면 true.
Future<bool> cancelClassFlow(
  BuildContext context,
  ClassesRepository repo,
  ClassSessionDto c,
) async {
  // G30 픽스 (2026-08-24): 대기자는 예약 행이 없어 종전엔 여기서 조용히
  // return — 대기 '취소' 버튼이 무동작이었다. 대기는 전용 DELETE 로 이탈.
  final isWaitlistCancel = c.isWaitlisted;
  final res = c.myReservation;
  if (!isWaitlistCancel && (res == null || !c.isReserved)) return false;
  final l = c.startAt.toLocal();
  final when = '${l.month}/${l.day} ${hhmm(l)}';
  // 테스터 지시 (2026-08-28) — 회원 취소는 시작 1시간 전까지만. 시한을 넘겼으면
  // 서버에 갔다가 거절당하게 두지 않고 여기서 이유를 먼저 말한다. 대기 이탈은
  // 제외 — 대기는 아직 내 자리가 아니라 언제든 뺄 수 있다.
  if (!isWaitlistCancel && !canMemberCancel(c)) {
    HkSnack.of(context).fail(
      '수업 시작 $kCancelDeadlineMinutes분 전까지만 취소할 수 있습니다. '
      '코치에게 쪽지로 알려 주세요.',
    );
    return false;
  }
  final ok = await HkDialog.confirm(
    context,
    title: isWaitlistCancel ? '대기를 취소할까요?' : '예약을 취소할까요?',
    message: '${c.title} · $when',
    cancelLabel: '유지',
    confirmLabel: '취소',
  );
  if (!ok || !context.mounted) return false;
  Haptic.medium();
  final messenger = HkSnack.of(context);
  try {
    if (isWaitlistCancel) {
      await repo.cancelWaitlist(c.id);
      messenger.info('대기 취소.', mood: MascotMood.happy);
    } else {
      final result = await repo.cancel(res!.reservationId);
      // 안 갈 수업을 알리지 않는다 — 걸어 둔 1시간 전 알림을 함께 지운다.
      await NotificationService.instance
          .cancelClassReminder(res.reservationId);
      final msg = (result['message'] ?? '').toString();
      final charged = result['session_charged'] == true;
      // 차감된 취소는 실패가 아니라 상태 안내 — 담담한 얼굴.
      messenger.info(
        msg.isEmpty ? '예약 취소.' : msg,
        mood: charged ? MascotMood.neutral : MascotMood.happy,
      );
    }
    return true;
  } on AppException catch (e) {
    messenger.fail(e.messageKo);
    return false;
  }
}
