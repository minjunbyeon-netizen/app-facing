import 'package:flutter/material.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/notification_service.dart';
import '../../core/time_format.dart';
import '../../models/class_session.dart';
import '../../widgets/hkit.dart';
import '../../widgets/mascot.dart';
import 'classes_repository.dart';

/// 수업 예약·취소 흐름 — 화면 밖 함수 두 개.

// D96 (2026-08-30): '늦은 취소' 판정은 서버가 한다 (체육관마다 노쇼 정책이 다르다 —
// 알림 설정 → 노쇼 정책). 구 `kLateCancelMinutes`·`isLateCancel` 상수 판정 폐기 — 다이얼로그를
// 열기 전에 `ClassesRepository.cancelPreview` 로 한 줄을 받아 그대로 보여 준다. 앱은 막지 않는다.

// v2.4 (2026-08-12): 예약 로직이 두 벌이 되면 정책이 갈라진다 (§3 코드 SSOT).
// v3.25 (2026-08-25): 구 `/classes` 화면(classes_screen.dart)을 지우면서 이 둘만
// 남겼다 — 회원이 예약하는 자리는 수업 탭 주간보드 하나다.

/// 예약 오픈 전에 '예약' 을 눌렀을 때의 스낵바 문구 (D82 · 2026-08-29 사용자 원문
/// "예약 가능한 시간이 아니에요"). 골든 `state_15` 와 검사가 같은 상수를 본다.
const String kBookingNotOpenSnack = '예약 가능한 시간이 아니에요';

/// 예약 완료 토스트 (D86 · 2026-08-29 사용자 원문 "예약이 완료되었습니다. / 수업시간
/// 최소5분전 도착해서 운동준비를 마쳐주세요 / 5분 이상 지각은, 수업에 참여할 수 없습니다").
/// 제목 한 줄 + 안내 두 줄, 웃는 캐릭터, 화면 중앙 폭죽 한 번. 대기 등록은 자리가 아직
/// 아니라 폭죽 없이 종전 한 줄. 골든 `snack_04` · `state_27` 이 같은 상수를 본다.
const String kReservedTitle = '예약이 완료되었습니다.';
const List<String> kReservedDetail = [
  '수업 시간 최소 5분 전에 도착해 운동 준비를 마쳐 주세요.',
  '5분 이상 지각은 수업에 참여할 수 없습니다.',
];

/// 예약 오픈 전 안내 — 담담한 캐릭터 스낵바. 실패(붉은 테두리·우는 얼굴)가 아니라
/// 상태 안내다: 회원이 잘못한 게 없다. 오픈 시각은 서버가 준 `booking_open_at`
/// 그대로 붙인다 (정책 계산을 앱에 두 번 적지 않는다).
void _noticeBookingNotOpen(HkSnack messenger, ClassSessionDto c) {
  final open = c.bookingOpenAt?.toLocal();
  // 둘째 줄에 시각 — 한 줄로 이으면 스낵바 폭에서 '부터' 만 다음 줄로 떨어진다(골든 실측).
  final when = open == null ? '' : '\n${open.month}/${open.day} ${hhmm(open)} 부터';
  messenger.info('$kBookingNotOpenSnack$when', mood: MascotMood.neutral);
}

/// 예약 실행 — 성공/대기 등록 시 스낵바 + true, 실패 시 에러 스낵바 + false.
Future<bool> reserveClassFlow(
  BuildContext context,
  ClassesRepository repo,
  ClassSessionDto c,
) async {
  Haptic.medium();
  final messenger = HkSnack.of(context);
  // D82 — 오픈 전이면 서버를 두드리지 않고 바로 안내. 버튼은 살아 있다
  // (사용자: "그 예약 버튼 누르고 싶은데"). 기기 시계가 틀려 여기를 지나쳐도
  // 서버 409 BOOKING_NOT_OPEN 이 아래 catch 에서 같은 문구로 잡는다.
  if (c.isBookingNotOpen) {
    _noticeBookingNotOpen(messenger, c);
    return false;
  }
  try {
    final result = await repo.reserve(c.id);
    final status = (result['status'] ?? '').toString();
    // 테스터 지시 (2026-08-28) — "오늘 몇 시 예약했더라 하고 까먹을 수도 있기
    // 때문". 자리를 잡은 예약만 1시간 전 알림을 건다 (대기는 아직 내 자리가 아니다).
    final rid = result['reservation_id'];
    if (status != 'waitlisted' && rid is int) {
      await NotificationService.instance.scheduleClassReminder(
        reservationId: rid,
        title: c.displayTitle,
        startAt: c.startAt.toLocal(),
      );
    }
    if (status == 'waitlisted') {
      messenger.info('대기열 ${result['position']}번 등록.', mood: MascotMood.happy);
    } else {
      // D86 — 세 줄 토스트 + 폭죽. 폭죽은 화면이 아직 있을 때만(await 뒤라 확인).
      messenger.info(
        kReservedTitle,
        detail: kReservedDetail,
        mood: MascotMood.happy,
      );
      if (context.mounted) HkConfetti.burst(context);
    }
    return true;
  } on AppException catch (e) {
    if (e.code == 'BOOKING_NOT_OPEN') {
      _noticeBookingNotOpen(messenger, c);
    } else {
      messenger.fail(e.messageKo);
    }
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
  // 테스터 확정 (2026-08-28) — 시작이 임박해도 취소를 막지 않는다. 대신 차감될 수
  // 있다는 사실을 누르기 전에 말한다. 조용히 차감하면 화면이 거짓말을 하는 것이다
  // (코치 쪽 기록은 회원의 일이 아니라 문구에 담지 않는다). 대기 이탈은 차감 규칙
  // 자체가 없어 안내도 없다. D96 — 문구는 서버 판정(체육관 노쇼 정책) 그대로.
  String? notice;
  if (!isWaitlistCancel) {
    try {
      notice = await repo.cancelPreview(res!.reservationId);
    } catch (_) {
      notice = null; // 미리보기 실패는 취소를 막지 않는다 — 결과 문구는 취소 응답이 말한다
    }
    if (!context.mounted) return false;
  }
  final ok = await HkDialog.confirm(
    context,
    title: isWaitlistCancel ? '대기를 취소할까요?' : '예약을 취소할까요?',
    message: '${c.displayTitle} · $when',
    notice: notice,
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
