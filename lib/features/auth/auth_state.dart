import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v1.16: 데모 회원가입 상태.
/// 실제 OAuth 통신은 Phase 2 — MVP는 Naver/Kakao 버튼 탭 시 provider 기록만.
class AuthState extends ChangeNotifier {
  static const _kSignedIn = 'auth_signed_in';
  static const _kProvider = 'auth_provider'; // naver | kakao | demo
  static const _kDisplayName = 'auth_display_name';
  static const _kSignedAt = 'auth_signed_at';

  bool _signedIn = false;
  String? _provider;
  String? _displayName;
  DateTime? _signedAt;

  bool get isSignedIn => _signedIn;
  String? get provider => _provider;
  String? get displayName => _displayName;
  DateTime? get signedAt => _signedAt;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _signedIn = prefs.getBool(_kSignedIn) ?? false;
    _provider = prefs.getString(_kProvider);
    _displayName = prefs.getString(_kDisplayName);
    final ts = prefs.getString(_kSignedAt);
    _signedAt = ts == null ? null : DateTime.tryParse(ts);
    notifyListeners();
  }

  /// v1.16 데모: provider 버튼 탭 → 로컬 저장만. 실제 OAuth 토큰 교환 X.
  Future<void> signIn(String provider, {String? displayName}) async {
    final prefs = await SharedPreferences.getInstance();
    _signedIn = true;
    _provider = provider;
    _displayName = displayName ?? _defaultName(provider);
    _signedAt = DateTime.now();
    await prefs.setBool(_kSignedIn, true);
    await prefs.setString(_kProvider, provider);
    await prefs.setString(_kDisplayName, _displayName!);
    await prefs.setString(_kSignedAt, _signedAt!.toIso8601String());
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    _signedIn = false;
    _provider = null;
    _displayName = null;
    _signedAt = null;
    await prefs.remove(_kSignedIn);
    await prefs.remove(_kProvider);
    await prefs.remove(_kDisplayName);
    await prefs.remove(_kSignedAt);
    notifyListeners();
  }

  String _defaultName(String provider) {
    switch (provider) {
      case 'naver':
        return 'Naver User';
      case 'kakao':
        return 'Kakao User';
      default:
        return 'Athlete';
    }
  }
}
