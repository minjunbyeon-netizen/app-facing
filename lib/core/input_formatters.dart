import 'package:flutter/services.dart';

/// 입력칸 서식 — 화면마다 다시 만들지 않는다 (§3 코드 SSOT).
/// v2.6 (2026-08-13 사용자 지시): 생년월일 자동 하이픈 + 형식 검증.

/// 생년월일 — 숫자만 받아 `YYYY-MM-DD` 로 하이픈을 자동으로 넣는다.
///
/// 사람이 하이픈을 직접 치게 두면 `1995.1.1`·`19950101`·`95-01-01` 이 뒤섞여
/// 코치 PC 명단의 '생년' 칸이 제각각이 된다. PC 신규 등록 폼도 같은 방식으로
/// 자동 삽입한다(`members.html formatBirth`) — 두 창구의 결과를 같게 맞춘다.
class BirthDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 4 || i == 6) buf.write('-');
      buf.write(capped[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// 생년월일 값 검증. 통과하면 null, 문제가 있으면 사용자에게 보일 한 줄.
///
/// - **빈 값은 통과** — 선택 입력이다. 안 적었다고 진행을 막지 않는다.
/// - 8자리를 다 채우기 전에는 조용히 둔다 (타이핑 도중 빨간 글씨는 방해다).
/// - 없는 날짜(2월 30일)·미래·1900년 이전은 막는다.
String? birthDateError(String raw, {DateTime? today}) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  if (digits.length < 8) return null;

  final y = int.parse(digits.substring(0, 4));
  final m = int.parse(digits.substring(4, 6));
  final d = int.parse(digits.substring(6, 8));
  final now = today ?? DateTime.now();

  if (y < 1900 || y > now.year) return '연도를 확인해 주세요.';
  if (m < 1 || m > 12) return '월은 01~12 입니다.';
  // 그 달의 마지막 날 = 다음 달 0일.
  final lastDay = DateTime(y, m + 1, 0).day;
  if (d < 1 || d > lastDay) return '$m월은 $lastDay일까지입니다.';
  if (DateTime(y, m, d).isAfter(DateTime(now.year, now.month, now.day))) {
    return '오늘 이후 날짜는 넣을 수 없습니다.';
  }
  return null;
}
