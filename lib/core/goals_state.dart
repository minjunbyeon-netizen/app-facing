// v1.16 Sprint 13: 성장 목표 관리.
// Persona P1/P2/P3/P4 공통 요구: 주간/월간/PR 목표 한곳에서 추적.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalsState extends ChangeNotifier {
  static const _kWeeklySessions = 'goal_weekly_sessions_v1';
  static const _kMonthlySessions = 'goal_monthly_sessions_v1';
  static const _kFranPrSec = 'goal_fran_pr_sec_v1';
  static const _kBackSquatKg = 'goal_back_squat_kg_v1';
  static const _kTargetTierLabel = 'goal_target_tier_v1';
  static const _kSeasonGoal = 'goal_season_text_v1';

  int _weeklyTargetSessions = 4;
  int _monthlyTargetSessions = 16;
  int _franPrSec = 120; // 2:00 default
  double _backSquatKg = 0;
  String _targetTier = 'RX+';
  String _seasonGoal = '';

  int get weeklyTargetSessions => _weeklyTargetSessions;
  int get monthlyTargetSessions => _monthlyTargetSessions;
  int get franPrSec => _franPrSec;
  double get backSquatKg => _backSquatKg;
  String get targetTier => _targetTier;
  String get seasonGoal => _seasonGoal;

  String get franPrDisplay {
    final m = _franPrSec ~/ 60;
    final s = _franPrSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _weeklyTargetSessions = prefs.getInt(_kWeeklySessions) ?? 4;
    _monthlyTargetSessions = prefs.getInt(_kMonthlySessions) ?? 16;
    _franPrSec = prefs.getInt(_kFranPrSec) ?? 120;
    _backSquatKg = prefs.getDouble(_kBackSquatKg) ?? 0;
    _targetTier = prefs.getString(_kTargetTierLabel) ?? 'RX+';
    _seasonGoal = prefs.getString(_kSeasonGoal) ?? '';
    notifyListeners();
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

  Future<void> setTargetTier(String t) async {
    _targetTier = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTargetTierLabel, t);
    notifyListeners();
  }

  Future<void> setSeasonGoal(String s) async {
    _seasonGoal = s.substring(0, s.length > 200 ? 200 : s.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSeasonGoal, _seasonGoal);
    notifyListeners();
  }
}
