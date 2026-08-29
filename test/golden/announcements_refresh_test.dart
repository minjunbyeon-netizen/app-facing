// 공지가 폰에 뜨는 두 경로의 회귀 (D79 · 2026-08-29).
//
// 사용자 보고: "지금 공지 제대로 작동안한다. pc설정했는데 폰에서는 안보인다"
//
// 원인 두 겹:
//   1) AnnouncementsState.bind 가 "이미 묶였고 목록이 있으면" 건너뛰어, 한 번 받은
//      목록이 앱을 껐다 켜기 전까지 굳었다.
//   2) announcement.posted SSE 는 GymState 만 reload 시켰는데 GymState 는 공지를
//      싣지 않는다 — AnnouncementsState 를 다시 묻게 하는 코드가 0곳이었다.
//
// 여기서 못 박는 것: 신호가 오면 다시 묻고, 다시 묻은 결과가 목록에 반영된다.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/announcements/announcements_state.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';

import 'fakes.dart';

Map<String, dynamic> _ann(int id, String title) => {
  'id': id,
  'title': title,
  'body': '$title 본문',
  'priority': 'normal',
  'pinned': false,
  'category': 'notice',
  'visible_to': 'all',
  'created_at': '2026-08-29T10:0$id:00+09:00',
};

void main() {
  test('공지 신호가 오면 서버에 다시 물어 새 공지가 목록에 들어온다', () async {
    SharedPreferences.setMockInitialValues({});
    final rows = <Map<String, dynamic>>[_ann(1, '첫 공지')];
    final api = FakeApi({'/api/v1/member/announcements': rows});
    final repo = GymRepository(api);
    final changed = StreamController<void>.broadcast();
    final state = AnnouncementsState();

    await state.bind(repo, 1, changed: changed.stream);
    expect(state.items.map((a) => a.title), ['첫 공지']);

    // 코치가 PC 에서 새 공지를 올렸다 — 서버 목록이 바뀌고 SSE 가 온다.
    rows.insert(0, _ann(2, '두 번째 공지'));
    changed.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(state.items.map((a) => a.title), ['두 번째 공지', '첫 공지'],
        reason: '신호 없이는 영영 안 보이던 자리 — 이제 그 자리에서 갱신된다');
    await changed.close();
    state.dispose();
  });

  test('같은 체육관에 다시 묶여도(셸 재빌드) 목록이 비어 있지 않으면 조용히', () async {
    SharedPreferences.setMockInitialValues({});
    final rows = <Map<String, dynamic>>[_ann(1, '첫 공지')];
    final api = FakeApi({'/api/v1/member/announcements': rows});
    final repo = GymRepository(api);
    final state = AnnouncementsState();
    await state.bind(repo, 1);
    // 서버가 바뀌었지만 신호 없이 같은 체육관에 다시 묶이는 것만으로는 안 묻는다
    // (셸이 재빌드될 때마다 서버를 두드리지 않는다).
    rows.insert(0, _ann(2, '두 번째 공지'));
    await state.bind(repo, 1);
    expect(state.items.map((a) => a.title), ['첫 공지']);
    // 다른 체육관이면 다시 묻는다.
    await state.bind(repo, 2);
    expect(state.items.map((a) => a.title), ['두 번째 공지', '첫 공지']);
    state.dispose();
  });
}
