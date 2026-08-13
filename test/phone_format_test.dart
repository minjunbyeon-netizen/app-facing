// 전화번호 입력 서식 (v2.6 · 2026-08-13 사용자 지시 — 생년월일에 이어 적용).
// 코치 명단의 번호 표기를 한 가지로 고정한다. 나중에 번호를 기계로 쓰는
// 기능(문자 발송 등)을 붙일 때 다시 씻지 않아도 되게.
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/core/input_formatters.dart';

String _format(String typed) {
  final f = PhoneInputFormatter();
  return f
      .formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: typed),
      )
      .text;
}

void main() {
  group('PhoneInputFormatter — 휴대폰', () {
    test('숫자만 치면 010-1234-5678 로 채워진다', () {
      expect(_format('01012345678'), '010-1234-5678');
    });
    test('치는 도중에도 하이픈이 붙는다', () {
      expect(_format('010'), '010');
      expect(_format('0101'), '010-1');
      expect(_format('0101234'), '010-1234');
      expect(_format('01012345'), '010-1234-5');
    });
    test('070 도 가운데 4자리로 고정', () {
      expect(_format('07012345678'), '070-1234-5678');
    });
    test('011 계열은 10자리 3-3-4', () {
      expect(_format('0111234567'), '011-123-4567');
    });
    test('사람이 넣은 하이픈·점·공백은 무시하고 다시 만든다', () {
      expect(_format('010.1234.5678'), '010-1234-5678');
      expect(_format('010 1234 5678'), '010-1234-5678');
      expect(_format('010-1234-5678'), '010-1234-5678');
    });
    test('11자리를 넘기면 잘린다', () {
      expect(_format('0101234567899'), '010-1234-5678');
    });
  });

  group('PhoneInputFormatter — 지역번호', () {
    test('서울 02 는 앞토막이 2자리', () {
      expect(_format('021234567'), '02-123-4567');
      expect(_format('0212345678'), '02-1234-5678');
    });
    test('서울은 10자리에서 잘린다', () {
      expect(_format('02123456789'), '02-1234-5678');
    });
    test('치는 도중 02', () {
      expect(_format('02'), '02');
      expect(_format('021'), '02-1');
    });
    test('그 밖 지역번호는 3-3-4', () {
      expect(_format('0311234567'), '031-123-4567');
      expect(_format('0511234567'), '051-123-4567');
    });
  });

  group('PhoneInputFormatter — 빈 값', () {
    test('빈 값은 빈 값', () {
      expect(_format(''), '');
    });
    test('숫자가 하나도 없으면 빈 값', () {
      expect(_format('---'), '');
    });
  });
}
