import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/exception.dart';
import '../../core/notification_service.dart';
import '../../core/sse_client.dart';
import '../../models/coach_profile.dart';
import '../../models/gym.dart';
import '../../models/locker.dart';
import '../../models/membership.dart';
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
    // v1.16.2 (2026-05-24) — 박스 프로필·코치 프로필 변경 → 박스 프로필 화면 자동 reload
    'gym.profile.updated',
    'coach.profile.updated',
    // v1.16.2 — 락커 배정/해제 → MyPage 카드 자동 reload
    'locker.assigned',
    'locker.released',
  };

  void _bindSse() {
    if (sse == null) return;
    _sseSub = sse!.events.listen((ev) {
      final hit = _reloadTriggers.contains(ev.type);
      debugPrint('[GymState] sse event=${ev.type} reload=${hit ? "YES" : "skip"}');
      if (hit) {
        // ⚠ 승인 전 상태는 **이벤트를 받은 즉시** 찍어야 한다. 1초 디바운스 뒤에
        // 읽으면 그 사이 화면 진입 등 다른 경로의 loadMine 이 이미 approved 로
        // 바꿔 놓아서, "대기→승인" 전이를 놓친다 (실측에서 알림이 안 뜬 원인).
        final wasApproved = _membership.isApprovedMember;
        _debounceReload?.cancel();
        _debounceReload = Timer(const Duration(seconds: 1), () {
          debugPrint('[GymState] reload trigger → loadMine()');
          loadMine().then((_) {
            debugPrint('[GymState] reload done');
            // 2026-08-13 — 대기 → 승인 으로 바뀐 순간 회원에게 알림.
            // 이벤트를 그대로 믿지 않고 **내 상태가 실제로 바뀐 것**만 알린다
            // (같은 박스의 다른 사람 승인 이벤트도 같은 채널로 오기 때문).
            debugPrint('[GymState] decided? type=${ev.type} '
                'was=$wasApproved now=${_membership.isApprovedMember}');
            if (ev.type == 'member.decided' &&
                !wasApproved &&
                _membership.isApprovedMember) {
              debugPrint('[GymState] 가입 승인 감지 → 알림');
              NotificationService.instance.showFromSseEvent(
                eventType: 'member.decided',
                payload: {
                  'member_id': _membership.gym?.id,
                  'status': 'approved',
                },
              );
            }
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
  // v1.16.2 (2026-05-24) — 박스 코치 목록. loadMine() 안에서 같이 fetch.
  List<CoachProfile> _coaches = const [];
  // v1.16.2 — 본인 회원권·락커. 폰 MyPage 카드용.
  List<Membership> _myMemberships = const [];
  List<Locker> _myLockers = const [];
  bool _loading = false;
  String? _error;

  GymMembership get membership => _membership;
  /// v1.21: 박스 전체 기간 WOD (kbox 스타일 날짜 그룹용).
  List<GymWodPost> get wods => _wods;
  /// 오늘 날짜 매치 — 기존 호출처 호환.
  List<GymWodPost> get todayWods =>
      _wods.where((w) => w.postDate == todayIso).toList();
  /// v1.16.2 — 박스 코치 목록 (BoxProfileScreen 에서 사용).
  List<CoachProfile> get coaches => _coaches;
  /// v1.16.2 — 본인 회원권 (가장 최근 active 우선).
  List<Membership> get myMemberships => _myMemberships;
  Membership? get currentMembership {
    if (_myMemberships.isEmpty) return null;
    for (final m in _myMemberships) {
      if (m.isActive) return m;
    }
    return _myMemberships.first;
  }
  /// v1.16.2 — 본인 락커.
  List<Locker> get myLockers => _myLockers;
  Locker? get myLocker =>
      _myLockers.isNotEmpty ? _myLockers.first : null;
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
        // v1.16.2 — 코치 목록 동시 fetch (실패해도 wods 결과는 유지)
        try {
          _coaches = await repo.listCoaches(_membership.gym!.id);
        } catch (e) {
          debugPrint('[GymState] listCoaches failed: $e');
          _coaches = const [];
        }
        // v1.16.2 — 본인 회원권·락커 (실패해도 다른 결과는 유지)
        try {
          _myMemberships = await repo.listMyMemberships();
        } catch (e) {
          debugPrint('[GymState] listMyMemberships failed: $e');
          _myMemberships = const [];
        }
        try {
          _myLockers = await repo.listMyLockers();
        } catch (e) {
          debugPrint('[GymState] listMyLockers failed: $e');
          _myLockers = const [];
        }
      } else {
        _wods = const [];
        _coaches = const [];
        _myMemberships = const [];
        _myLockers = const [];
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
  /// v1.16.2 (2026-05-24) — 박스 프로필 페이지 9 필드 추가.
  Future<bool> updateGymProfile({
    String? phone,
    String? coachName,
    String? coachBio,
    String? classSchedule,
    String? motto,
    String? instagram,
    String? priceSummary,
    String? paymentMethods,
    String? receiptInfo,
    String? parkingInfo,
    String? firstVisitGuide,
    String? attireGuide,
    String? wifiInfo,
    String? contactKakao,
    String? freeNotice,
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
        priceSummary: priceSummary,
        paymentMethods: paymentMethods,
        receiptInfo: receiptInfo,
        parkingInfo: parkingInfo,
        firstVisitGuide: firstVisitGuide,
        attireGuide: attireGuide,
        wifiInfo: wifiInfo,
        contactKakao: contactKakao,
        freeNotice: freeNotice,
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
