import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/fkit.dart';
import '../auth/auth_state.dart';
import '../profile/profile_state.dart';

/// 회원 가입 신청 — 아이디 + 비밀번호(2회)만 받는다.
///
/// v2.3 (2026-08-12 사용자 지시): 이 앱은 **HYPHEN 한 박스 전용**이다. 코치와
/// 회원이 그 안에서 예약·공지를 주고받는 것이 전부라, 박스를 고르거나 번호를
/// 넣는 절차 자체가 없다. 이름·전화·성별은 사장이 승인하면서 채운다.
/// 아이디가 그대로 표시용 이름으로 들어간다.
///
/// 박스 id 는 `/api/v1/member/gyms-list` 에서 이름이 HYPHEN 인 행으로 찾는다
/// (목록이 안 오면 [_kFallbackGymId]). 나중에 박스가 늘어나면 이 화면에
/// 선택 UI 를 되살리는 것이 아니라, 서버가 기본 박스를 내려주게 하면 된다.
///
/// 백엔드: POST /api/v1/member/gyms/`<gid>`/self-signup
///   body {login_id, password} · header X-Device-Id
///   → status='pending' 으로 신청 + MemberCredential 생성 (승인 후 바로 로그인)
const String _kBrandGymName = 'HYPHEN';
const int _kFallbackGymId = 2;

class SelfSignupScreen extends StatefulWidget {
  const SelfSignupScreen({super.key});

  @override
  State<SelfSignupScreen> createState() => _SelfSignupScreenState();
}

class _SelfSignupScreenState extends State<SelfSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  int _gymId = _kFallbackGymId;
  bool _submitting = false;
  bool _pwVisible = false;

  @override
  void initState() {
    super.initState();
    _resolveGym();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  /// 가입 대상 박스를 이름으로 찾는다. 목록을 못 받으면 폴백 id 로 그대로 진행 —
  /// 신청 자체를 막을 이유가 없다 (서버가 없는 박스면 404 로 알려준다).
  Future<void> _resolveGym() async {
    try {
      final api = context.read<ApiClient>();
      final raw = await api.getList('/api/v1/member/gyms-list');
      if (!mounted) return;
      for (final e in raw) {
        if ((e['name'] ?? '') == _kBrandGymName) {
          setState(() => _gymId = (e['id'] as num).toInt());
          return;
        }
      }
    } catch (_) {
      // 폴백 id 유지.
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final gymId = _gymId;
    final loginId = _idCtrl.text.trim();

    setState(() => _submitting = true);
    Haptic.medium();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final profile = context.read<ProfileState>();

    try {
      final res = await api.post(
        '/api/v1/member/gyms/$gymId/self-signup',
        {'login_id': loginId, 'password': _pwCtrl.text},
      );
      if (!mounted) return;
      final status = (res['status'] ?? 'pending') as String;
      final duplicate = res['duplicate'] == true;

      // 가입 신청 성공 = 이 기기의 신원 확정. AuthState 를 세워 두지 않으면
      // 다음 실행 때 splash 가 !isSignedIn 을 보고 로그인 화면으로 되돌린다.
      await auth.signIn('self', displayName: loginId);
      await AppModeStore.set(AppMode.member);
      if (!mounted) return;

      if (duplicate) {
        _toast(status == 'pending'
            ? '이미 승인 대기 중입니다.'
            : '이미 가입된 회원입니다.');
        _goNext(profile);
      } else if (status == 'pending') {
        _showApprovalDialog(_kBrandGymName, profile);
      } else {
        _toast('이미 가입된 회원입니다.');
        _goNext(profile);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      _toast(e.messageKo);
    } catch (_) {
      if (!mounted) return;
      _toast('가입 신청 실패. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showApprovalDialog(String gymName, ProfileState profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surface,
        title: const Text('가입 신청 완료'),
        content: Text(
          '$gymName 에 가입을 신청했습니다.\n코치 승인 후 아이디로 로그인할 수 있습니다.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _goNext(profile);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 가입 직후 목적지. v2.3: 성별·경력 두 가지만 묻는 짧은 화면 하나로 보낸다.
  /// (등급 산정용 신체·벤치마크 단계는 이 흐름에서 뺐다.)
  void _goNext(ProfileState profile) {
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/onboarding/basic', (_) => false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(
        title: const Text('가입 신청'),
        backgroundColor: FacingTokens.bg,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(FacingTokens.sp5,
              FacingTokens.sp4, FacingTokens.sp5, FacingTokens.sp5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FkSectionLabel('아이디'),
                const SizedBox(height: FacingTokens.sp1),
                TextFormField(
                  controller: _idCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: _deco('로그인에 쓸 아이디'),
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9._-]')),
                  ],
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.length < 4) return '아이디는 4자 이상 입력해 주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: FacingTokens.sp4),

                const FkSectionLabel('비밀번호'),
                const SizedBox(height: FacingTokens.sp1),
                TextFormField(
                  controller: _pwCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: _deco('비밀번호').copyWith(
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
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v ?? '').length < 4 ? '비밀번호는 4자 이상 입력해 주세요.' : null,
                ),
                const SizedBox(height: FacingTokens.sp3),
                TextFormField(
                  controller: _pw2Ctrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: _deco('비밀번호 확인'),
                  obscureText: !_pwVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      v != _pwCtrl.text ? '비밀번호가 서로 다릅니다.' : null,
                ),

                const SizedBox(height: FacingTokens.sp6),
                _submitting
                    ? const FkLoading()
                    : FkButton.primary('신청하기', onPressed: _submit),
                const SizedBox(height: FacingTokens.sp3),
                Text(
                  '코치가 승인하면 이 아이디로 로그인할 수 있습니다.',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: FacingTokens.body.copyWith(color: FacingTokens.placeholder),
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
