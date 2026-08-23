// v1.16 Sprint 13: 성장 목표 관리.
// Persona P1/P2/P3/P4 공통 요구: 주간/월간/PR 목표 한곳에서 추적.
//
// v3.11 (2026-08-23): **서버 저장 배선.** 종전엔 SharedPreferences 에만 있어
// 폰을 바꾸거나 앱을 지우면 목표가 초기값으로 돌아갔다 (목표 화면이 스스로
// "이 기기에 저장됩니다" 라고 고지하던 상태). 회원 기록(출석·수업·PR)은 전부
// 서버에 있는데 목표만 기기에 남아 있던 비대칭을 없앤다.
//
// 저장 규칙:
//  - 로컬(prefs)은 **캐시**다. 서버가 정본이고, 오프라인·서버 실패 시에도
//    화면이 비지 않도록 항상 같이 쓴다.
//  - 값 변경(set*)은 로컬 저장 + 화면 갱신까지만 한다. 서버 전송은 [sync] 를
//    부르는 쪽(슬라이더 놓는 순간·다이얼로그 확정·시즌 목표 저장)이 정한다.
//    슬라이더 onChanged 는 드래그 내내 수십 번 불려 그대로 보내면 요청 폭주다.
//    Timer 디바운스를 쓰지 않는 이유는 골든 테스트의 pending timer 회피.
//  - 진행률(주간·월간 세션 수)은 여기 없다 — 서버 히스토리에서 세는 값이라
//    저장하면 두 곳이 어긋난다 (§0-B).

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class GoalsState extends ChangeNotifier {
  GoalsState({ApiClient? api}) : _api = api;

  /// 서버 연동용. null 이면 로컬 전용으로 동작한다 (테스트·미배선 경로).
  ApiClient? _api;
  set api(ApiClient? v) => _api = v;

  static const _path = '/api/v1/member/me/goals';

  static const _kWeeklySessions = 'goal_weekly_sessions_v1';
  static const _kMonthlySessions = 'goal_monthly_sessions_v1';
  static const _kFranPrSec = 'goal_fran_pr_sec_v1';
  static const _kBackSquatKg = 'goal_back_squat_kg_v1';
  // v3.2 (2026-08-20): targetTier 삭제 — '목표 Tier' UI 소멸 (README §제거된 기능 대장).
  // 구 prefs 키 'goal_target_tier_v1' 은 읽지 않고 방치 (무해).
  static const _kSeasonGoal = 'goal_season_text_v1';
  // v3.12 (2026-08-23): 착용 칭호가 여기로 들어왔다. 종전 WornTitleStore 는
  // 로컬 전용이라 폰을 바꾸면 착용이 풀렸다 — 목표와 성격이 같아(회원이
  // 스스로 고르는 값·체육관 무관) 같은 행·같은 창구로 합친다 (§0-B).
  static const _kWornTitle = 'worn_title_code_v1';

  int _weeklyTargetSessions = 4;
  int _monthlyTargetSessions = 16;
  int _franPrSec = 120; // 2:00 default
  double _backSquatKg = 0;
  String _seasonGoal = '';
  String _wornTitle = '';

  /// 마지막 서버 저장이 실패했는지. 화면이 "이 기기에만 저장됨" 안내를
  /// 띄울지 판단하는 데 쓴다.
  bool _serverDown = false;
  bool get isServerDown => _serverDown;

  int get weeklyTargetSessions => _weeklyTargetSessions;
  int get monthlyTargetSessions => _monthlyTargetSessions;
  int get franPrSec => _franPrSec;
  double get backSquatKg => _backSquatKg;
  String get seasonGoal => _seasonGoal;
  /// 착용 칭호 code. 빈 문자열이면 착용 안 함.
  String get wornTitle => _wornTitle;

  String get franPrDisplay {
    final m = _franPrSec ~/ 60;
    final s = _franPrSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// 로컬 캐시를 먼저 올리고, 서버 값이 오면 덮어쓴다.
  /// 서버가 죽어 있어도 화면은 캐시로 뜬다.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _weeklyTargetSessions = prefs.getInt(_kWeeklySessions) ?? 4;
    _monthlyTargetSessions = prefs.getInt(_kMonthlySessions) ?? 16;
    _franPrSec = prefs.getInt(_kFranPrSec) ?? 120;
    _backSquatKg = prefs.getDouble(_kBackSquatKg) ?? 0;
    _seasonGoal = prefs.getString(_kSeasonGoal) ?? '';
    _wornTitle = prefs.getString(_kWornTitle) ?? '';
    notifyListeners();
    await pull();
  }

  /// 서버 값 가져오기. 실패는 삼킨다 — 목표는 없어도 앱이 도는 값이고,
  /// 여기서 예외를 던지면 앱 부팅이 서버 상태에 묶인다.
  Future<void> pull() async {
    final api = _api;
    if (api == null) return;
    try {
      final data = await api.get(_path);
      _weeklyTargetSessions = _asInt(data['weekly_sessions'], _weeklyTargetSessions);
      _monthlyTargetSessions =
          _asInt(data['monthly_sessions'], _monthlyTargetSessions);
      _franPrSec = _asInt(data['fran_pr_sec'], _franPrSec);
      _backSquatKg = _asDouble(data['back_squat_kg'], _backSquatKg);
      _seasonGoal = (data['season_goal'] ?? _seasonGoal).toString();
      _wornTitle = (data['worn_title'] ?? _wornTitle).toString();
      _serverDown = false;
      await _cacheAll();
      notifyListeners();
    } catch (_) {
      _serverDown = true;
      notifyListeners();
    }
  }

  /// 현재 값을 서버에 통째로 올린다. 슬라이더를 놓는 순간·다이얼로그 확정·
  /// 시즌 목표 저장에서 부른다 (드래그 중에는 부르지 않는다).
  Future<void> sync() async {
    final api = _api;
    if (api == null) return;
    try {
      await api.put(_path, {
        'weekly_sessions': _weeklyTargetSessions,
        'monthly_sessions': _monthlyTargetSessions,
        'fran_pr_sec': _franPrSec,
        'back_squat_kg': _backSquatKg,
        'season_goal': _seasonGoal,
        'worn_title': _wornTitle,
      });
      if (_serverDown) {
        _serverDown = false;
        notifyListeners();
      }
    } catch (_) {
      // 로컬 캐시에는 이미 들어가 있다 — 다음 sync·pull 에서 만회한다.
      _serverDown = true;
      notifyListeners();
    }
  }

  static int _asInt(Object? v, int fallback) =>
      v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);

  static double _asDouble(Object? v, double fallback) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? fallback);

  Future<void> _cacheAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeeklySessions, _weeklyTargetSessions);
    await prefs.setInt(_kMonthlySessions, _monthlyTargetSessions);
    await prefs.setInt(_kFranPrSec, _franPrSec);
    await prefs.setDouble(_kBackSquatKg, _backSquatKg);
    await prefs.setString(_kSeasonGoal, _seasonGoal);
    await prefs.setString(_kWornTitle, _wornTitle);
  }

  Future<void> setWeeklyTarget(int n) async {
    _weeklyTargetSessions = n.clamp(1, 14);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeeklySessions, _weeklyTargetSessions);
    notifyListeners();
  }

  Future<void> setMonthlyTarget(int n) async {
    _monthlyTargetSessions = n.clamp(1, 40);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMonthlySessions, _monthlyTargetSessions);
    notifyListeners();
  }

  Future<void> setFranPrSec(int sec) async {
    _franPrSec = sec.clamp(60, 600);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFranPrSec, _franPrSec);
    notifyListeners();
  }

  Future<void> setBackSquatKg(double kg) async {
    _backSquatKg = kg.clamp(0, 400);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBackSquatKg, _backSquatKg);
    notifyListeners();
  }

  /// 칭호 착용·해제. 고른 즉시 서버로 보낸다 — 목표 슬라이더와 달리
  /// 연타가 아니라 한 번의 선택이라 디바운스가 필요 없다.
  Future<void> setWornTitle(String code) async {
    _wornTitle = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWornTitle, _wornTitle);
    notifyListeners();
    await sync();
  }

  Future<void> setSeasonGoal(String s) async {
    _seasonGoal = s.substring(0, s.length > 200 ? 200 : s.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSeasonGoal, _seasonGoal);
    notifyListeners();
  }
}
