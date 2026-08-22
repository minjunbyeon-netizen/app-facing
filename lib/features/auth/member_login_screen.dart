import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/device_id.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/hkit.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';
import 'auth_state.dart';

/// 회원 아이디·비밀번호 로그인 (2026-08-12 신설).
///
/// 그동안 회원 신원은 기기에 저장된 device_id 하나뿐이라, 앱을 지우거나 폰을
/// 바꾸면 남의 기기에서 같은 회원으로 들어올 방법이 없었다. 서버가 login_id ↔
/// device_id 를 이어 주는 `POST /api/v1/auth/member-login` 을 붙이고, 여기서
/// 받은 device_id 를 [DeviceIdService.adopt] 로 채택한다. 이후 모든 회원 API 는
/// 기존과 똑같이 X-Device-Id 헤더로 동작한다.
class MemberLoginScreen extends StatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  State<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends State<MemberLoginScreen> {
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

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    Haptic.medium();

    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final profile = context.read<ProfileState>();
    final navigator = Navigator.of(context);
    GymState? gymState;
    try {
      gymState = context.read<GymState>();
    } catch (_) {}

    try {
      final data = await api.post('/api/v1/auth/member-login', {
        'login_id': _idCtrl.text.trim(),
        'password': _pwCtrl.text,
      });
      final deviceId = data['device_id']?.toString() ?? '';
      if (deviceId.isEmpty) {
        throw AppException('로그인 응답이 올바르지 않습니다.', code: 'NO_DEVICE_ID');
      }
      // 이 기기의 신원을 로그인한 회원으로 교체.
      await DeviceIdService.adopt(deviceId);
      await auth.signIn('member_id',
          displayName: data['name']?.toString() ?? _idCtrl.text.trim());

      // 박스 소속·프로필 미리 불러오기 (실패해도 진입은 막지 않는다).
      try {
        await gymState?.loadMine();
      } catch (_) {}
      try {
        await profile.load();
      } catch (_) {}

      if (!mounted) return;
      Haptic.heavy();
      // 박스 승인 회원은 곧장 홈으로. 온보딩(7단계)은 페이싱 등급 산정용이라
      // 쪽지·와드·수업 예약과는 무관하다 — 로그인 직후 붙잡아 두지 않는다.
      // v2.3: 등급(Tier) 유무로 온보딩에 붙잡던 분기 제거 — 성별·경력은 가입
      // 직후 한 번만 묻는다. 로그인한 사람은 승인 여부와 무관하게 홈으로.
      navigator.pushNamedAndRemoveUntil('/shell', (_) => false);
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
                const SizedBox(height: HyphenTokens.sp3),
                const Center(child: BrandLogo()),
                const SizedBox(height: HyphenTokens.sp5),
                Text('회원 로그인', style: HyphenTokens.h1),
                const SizedBox(height: HyphenTokens.sp1),
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
                // v2.3 (2026-08-12 사용자 지시): 회원 화면에서 코치·사장 진입
                // 줄을 내렸다 (로그인 첫 화면과 같은 처리). /boss/login 라우트는
                // 그대로 살아 있다 — 필요해지면 이 자리에 다시 놓으면 된다.
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
