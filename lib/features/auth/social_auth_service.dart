import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/device_id.dart';

/// 서버가 결정하는 역할 (D26). boss 는 폰 보조 운영(BossAuthState) 경로로,
/// coach·member·solo 는 [AppMode] 폰 shell 로 분기된다.
enum SocialRole {
  boss,
  coach,
  member,
  solo;

  /// 폰 shell 모드 매핑. boss 는 별도 경로라 null.
  AppMode? toAppMode() => switch (this) {
        SocialRole.coach => AppMode.coach,
        SocialRole.member => AppMode.member,
        SocialRole.solo => AppMode.solo,
        SocialRole.boss => null,
      };
}

/// D26 (2026-06-03) — 소셜 로그인 통일 추상화 층.
///
/// 회원·코치·사장 전원 네이버·구글 로그인. 현재는 [StubSocialAuthService]
/// (가짜 버튼) 가 기본. 실 OAuth 활성화는 [RealSocialAuthService] 1개를
/// 끼우면 끝 — 화면·라우팅 코드는 인터페이스에만 의존하므로 변경 0줄.
///
/// 실 OAuth 계약 (Phase 2):
/// 1. 앱이 provider SDK 로 Authorization Code + PKCE 흐름 수행 → id_token/access_token 획득
/// 2. 백엔드 `POST /api/v1/auth/social` 에 토큰 전달 → 서버가 검증·계정 upsert·role 결정
/// 3. 응답으로 [SocialAuthResult] (role 포함) 수신 → 앱이 자동 분기
enum SocialProvider {
  naver,
  google;

  String get wireName => name; // 'naver' | 'google' — 백엔드 전달용
}

/// 로그인 결과 계약. role 한 줄이 자동 분기의 핵심.
class SocialAuthResult {
  final SocialProvider provider;

  /// 백엔드가 부여하는 안정 식별자 (provider + uid 조합으로 계정 unique).
  final String providerUid;
  final String displayName;
  final String? email;

  /// 서버가 결정한 역할. 박스에 사장/코치/회원으로 연결됐으면 그 역할,
  /// 아무 박스에도 안 엮였으면 [SocialRole.solo].
  final SocialRole role;

  const SocialAuthResult({
    required this.provider,
    required this.providerUid,
    required this.displayName,
    required this.role,
    this.email,
  });
}

/// 로그인 실패 (사용자 취소·네트워크·토큰 검증 실패).
class SocialAuthException implements Exception {
  final String message;
  final String code;
  const SocialAuthException(this.message, this.code);
  @override
  String toString() => 'SocialAuthException($code): $message';
}

/// 갈아끼우기 지점. 화면은 이 인터페이스에만 의존한다.
abstract class SocialAuthService {
  Future<SocialAuthResult> signIn(SocialProvider provider);
}

/// 현재 기본 구현 — 가짜 버튼. 실제 OAuth 통신 0.
///
/// provider 탭 → 즉시 성공한 것처럼 결과 반환. role 은 [AppMode.solo]
/// (신규 계정 = 아직 어느 박스에도 안 엮임). 코치·회원·사장 데모 진입은
/// 별도 DEMO ACCOUNTS 버튼이 담당 (백엔드 페르소나 시드).
class StubSocialAuthService implements SocialAuthService {
  const StubSocialAuthService();

  @override
  Future<SocialAuthResult> signIn(SocialProvider provider) async {
    // 실 OAuth 의 네트워크 지연을 흉내내 UX 일관성만 맞춤.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return SocialAuthResult(
      provider: provider,
      providerUid: 'stub-${provider.wireName}',
      displayName: switch (provider) {
        SocialProvider.naver => 'Naver User',
        SocialProvider.google => 'Google User',
      },
      role: SocialRole.solo,
    );
  }
}

/// 실 OAuth 구현 (D26 Phase 2). provider SDK 로 토큰 획득 →
/// `POST /api/v1/auth/social` 서버 검증 → 응답 role 로 [SocialAuthResult] 반환.
///
/// 활성화: `--dart-define=USE_REAL_AUTH=true` ([resolveSocialAuthService]).
/// google id_token 은 server client id 필요 → `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
/// 네이버는 AndroidManifest meta-data(client id/secret/name) 설정 필요.
/// 화면·라우팅은 [SocialAuthService] 인터페이스에만 의존 → 교체 외 변경 0줄.
class RealSocialAuthService implements SocialAuthService {
  final ApiClient _api;
  const RealSocialAuthService(this._api);

  /// google id_token 발급용 server(web) client id. 미지정 시 빈 문자열.
  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  // 네이버 키 — 빌드 시 --dart-define 으로 주입 (안드로이드 manifest 설정 불필요).
  static const String _naverClientId = String.fromEnvironment('NAVER_CLIENT_ID');
  static const String _naverClientSecret =
      String.fromEnvironment('NAVER_CLIENT_SECRET');
  static const String _naverClientName =
      String.fromEnvironment('NAVER_CLIENT_NAME', defaultValue: 'FACING');
  static const String _naverUrlScheme =
      String.fromEnvironment('NAVER_URL_SCHEME', defaultValue: 'facing');

  @override
  Future<SocialAuthResult> signIn(SocialProvider provider) async {
    final token = switch (provider) {
      SocialProvider.google => await _googleToken(),
      SocialProvider.naver => await _naverToken(),
    };
    final deviceId = await DeviceIdService.get();
    try {
      final data = await _api.post('/api/v1/auth/social', {
        'provider': provider.wireName,
        'token': token,
        'device_id': deviceId,
      });
      final user = (data['user'] as Map?) ?? const {};
      return SocialAuthResult(
        provider: provider,
        providerUid: (user['id'] ?? '').toString(),
        displayName: (user['display_name'] ?? '').toString(),
        email: user['email'] as String?,
        role: _roleFromString(data['role'] as String?),
      );
    } catch (e) {
      throw SocialAuthException('로그인에 실패했습니다.', 'SOCIAL_BACKEND');
    }
  }

  SocialRole _roleFromString(String? r) => switch (r) {
        'boss' => SocialRole.boss,
        'coach' => SocialRole.coach,
        'member' => SocialRole.member,
        _ => SocialRole.solo,
      };

  Future<String> _googleToken() async {
    final google = GoogleSignIn(
      scopes: const ['email'],
      serverClientId:
          _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
    final account = await google.signIn();
    if (account == null) {
      throw const SocialAuthException('로그인을 취소했습니다.', 'CANCELLED');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const SocialAuthException('구글 토큰을 받지 못했습니다.', 'NO_TOKEN');
    }
    return idToken;
  }

  Future<String> _naverToken() async {
    await NaverLoginSDK.initialize(
      urlScheme: _naverUrlScheme,
      clientId: _naverClientId,
      clientSecret: _naverClientSecret,
      clientName: _naverClientName,
    );
    final completer = Completer<void>();
    NaverLoginSDK.login(
      callback: OAuthLoginCallback(
        onSuccess: () {
          if (!completer.isCompleted) completer.complete();
        },
        onFailure: (httpStatus, message) {
          if (!completer.isCompleted) {
            completer.completeError(
              SocialAuthException('네이버 로그인 실패.', 'NAVER_$httpStatus'),
            );
          }
        },
        onError: (errorCode, message) {
          if (!completer.isCompleted) {
            completer.completeError(
              const SocialAuthException('로그인을 취소했습니다.', 'CANCELLED'),
            );
          }
        },
      ),
    );
    await completer.future;
    final accessToken = await NaverLoginSDK.getAccessToken();
    if (accessToken.isEmpty) {
      throw const SocialAuthException('네이버 토큰을 받지 못했습니다.', 'NO_TOKEN');
    }
    return accessToken;
  }
}

/// 실 OAuth 활성 스위치. 키·네이티브 설정 완료 후 빌드 플래그 한 줄로 전환.
///   flutter run --dart-define=USE_REAL_AUTH=true
const bool kUseRealSocialAuth =
    bool.fromEnvironment('USE_REAL_AUTH', defaultValue: false);

/// 화면이 호출하는 단일 진입점. 플래그에 따라 stub ↔ real 자동 선택.
SocialAuthService resolveSocialAuthService(ApiClient api) =>
    kUseRealSocialAuth ? RealSocialAuthService(api) : const StubSocialAuthService();
