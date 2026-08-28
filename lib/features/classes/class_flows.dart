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

/// **차감 없이 취소되는 마지막 시점** (분) — 이 선을 지나 취소하면 '늦은 취소'다.
/// 서버 `api/_membership.py LATE_CANCEL_MINUTES` 와 같은 값이고, 기록도 차감도
/// 서버가 한다 (브리프 D57). 앱은 **막지 않고 사실만 미리 알린다** — 테스터 확정
/// (2026-08-28) 으로 시작이 임박해도 회원이 스스로 취소할 수 있다.
/// 구 '취소 시한 60분' 상수는 버튼을 미리 잠그던 선이라 차단과 함께 폐기됐다.
const int kLateCancelMinutes = 20;

/// 지금 취소하면 '늦은 취소'로 기록되는 구간인가 (시작 20분 전을 지났나).
bool isLateCancel(ClassSessionDto c) => !appClock
    .now()
    .isBefore(c.startAt.subtract(const Duration(minutes: kLateCancelMinutes)));

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
  // 테스터 확정 (2026-08-28) — 시작이 임박해도 취소를 막지 않는다. 대신 시작
  // 20분 전을 지났으면 차감될 수 있다는 사실을 누르기 전에 말한다. 조용히
  // 차감하면 화면이 거짓말을 하는 것이다 (코치 쪽 기록은 회원의 일이 아니라
  // 문구에 담지 않는다). 대기 이탈은 차감 규칙 자체가 없어 안내도 없다.
  final isLate = !isWaitlistCancel && isLateCancel(c);
  final ok = await HkDialog.confirm(
    context,
    title: isWaitlistCancel ? '대기를 취소할까요?' : '예약을 취소할까요?',
    message: '${c.title} · $when',
    notice: isLate ? '늦은 취소로 기록됩니다. 횟수권은 1회 차감될 수 있습니다.' : null,
    // 여기는 자리를 미리 잡지 않는다. 공간 예약은 '보고 있는 화면 안에서 상태가
    // 바뀔 때' 를 위한 것인데(로그인 에러·목록 로딩), 이 안내는 어느 수업을
    // 취소하느냐로 정해져 다이얼로그가 열린 뒤 붙거나 빠지지 않는다. 늘 비워
    // 두면 흔한 쪽(20분 전까지) 다이얼로그에 빈 띠만 남는다 — state_23 캡처.
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
