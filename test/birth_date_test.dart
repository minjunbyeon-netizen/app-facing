// 생년월일 입력 서식·검증 (v2.6 · 2026-08-13 사용자 지시).
// 코치 PC 명단의 '생년' 칸이 제각각이 되지 않도록 앱 입구에서 형식을 고정한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/core/input_formatters.dart';

String _format(String typed) {
  final f = BirthDateInputFormatter();
  return f
      .formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: typed),
      )
      .text;
}

void main() {
  group('BirthDateInputFormatter — 하이픈 자동', () {
    test('숫자만 치면 YYYY-MM-DD 로 채워진다', () {
      expect(_format('19950101'), '1995-01-01');
    });
    test('치는 도중에도 하이픈이 붙는다', () {
      expect(_format('1995'), '1995');
      expect(_format('199501'), '1995-01');
      expect(_format('1995010'), '1995-01-0');
    });
    test('사람이 넣은 하이픈·점은 무시하고 다시 만든다', () {
      expect(_format('1995.01.01'), '1995-01-01');
      expect(_format('1995-01-01'), '1995-01-01');
    });
    test('8자리를 넘기면 잘린다', () {
      expect(_format('199501011234'), '1995-01-01');
    });
  });

  group('birthDateError — 값 검증', () {
    final today = DateTime(2026, 8, 13);
    test('빈 값은 통과 (선택 입력)', () {
      expect(birthDateError('', today: today), isNull);
    });
    test('채우는 중에는 조용하다', () {
      expect(birthDateError('1995-01', today: today), isNull);
    });
    test('정상 날짜는 통과', () {
      expect(birthDateError('1995-01-01', today: today), isNull);
    });
    test('없는 날짜는 막는다', () {
      expect(birthDateError('1995-02-30', today: today), isNotNull);
      expect(birthDateError('1995-13-01', today: today), isNotNull);
    });
    test('윤년 2월 29일은 통과', () {
      expect(birthDateError('1996-02-29', today: today), isNull);
      expect(birthDateError('1995-02-29', today: today), isNotNull);
    });
    test('미래·1900년 이전은 막는다', () {
      expect(birthDateError('2027-01-01', today: today), isNotNull);
      expect(birthDateError('1899-12-31', today: today), isNotNull);
    });
  });
}
