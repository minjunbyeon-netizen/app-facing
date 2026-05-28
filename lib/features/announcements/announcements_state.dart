import 'package:flutter/foundation.dart';
// ignore: unused_import
import 'package:flutter/material.dart';
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
      debugPrint('[Ann] fetched=${items.length} unread=$_unreadCount lastSeenMs=$lastSeenMs');
      notifyListeners();
    } catch (e) {
      debugPrint('[Ann] refresh error: $e');
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
