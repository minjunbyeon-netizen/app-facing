import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/announcement.dart';
import '../gym/gym_repository.dart';

class AnnouncementsState extends ChangeNotifier {
  static const _kLastSeenKey = 'ann_last_seen_at_ms';

  List<GymAnnouncement> _items = const [];
  int _unreadCount = 0;
  int? _boundGymId;

  int get unreadCount => _unreadCount;
  int? get boundGymId => _boundGymId;
  // v1.25: 회원 대화 화면 상단 공지 핀용 — 최신순 목록 노출.
  List<GymAnnouncement> get items => _items;

  Future<void> bind(GymRepository repo, int gymId) async {
    if (_boundGymId == gymId && _items.isNotEmpty) return;
    _boundGymId = gymId;
    await refresh(repo);
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
    await prefs.setInt(_kLastSeenKey, DateTime.now().millisecondsSinceEpoch);
    _unreadCount = 0;
    notifyListeners();
  }
}
