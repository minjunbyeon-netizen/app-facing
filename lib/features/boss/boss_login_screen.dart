import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/hkit.dart';
import 'boss_api_client.dart';
import 'boss_auth_state.dart';

/// PHASE5 §1.1 — 스태프(코치·매니저·사장) 폰 로그인 화면.
/// 2026-08-12: 코치=사장 권한 확정 (사용자 결정). 백엔드 admin_login 은 role 무제한이고
/// dashboard 는 @require_role(["boss","coach"]) 라 코치도 원래 들어왔으나, 화면 라벨이
/// '사장'이라 코치가 자기 입구를 못 찾던 문제를 라벨로만 해소 (라우트 /boss/login 은 유지).
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
                // ─── 헤더 (v1.29: 로그인 화면 통일 — BrandLogo 220, DESIGN-SSOT §6) ───
                const Center(child: BrandLogo()),
                const SizedBox(height: HyphenTokens.sp5),
                Text('코치 로그인', style: HyphenTokens.h1),
                const SizedBox(height: HyphenTokens.sp1),
                Text(
                  'PC 어드민과 동일 계정으로 로그인.',
                  style: HyphenTokens.caption,
                ),
                const SizedBox(height: HyphenTokens.sp6),

                // ─── ID 필드 ─────────────────────────────────────────
                _FieldLabel('아이디'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _idCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  // 힌트가 옛 데모 계정(boss_seongsu)이라 실계정으로 오인됨 (2026-08-18)
                  decoration: _inputDeco('coach'),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '아이디를 입력해 주세요.' : null,
                ),
                const SizedBox(height: HyphenTokens.sp3),

                // ─── PW 필드 ─────────────────────────────────────────
                _FieldLabel('비밀번호'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _pwCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: _inputDeco('••••').copyWith(
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

                // ─── 에러 메시지 ──────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: HyphenTokens.sp3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: HyphenTokens.sp3,
                        vertical: HyphenTokens.sp2),
                    decoration: BoxDecoration(
                      color: HyphenTokens.danger.withValues(alpha:0.12),
                      border: Border.all(
                          color: HyphenTokens.danger.withValues(alpha:0.4)),
                    ),
                    child: Text(
                      _error!,
                      style: HyphenTokens.caption
                          .copyWith(color: HyphenTokens.danger),
                    ),
                  ),
                ],

                const SizedBox(height: HyphenTokens.sp6),

                // ─── 로그인 버튼 (v1.29: 테마 ElevatedButton = CTA 유일 규격) ───
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
          borderSide:
              const BorderSide(color: HyphenTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          borderSide: const BorderSide(color: HyphenTokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          borderSide:
              const BorderSide(color: HyphenTokens.danger, width: 1.5),
        ),
        errorStyle: HyphenTokens.micro.copyWith(color: HyphenTokens.danger),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => HkSectionLabel(text);
}

// v1.29: _PrimaryButton 폐기 — CTA 는 테마 ElevatedButton 유일 규격 (DESIGN-SSOT §5).
