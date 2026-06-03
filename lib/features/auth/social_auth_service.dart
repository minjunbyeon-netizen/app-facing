import '../../core/app_mode.dart';

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
