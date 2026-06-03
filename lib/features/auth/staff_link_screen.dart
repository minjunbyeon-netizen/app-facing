import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';

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
    final navigator = Navigator.of(context);
    try {
      final data = await api.post('/api/v1/auth/link-staff', {
        'login_id': _idCtrl.text.trim(),
        'password': _pwCtrl.text,
      });
      if (!mounted) return;
      Haptic.heavy();
      _routeByRole(navigator, (data['role'] ?? 'solo').toString());
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // UNAUTHORIZED = 소셜 세션 없음(먼저 로그인 안 함).
        _error = e.code == 'UNAUTHORIZED'
            ? '먼저 네이버·구글로 로그인한 뒤 연결해주세요.'
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

  /// 연결 성공 후 새 role 로 분기 (signup _routeByRole 과 동일 규칙).
  /// boss 는 사장 대시보드용 BossAuthState 가 별도라 /boss/login 으로 보내
  /// 세션을 확립(전환기). coach·member 는 폰 shell 로.
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
                Text('FACING', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp1),
                Text('Link Staff.', style: FacingTokens.h1),
                const SizedBox(height: FacingTokens.sp2),
                Text(
                  '기존 코치·사장 아이디와 비밀번호로 한 번만 연결하면,\n'
                  '다음부터는 소셜 로그인만으로 코치·사장으로 들어와요.',
                  style: FacingTokens.caption,
                ),
                const SizedBox(height: FacingTokens.sp6),

                _FieldLabel('ID'),
                const SizedBox(height: FacingTokens.sp1),
                TextFormField(
                  controller: _idCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: _inputDeco('coach_park'),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'ID 필수' : null,
                ),
                const SizedBox(height: FacingTokens.sp3),

                _FieldLabel('Password'),
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
                      (v == null || v.isEmpty) ? 'Password 필수' : null,
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
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FacingTokens.primary,
                          ),
                        ),
                      )
                    : _PrimaryButton(label: 'Link Account', onTap: _link),
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
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: FacingTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: FacingTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: FacingTokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: FacingTokens.danger, width: 1.5),
        ),
        errorStyle: FacingTokens.micro.copyWith(color: FacingTokens.danger),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: FacingTokens.sectionLabel,
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp4),
        color: FacingTokens.primary,
        alignment: Alignment.center,
        child: Text(
          label,
          style: FacingTokens.h3.copyWith(
            color: FacingTokens.onColor,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
