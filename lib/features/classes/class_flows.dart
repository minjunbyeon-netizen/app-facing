import 'package:flutter/material.dart';

import '../../core/app_clock.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/time_format.dart';
import '../../models/class_session.dart';
import '../../widgets/hkit.dart';
import '../../widgets/mascot.dart';
import 'classes_repository.dart';

/// 수업 예약·취소 흐름 — 화면 밖 함수 두 개.
///
/// 서버 `api/_membership.py LATE_CANCEL_MINUTES` 와 같은 값 — 다이얼로그 경고
/// 문구용 (판정 정본은 서버).
const int kLateCancelMinutes = 20;
///
/// v2.4 (2026-08-12): 예약 로직이 두 벌이 되면 정책이 갈라진다 (§3 코드 SSOT).
/// v3.25 (2026-08-25): 구 `/classes` 화면(classes_screen.dart)을 지우면서 이 둘만
/// 남겼다 — 회원이 예약하는 자리는 수업 탭 주간보드 하나다.

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
  // D57 (2026-08-26): 시작 20분 전을 지난 취소는 횟수권에서 차감될 수 있다
  // (회원권마다 1회 면제). 정확한 차감 여부는 서버가 취소 응답 문구로 알린다.
  final late = !isWaitlistCancel &&
      !appClock.now().isBefore(
        c.startAt.subtract(const Duration(minutes: kLateCancelMinutes)),
      );
  final ok = await HkDialog.confirm(
    context,
    title: isWaitlistCancel ? '대기를 취소할까요?' : '예약을 취소할까요?',
    message: late
        ? '${c.title} · $when\n수업 20분 전이 지났습니다 — 횟수권은 1회 차감될 수 있습니다.'
        : '${c.title} · $when',
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
