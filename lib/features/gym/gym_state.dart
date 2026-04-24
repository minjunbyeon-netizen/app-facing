import 'package:flutter/foundation.dart';

import '../../core/exception.dart';
import '../../models/gym.dart';
import 'gym_repository.dart';

/// v1.15.3: 박스 소속 + 오늘 WOD 전역 상태.
class GymState extends ChangeNotifier {
  final GymRepository repo;
  GymState(this.repo);

  GymMembership _membership = GymMembership.empty;
  List<GymWodPost> _todayWods = const [];
  bool _loading = false;
  String? _error;

  GymMembership get membership => _membership;
  List<GymWodPost> get todayWods => _todayWods;
  bool get isLoading => _loading;
  String? get error => _error;

  bool get isOwner => _membership.isOwner;
  bool get hasGym => _membership.hasGym;

  String get todayIso {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadMine() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _membership = await repo.getMine();
      if (_membership.gym != null &&
          (_membership.isOwner || _membership.isApprovedMember)) {
        _todayWods = await repo.listWods(
          gymId: _membership.gym!.id,
          date: todayIso,
        );
      } else {
        _todayWods = const [];
      }
    } on AppException catch (e) {
      _error = e.messageKo;
    } catch (e) {
      _error = '불러오기 실패: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createGym({
    required String name,
    String location = '',
  }) async {
    try {
      await repo.createGym(name: name, location: location);
      await loadMine();
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinGym(int gymId) async {
    try {
      await repo.join(gymId);
      await loadMine();
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  Future<bool> decideMember({
    required int memberId,
    required String action,
  }) async {
    final gym = _membership.gym;
    if (gym == null || !isOwner) return false;
    try {
      await repo.decideMember(
        gymId: gym.id,
        memberId: memberId,
        action: action,
      );
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  Future<bool> postWod({
    required String postDate,
    required String wodType,
    required String content,
    int? rounds,
    int? timeCapSec,
  }) async {
    final gym = _membership.gym;
    if (gym == null || !isOwner) return false;
    try {
      await repo.postWod(
        gymId: gym.id,
        postDate: postDate,
        wodType: wodType,
        content: content,
        rounds: rounds,
        timeCapSec: timeCapSec,
      );
      await loadMine();
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWod(int wodId) async {
    final gym = _membership.gym;
    if (gym == null || !isOwner) return false;
    try {
      await repo.deleteWod(gymId: gym.id, wodId: wodId);
      await loadMine();
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }
}
