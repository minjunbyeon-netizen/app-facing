import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/announcement.dart';
import '../gym/gym_repository.dart';
import '../../core/app_clock.dart';

class AnnouncementsState extends ChangeNotifier {
  static const _kLastSeenKey = 'ann_last_seen_at_ms';

  List<GymAnnouncement> _items = const [];
  int _unreadCount = 0;
  int? _boundGymId;
  StreamSubscription<void>? _changedSub;

  int get unreadCount => _unreadCount;
  int? get boundGymId => _boundGymId;
  // v1.25: 회원 대화 화면 상단 공지 핀용 — 최신순 목록 노출.
  List<GymAnnouncement> get items => _items;

  /// D79 (2026-08-29) — 묶일 때 **항상** 다시 묻는다. 종전엔 "이미 묶였고 목록이
  /// 있으면" 건너뛰어, 한 번 받은 목록이 앱을 껐다 켜기 전까지 굳었다.
  /// `changed` 를 주면(GymState.announcementsChanged) 코치가 PC 에서 공지를
  /// 올릴 때마다 서버에 다시 묻는다 — 새로고침 없이 폰에 뜬다.
  Future<void> bind(GymRepository repo, int gymId, {Stream<void>? changed}) async {
    final rebinding = _boundGymId == gymId;
    _boundGymId = gymId;
    if (changed != null) {
      await _changedSub?.cancel();
      _changedSub = changed.listen((_) => refresh(repo));
    }
    // 같은 체육관에 다시 묶이는 경우(셸 재빌드)엔 이미 구독이 있으니 조용히.
    if (!rebinding || _items.isEmpty) await refresh(repo);
  }

  @override
  void dispose() {
    _changedSub?.cancel();
    super.dispose();
  }

  Future<void> refresh(GymRepository repo) async {
    try {
      final items = await repo.listMemberAnnouncements();
      final prefs = await SharedPreferences.getInstance();
      final lastSeenMs = prefs.getInt(_kLastSeenKey) ?? 0;
      _items = items;
      _unreadCount = items
          .where((a) => a.createdAt.millisecondsSinceEpoch > lastSeenMs)
          .length;
      notifyListeners();
    } catch (_) {
      // silent — 배지 실패해도 앱 동작 영향 X
    }
  }

  Future<void> markSeen() async {
    if (_unreadCount == 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSeenKey, appClock.now().millisecondsSinceEpoch);
    _unreadCount = 0;
    notifyListeners();
  }
}
