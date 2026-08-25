import 'package:flutter/foundation.dart';

import '../../core/exception.dart';
import '../../models/achievement.dart';
import 'achievement_repository.dart';
import '../../core/app_clock.dart';

/// v1.16: Achievement 전역 상태.
/// - `snapshot`: GET /achievements 결과
/// - `check()`: POST /check 호출 → 신규 해금 반환 (UI toast 재료)
/// - `lastCheckedAt`: 세션당 1회 제한용 캐시
///
/// v1.20 Phase 2.5: `demoUnlockedCodes` 제거 (B-LW-13).
/// Panel B 20-title (titles_catalog.dart + PanelBUnlocker)이 클라이언트 추론을 담당.
/// Achievement 시스템은 백엔드 trigger 응답(`unlocked` 맵)만 신뢰.
class AchievementState extends ChangeNotifier {
  final AchievementRepository repo;
  AchievementState(this.repo);

  bool isUnlockedInUi(String code) => _snapshot.isUnlocked(code);

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
    return appClock.now().difference(t).inMinutes < 10;
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
      // 예외 원문은 사용자에게 보이지 않는다 — 로그로만 (2026-08-23).
      debugPrint('[AchievementState.load] $e');
      _error = '업적을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 새 해금 트리거 후 호출. 신규 해금 목록 반환.
  /// throttle=true면 10분 내 중복 차단.
  ///
  /// v3.3 (2026-08-20): 서버 응답의 newly 만으로는 부족해졌다 — 리워드 규칙
  /// 해금은 서버 훅(출석 기록·기록 저장·코치 승인) 시점에 이미 일어나 /check
  /// 응답에 안 실린다. 재로딩 후 이전 스냅샷과 **diff** 해서 새로 나타난
  /// 해금을 합쳐 돌려준다 (토스트·컨페티 재료).
  Future<List<AchievementUnlockResult>> check({bool throttle = false}) async {
    if (throttle && _checkThrottled) return const [];
    try {
      final before = _snapshot;
      final beforeLoaded = before.catalog.isNotEmpty;
      final newly = await repo.check();
      _lastCheckedAt = appClock.now();
      await load();
      if (!beforeLoaded) return newly; // 첫 로드 — 과거 해금 전체를 토스트하지 않음
      final beforeCodes = before.unlocked.keys.toSet();
      final newlyCodes = newly.map((n) => n.code).toSet();
      final byCode = {for (final c in _snapshot.catalog) c.code: c};
      final merged = [...newly];
      for (final code in _snapshot.unlocked.keys) {
        if (beforeCodes.contains(code) || newlyCodes.contains(code)) continue;
        final cat = byCode[code];
        merged.add(
          AchievementUnlockResult(
            code: code,
            name: cat?.name ?? code,
            rarity: cat?.rarity ?? 'Common',
          ),
        );
      }
      return merged;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return const [];
    } catch (e) {
      // QA B-EX-7: 일반 예외도 사용자에게 알림.
      _error = '업적 확인 실패. 잠시 후 다시 시도.';
      notifyListeners();
      debugPrint('[AchievementState.check] $e');
      return const [];
    }
  }
}
