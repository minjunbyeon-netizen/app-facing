import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/exception.dart';
import '../../core/sse_client.dart';
import '../../models/gym.dart';
import 'gym_repository.dart';

/// v1.15.3: 박스 소속 + 오늘 WOD 전역 상태.
/// PHASE5: SSE 자동 갱신 — PC 사장이 회원·membership·클래스 등 변경하면 즉시 reload.
class GymState extends ChangeNotifier {
  final GymRepository repo;
  final SseClient? sse;
  StreamSubscription<SseEvent>? _sseSub;
  Timer? _debounceReload;
  GymState(this.repo, {this.sse}) {
    _bindSse();
  }

  /// PC 사장이 변경할 때 폰이 자동 reload 해야 하는 이벤트 type 들.
  /// 백엔드 sse_publish 호출 위치와 1:1 매핑.
  static const _reloadTriggers = <String>{
    'member.created',
    'member.updated',
    'member.decided',
    'member.left',
    'member.self_left',
    'membership.issued',
    'membership.extended',
    'membership.cancelled',
    'membership.cancel_scheduled',
    'wod.posted',
    'announcement.posted',
    'class_cancelled',
    'member_promoted_from_waitlist',
  };

  void _bindSse() {
    if (sse == null) return;
    _sseSub = sse!.events.listen((ev) {
      final hit = _reloadTriggers.contains(ev.type);
      debugPrint('[GymState] sse event=${ev.type} reload=${hit ? "YES" : "skip"}');
      if (hit) {
        _debounceReload?.cancel();
        _debounceReload = Timer(const Duration(seconds: 1), () {
          debugPrint('[GymState] reload trigger → loadMine()');
          loadMine().then((_) {
            debugPrint('[GymState] reload done');
          }).catchError((e) {
            debugPrint('[GymState] reload failed: $e');
          });
        });
      }
    }, onError: (e) {
      debugPrint('[GymState] sse error: $e');
    });
  }

  @override
  void dispose() {
    _debounceReload?.cancel();
    _sseSub?.cancel();
    super.dispose();
  }

  GymMembership _membership = GymMembership.empty;
  List<GymWodPost> _wods = const [];
  bool _loading = false;
  String? _error;

  GymMembership get membership => _membership;
  /// v1.21: 박스 전체 기간 WOD (kbox 스타일 날짜 그룹용).
  List<GymWodPost> get wods => _wods;
  /// 오늘 날짜 매치 — 기존 호출처 호환.
  List<GymWodPost> get todayWods =>
      _wods.where((w) => w.postDate == todayIso).toList();
  bool get isLoading => _loading;
  String? get error => _error;

  bool get isOwner => _membership.isOwner;
  bool get hasGym => _membership.hasGym;

  String get todayIso {
    // QA B-TZ-3: 박스 WOD 날짜 기준은 KST. UTC 사용 시 자정 전후 9시간 오차.
    final now = DateTime.now().toLocal();
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
        // v1.21: 날짜 필터 제거 — 박스 전체 기간 WOD 로드 후 클라이언트에서 그룹.
        _wods = await repo.listWods(gymId: _membership.gym!.id);
      } else {
        _wods = const [];
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
    // v1.19 차수 5 (B-ST-3): 시작 시 _error 초기화로 stale error 표시 방지.
    _error = null;
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
    _error = null;
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

  Future<bool> leaveGym() async {
    final gym = _membership.gym;
    if (gym == null || isOwner) return false;
    _error = null;
    try {
      await repo.leaveGym(gym.id);
      _membership = GymMembership.empty;
      _wods = const [];
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  /// v1.22: 체육관 부가정보 저장. 성공 시 _membership 갱신 + notifyListeners.
  Future<bool> updateGymProfile({
    String? phone,
    String? coachName,
    String? coachBio,
    String? classSchedule,
    String? motto,
    String? instagram,
  }) async {
    final gym = _membership.gym;
    if (gym == null || !isOwner) return false;
    _error = null;
    try {
      final newProfile = await repo.updateGymProfile(
        gymId: gym.id,
        phone: phone,
        coachName: coachName,
        coachBio: coachBio,
        classSchedule: classSchedule,
        motto: motto,
        instagram: instagram,
      );
      final updatedGym = GymSummary(
        id: gym.id,
        name: gym.name,
        location: gym.location,
        memberCount: gym.memberCount,
        isOfficial: gym.isOfficial,
        ownerHash: gym.ownerHash,
        profile: newProfile,
      );
      _membership = GymMembership(
        gym: updatedGym,
        role: _membership.role,
        status: _membership.status,
      );
      notifyListeners();
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
    String? scaledVersion,
    String? beginnerVersion,
    String? scaleGuide,
    List<WodRoundItem> roundsData = const [],
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
        scaledVersion: scaledVersion,
        beginnerVersion: beginnerVersion,
        scaleGuide: scaleGuide,
        roundsData: roundsData,
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
