import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 전역 kg/lb 단위 토글. 저장값(백엔드·로컬)은 항상 lb/kg 원본 유지.
/// UI 표시·입력 변환에만 영향.
class UnitState extends ChangeNotifier {
  static const _key = 'unit_is_kg';
  static const double _kgPerLb = 0.45359237;

  bool _isKg = true;
  bool _loaded = false;

  bool get isKg => _isKg;
  bool get isLoaded => _loaded;
  String get weightSuffix => _isKg ? 'kg' : 'lb';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isKg = prefs.getBool(_key) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setIsKg(bool value) async {
    if (_isKg == value) return;
    _isKg = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
  }

  Future<void> toggle() => setIsKg(!_isKg);

  /// lb 기준 저장값을 현재 단위로 표시용 변환.
  double? lbToDisplay(double? lbValue) {
    if (lbValue == null) return null;
    return _isKg ? lbValue * _kgPerLb : lbValue;
  }

  /// 사용자가 현재 단위로 입력한 값을 lb 기준 저장값으로 변환.
  double? displayToLb(double? displayValue) {
    if (displayValue == null) return null;
    return _isKg ? displayValue / _kgPerLb : displayValue;
  }

  /// kg 기준 저장값을 현재 단위로 표시용 변환.
  double? kgToDisplay(double? kgValue) {
    if (kgValue == null) return null;
    return _isKg ? kgValue : kgValue / _kgPerLb;
  }

  /// 사용자가 현재 단위로 입력한 값을 kg 기준 저장값으로 변환.
  double? displayToKg(double? displayValue) {
    if (displayValue == null) return null;
    return _isKg ? displayValue : displayValue * _kgPerLb;
  }
}
