import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/fkit.dart';
import '../boss/boss_auth_state.dart';

/// D26 §4.1 — 코치·사장 계정 연결 (전환기 claim).
///
/// 소셜 로그인(보통 role=solo) 후, 기존 코치/사장 login_id + PW 를 1회 입력해
/// `POST /api/v1/auth/link-staff` 로 본인 확인 → 소셜계정에 연결. 이후 소셜
/// 로그인만으로 자동 boss/coach 분기. 설계: services/facing/docs/AUTH_SOCIAL_DESIGN.md.
///
/// 세션은 메인 [ApiClient] 의 쿠키 보관(소셜 로그인 시 발급)으로 전달된다.
class StaffLinkScreen extends StatefulWidget {
  const StaffLinkScreen({super.key});

  @override
  State<StaffLinkScreen> createState() => _StaffLinkScreenState();
}

class _StaffLinkScreenState extends State<StaffLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _busy = false;
  bool _pwVisible = false;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    Haptic.medium();
    final api = context.read<ApiClient>();
    final bossAuth = context.read<BossAuthState>();
    final navigator = Navigator.of(context);
    try {
      final data = await api.post('/api/v1/auth/link-staff', {
        'login_id': _idCtrl.text.trim(),
        'password': _pwCtrl.text,
      });
      final role = (data['role'] ?? 'solo').toString();
      // 사장: 소셜 세션을 BossAuthState 로 넘겨 재로그인 없이 대시보드 진입.
      // (서버는 link 시 admin_* 세션 bridge 를 이미 세팅 → 같은 쿠키로 admin endpoint 인가됨)
      if (role == 'boss') {
        await _activateBoss(api, bossAuth, data);
        if (!mounted) return;
        Haptic.heavy();
        navigator.pushNamedAndRemoveUntil('/boss/dashboard', (_) => false);
        return;
      }
      if (!mounted) return;
      Haptic.heavy();
      _routeByRole(navigator, role);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // UNAUTHORIZED = 소셜 세션 없음(먼저 로그인 안 함).
        _error = e.code == 'UNAUTHORIZED'
            ? '네이버·구글 로그인 후 연결 가능.'
            : e.messageKo;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '연결 실패. 백엔드 재시도.';
      });
    }
  }

  /// 사장 연결 — link 응답 + 소셜 세션 쿠키로 BossAuthState 채움.
  /// 이후 BossApiClient 가 같은 세션을 실어 보내고, main.dart 리스너가 staffPush 시작.
  Future<void> _activateBoss(
      ApiClient api, BossAuthState bossAuth, Map<String, dynamic> data) async {
    final user = (data['user'] as Map?) ?? const {};
    final gyms = (data['gyms'] as List?) ?? const [];
    final primary = gyms.isNotEmpty ? (gyms.first as Map) : const {};
    final cookie = await api.sessionCookie() ?? '';
    await bossAuth.save(
      loginId: 'social:${user['id']}',
      name: (user['display_name'] ?? '').toString(),
      role: 'boss',
      gymId: (primary['gym_id'] as num?)?.toInt() ?? 0,
      gymName: (primary['name'] ?? '').toString(),
      csrfToken: (data['csrf_token'] ?? '').toString(),
      sessionCookie: cookie,
    );
  }

  /// 연결 성공 후 새 role 로 분기 (boss 는 _link 에서 _activateBoss 로 처리).
  /// coach·member 는 폰 shell 로. boss 가 여기 오면(이론상 X) /boss/login 폴백.
  void _routeByRole(NavigatorState navigator, String role) {
    if (role == 'boss') {
      navigator.pushNamedAndRemoveUntil('/boss/login', (_) => false);
      return;
    }
    final mode = switch (role) {
      'coach' => AppMode.coach,
      'member' => AppMode.member,
      _ => AppMode.solo,
    };
    AppModeStore.set(mode);
    navigator.pushNamedAndRemoveUntil('/shell', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(
        backgroundColor: FacingTokens.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FacingTokens.fg),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp5, vertical: FacingTokens.sp4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: FacingTokens.sp3),
                // v1.29: 로그인 계열 화면 통일 — BrandLogo 220 (DESIGN-SSOT §6).
                const Center(child: BrandLogo()),
                const SizedBox(height: FacingTokens.sp5),
                Text('직원 계정 연결', style: FacingTokens.h1),
                const SizedBox(height: FacingTokens.sp2),
                Text(
                  '기존 코치·사장 아이디와 비밀번호로 한 번만 연결하면,\n'
                  '다음부터는 소셜 로그인만으로 코치·사장으로 들어와요.',
                  style: FacingTokens.caption,
                ),
                const SizedBox(height: FacingTokens.sp6),

                _FieldLabel('아이디'),
                const SizedBox(height: FacingTokens.sp1),
                TextFormField(
                  controller: _idCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: _inputDeco('coach_park'),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '아이디를 입력해 주세요.' : null,
                ),
                const SizedBox(height: FacingTokens.sp3),

                _FieldLabel('비밀번호'),
                const SizedBox(height: FacingTokens.sp1),
                TextFormField(
                  controller: _pwCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: _inputDeco('••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _pwVisible ? Icons.visibility_off : Icons.visibility,
                        color: FacingTokens.muted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _pwVisible = !_pwVisible),
                    ),
                  ),
                  obscureText: !_pwVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _link(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                ),

                if (_error != null) ...[
                  const SizedBox(height: FacingTokens.sp3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: FacingTokens.sp3,
                        vertical: FacingTokens.sp2),
                    decoration: BoxDecoration(
                      color: FacingTokens.danger.withValues(alpha: 0.12),
                      border: Border.all(
                          color: FacingTokens.danger.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _error!,
                      style: FacingTokens.caption
                          .copyWith(color: FacingTokens.danger),
                    ),
                  ),
                ],

                const SizedBox(height: FacingTokens.sp6),
                _busy
                    ? const FkLoading()
                    : ElevatedButton(
                        onPressed: _link, child: const Text('계정 연결')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: FacingTokens.body.copyWith(color: FacingTokens.mutedStrong),
        filled: true,
        fillColor: FacingTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp3, vertical: FacingTokens.sp3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          borderSide: const BorderSide(color: FacingTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          borderSide: const BorderSide(color: FacingTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          borderSide: const BorderSide(color: FacingTokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          borderSide: const BorderSide(color: FacingTokens.danger, width: 1.5),
        ),
        errorStyle: FacingTokens.micro.copyWith(color: FacingTokens.danger),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => FkSectionLabel(text);
}

// v1.29: _PrimaryButton 폐기 — CTA 는 테마 ElevatedButton 유일 규격 (DESIGN-SSOT §5).
