import 'package:flutter/foundation.dart';

import '../../core/exception.dart';
import '../../models/achievement.dart';
import 'achievement_repository.dart';

/// v1.16: Achievement 전역 상태.
/// - `snapshot`: GET /achievements 결과
/// - `check()`: POST /check 호출 → 신규 해금 반환 (UI toast 재료)
/// - `lastCheckedAt`: 세션당 1회 제한용 캐시
class AchievementState extends ChangeNotifier {
  final AchievementRepository repo;
  AchievementState(this.repo);

  AchievementSnapshot _snapshot = AchievementSnapshot.empty;
  bool _loading = false;
  String? _error;
  DateTime? _lastCheckedAt;

  AchievementSnapshot get snapshot => _snapshot;
  bool get isLoading => _loading;
  String? get error => _error;

  /// 10분 내 재호출 방지 (Profile 탭 들어갈 때마다 중복 호출 방지).
  bool get _checkThrottled {
    final t = _lastCheckedAt;
    if (t == null) return false;
    return DateTime.now().difference(t).inMinutes < 10;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _snapshot = await repo.list();
    } on AppException catch (e) {
      _error = e.messageKo;
    } catch (e) {
      _error = '불러오기 실패: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 새 해금 트리거 후 호출. 신규 해금 목록 반환.
  /// throttle=true면 10분 내 중복 차단.
  Future<List<AchievementUnlockResult>> check({bool throttle = false}) async {
    if (throttle && _checkThrottled) return const [];
    try {
      final newly = await repo.check();
      _lastCheckedAt = DateTime.now();
      if (newly.isNotEmpty) {
        // 해금 반영 후 스냅샷 재로딩.
        await load();
      }
      return newly;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
