import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import 'boss_api_client.dart';
import 'boss_auth_state.dart';

/// PHASE5 §1.1 — 사장·매니저 폰 로그인 화면.
/// ID/PW → POST /api/v1/admin/login → BossAuthState 저장 → /boss/dashboard
class BossLoginScreen extends StatefulWidget {
  const BossLoginScreen({super.key});

  @override
  State<BossLoginScreen> createState() => _BossLoginScreenState();
}

class _BossLoginScreenState extends State<BossLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl  = TextEditingController();
  final _pwCtrl  = TextEditingController();
  bool _busy    = false;
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
    setState(() { _busy = true; _error = null; });
    Haptic.medium();

    final api   = context.read<BossApiClient>();
    final auth  = context.read<BossAuthState>();

    try {
      final result = await api.login(_idCtrl.text.trim(), _pwCtrl.text);
      final data   = result['data'] as Map<String, dynamic>;
      final cookie = result['session_cookie'] as String? ?? '';

      final gym = data['active_gym'] as Map<String, dynamic>? ?? {};
      await auth.save(
        loginId:       data['login_id']?.toString() ?? '',
        name:          data['name']?.toString()     ?? '',
        role:          data['role']?.toString()     ?? 'boss',
        gymId:         (gym['gym_id'] as num?)?.toInt() ?? 0,
        gymName:       gym['gym_name']?.toString()  ?? '',
        csrfToken:     data['csrf_token']?.toString() ?? '',
        sessionCookie: cookie,
      );

      if (!mounted) return;
      Haptic.heavy();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/boss/dashboard', (_) => false,
      );
    } on AppException catch (e) {
      setState(() { _error = e.messageKo; });
    } catch (e) {
      setState(() { _error = '연결 실패. 백엔드 재시도.'; });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
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
                // ─── 헤더 ───────────────────────────────────────────
                Text('FACING', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp1),
                Text('Boss Login.', style: FacingTokens.h1),
                const SizedBox(height: FacingTokens.sp1),
                Text(
                  'PC 어드민과 동일 계정으로 로그인.',
                  style: FacingTokens.caption,
                ),
                const SizedBox(height: FacingTokens.sp6),

                // ─── ID 필드 ─────────────────────────────────────────
                _FieldLabel('ID'),
                const SizedBox(height: FacingTokens.sp1),
                TextFormField(
                  controller: _idCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: _inputDeco('boss_seongsu'),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'ID 필수' : null,
                ),
                const SizedBox(height: FacingTokens.sp3),

                // ─── PW 필드 ─────────────────────────────────────────
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
                  onFieldSubmitted: (_) => _login(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password 필수' : null,
                ),

                // ─── 에러 메시지 ──────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: FacingTokens.sp3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: FacingTokens.sp3,
                        vertical: FacingTokens.sp2),
                    decoration: BoxDecoration(
                      color: FacingTokens.danger.withValues(alpha:0.12),
                      border: Border.all(
                          color: FacingTokens.danger.withValues(alpha:0.4)),
                    ),
                    child: Text(
                      _error!,
                      style: FacingTokens.caption
                          .copyWith(color: FacingTokens.danger),
                    ),
                  ),
                ],

                const SizedBox(height: FacingTokens.sp6),

                // ─── 로그인 버튼 ──────────────────────────────────────
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
                    : _PrimaryButton(label: 'Login', onTap: _login),
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
          borderSide:
              const BorderSide(color: FacingTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: FacingTokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              const BorderSide(color: FacingTokens.danger, width: 1.5),
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
