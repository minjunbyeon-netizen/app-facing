import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/device_id.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/remembered_login.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import '../boss/boss_api_client.dart';
import '../boss/boss_auth_state.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';
import 'auth_state.dart';

/// 로그인 — **창구는 하나다** (v3.19 · 2026-08-25 사용자 지시).
///
/// 사람이 '회원 로그인 / 코치 로그인' 을 골라 들어가는 구조 자체를 없앴다.
/// 아이디·비밀번호만 받고 계정 유형 판정은 **서버**가 한다:
/// `POST /api/v1/auth/login` 이 `kind: coach|member` 를 내려주고, 이 화면은
/// 그 값만 보고 코치 셸(`/boss/dashboard`) 과 회원 셸(`/shell`) 로 가른다.
///
/// - 코치: 응답의 세션 쿠키·CSRF 를 [BossAuthState] 에 저장 (구 BossLoginScreen 몫).
/// - 회원: 응답의 device_id 를 [DeviceIdService.adopt] 로 채택 — 이후 모든 회원
///   API 는 종전대로 X-Device-Id 헤더로 동작한다. 폰이 바뀌어도 같은 기록으로 들어온다.
///
/// 사용자 지시로 이 화면에는 브랜드 로고를 넣지 않는다 (스플래시·진입 화면과 구분).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _busy = false;
  bool _pwVisible = false;
  bool _remember = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 30일 안에 로그인한 적이 있으면 아이디를 채워 둔다 (비밀번호는 저장 안 함).
    RememberedLogin.load().then((id) {
      if (!mounted || id == null) return;
      setState(() {
        _idCtrl.text = id;
        _remember = true;
      });
    });
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    Haptic.medium();

    final loginId = _idCtrl.text.trim();
    final bossApi = context.read<BossApiClient>();
    final bossAuth = context.read<BossAuthState>();
    final auth = context.read<AuthState>();
    final profile = context.read<ProfileState>();
    final navigator = Navigator.of(context);
    GymState? gymState;
    try {
      gymState = context.read<GymState>();
    } catch (_) {}

    try {
      final result = await bossApi.unifiedLogin(loginId, _pwCtrl.text);
      final data = result['data'] as Map<String, dynamic>;
      // 판정은 서버가 한다. 앱은 kind 만 보고 갈라 준다.
      final isCoach = data['kind']?.toString() == 'coach';

      if (isCoach) {
        final gym = data['active_gym'] as Map<String, dynamic>? ?? {};
        await bossAuth.save(
          loginId: data['login_id']?.toString() ?? loginId,
          name: data['name']?.toString() ?? '',
          role: data['role']?.toString() ?? 'coach',
          gymId: (gym['gym_id'] as num?)?.toInt() ?? 0,
          gymName: gym['gym_name']?.toString() ?? '',
          csrfToken: data['csrf_token']?.toString() ?? '',
          sessionCookie: result['session_cookie'] as String? ?? '',
        );
      } else {
        // 창구가 하나가 되면서 같은 폰에서 코치 → 회원 전환이 흔해졌다.
        // 코치 세션(secure storage)을 안 지우면 main.dart 의 staffPush 리스너가
        // 계속 살아 회원이 스태프 알림을 받는다 — 회원으로 들어올 땐 먼저 끊는다.
        if (bossAuth.isLoggedIn) await bossAuth.clear();

        final deviceId = data['device_id']?.toString() ?? '';
        if (deviceId.isEmpty) {
          throw AppException('로그인 응답이 올바르지 않습니다.', code: 'NO_DEVICE_ID');
        }
        // 이 기기의 신원을 로그인한 회원으로 교체.
        await DeviceIdService.adopt(deviceId);
        await auth.signIn('member_id',
            displayName: data['name']?.toString() ?? loginId);

        // 체육관 소속·프로필 미리 불러오기 (실패해도 진입은 막지 않는다).
        try {
          await gymState?.loadMine();
        } catch (_) {}
        try {
          await profile.load();
        } catch (_) {}
      }

      if (_remember) {
        await RememberedLogin.save(loginId);
      } else {
        await RememberedLogin.clear();
      }

      if (!mounted) return;
      Haptic.heavy();
      // 회원: 승인 대기든 활성이든 홈으로. 온보딩(성별·경력)은 가입 직후 한 번만
      // 묻는다 — 로그인한 사람을 다시 붙잡아 두지 않는다 (v2.3).
      navigator.pushNamedAndRemoveUntil(
          isCoach ? '/boss/dashboard' : '/shell', (_) => false);
    } on AppException catch (e) {
      setState(() => _error = e.messageKo);
    } catch (_) {
      setState(() => _error = '연결 실패. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: AppBar(
        backgroundColor: HyphenTokens.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HyphenTokens.fg),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: HyphenTokens.sp5, vertical: HyphenTokens.sp4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: HyphenTokens.sp5),
                // v3.19 사용자 지시 — 이 화면에 브랜드 로고를 넣지 않는다.
                Text('로그인', style: HyphenTokens.h1),
                const SizedBox(height: HyphenTokens.sp1),
                // 역할을 고르게 하지 않는다. 어느 화면으로 갈지는 서버가 판정한다.
                Text('체육관에서 받은 아이디로 로그인합니다.',
                    style: HyphenTokens.caption),
                const SizedBox(height: HyphenTokens.sp6),

                HkSectionLabel('아이디'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _idCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: _inputDeco('아이디'),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? '아이디를 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: HyphenTokens.sp3),

                HkSectionLabel('비밀번호'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _pwCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: _inputDeco('비밀번호').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _pwVisible ? Icons.visibility_off : Icons.visibility,
                        color: HyphenTokens.muted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _pwVisible = !_pwVisible),
                    ),
                  ),
                  obscureText: !_pwVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                ),

                // 아이디 기억 (2026-08-25 사용자 요청) — 비밀번호는 저장 안 함.
                const SizedBox(height: HyphenTokens.sp1),
                Align(
                  alignment: Alignment.centerLeft,
                  child: HkCheckRow(
                    value: _remember,
                    label: '아이디 기억하기 (${RememberedLogin.days}일)',
                    onChanged: (v) => setState(() => _remember = v),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: HyphenTokens.sp3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: HyphenTokens.sp3,
                        vertical: HyphenTokens.sp2),
                    decoration: BoxDecoration(
                      color: HyphenTokens.danger.withValues(alpha: 0.12),
                      border: Border.all(
                          color: HyphenTokens.danger.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _error!,
                      style: HyphenTokens.caption
                          .copyWith(color: HyphenTokens.danger),
                    ),
                  ),
                ],

                const SizedBox(height: HyphenTokens.sp6),
                _busy
                    ? const HkLoading()
                    : ElevatedButton(
                        onPressed: _login, child: const Text('로그인')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: HyphenTokens.body.copyWith(color: HyphenTokens.mutedStrong),
        filled: true,
        fillColor: HyphenTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: HyphenTokens.sp3, vertical: HyphenTokens.sp3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          borderSide: const BorderSide(color: HyphenTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          borderSide: const BorderSide(color: HyphenTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          borderSide: const BorderSide(color: HyphenTokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          borderSide: const BorderSide(color: HyphenTokens.danger, width: 1.5),
        ),
        errorStyle: HyphenTokens.micro.copyWith(color: HyphenTokens.danger),
      );
}
