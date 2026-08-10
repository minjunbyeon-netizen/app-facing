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
import '../gym/gym_state.dart';

/// 이음새 1 (백엔드 api/claim.py) — 가입 코드 입력.
///
/// 사장이 PC 에서 선등록한 회원이 받은 6자리 코드를 입력하면
/// `POST /api/v1/member/claim` 으로 선등록 행이 이 폰의 device_hash 를
/// 흡수한다 (회원권·계약·쪽지가 이 폰으로 연결). DESIGN-SSOT §6 양식.
class ClaimCodeScreen extends StatefulWidget {
  const ClaimCodeScreen({super.key});

  @override
  State<ClaimCodeScreen> createState() => _ClaimCodeScreenState();
}

class _ClaimCodeScreenState extends State<ClaimCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6자리 코드를 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    Haptic.medium();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    GymState? gymState;
    try {
      gymState = context.read<GymState>();
    } catch (_) {}
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await api.post('/api/v1/member/claim', {'code': code});
      await AppModeStore.set(AppMode.member);
      try {
        await gymState?.loadMine();
      } catch (_) {}
      if (!mounted) return;
      final gymName = (data['gym_name'] ?? '박스').toString();
      messenger.showSnackBar(
        SnackBar(content: Text('$gymName 연결 완료.')),
      );
      Haptic.heavy();
      // v1.33 (2026-08-10): 코드 연결 성공 = 이 기기가 선등록 회원 행을 흡수 —
      // 신원이 확정된 상태다. 예전엔 미로그인 진입이면 로그인 화면으로 되돌려
      // 보냈는데, 소셜 버튼을 내린 지금은 그게 막다른 길이 된다.
      if (!auth.isSignedIn) {
        // 백엔드 응답 필드는 `name` (api/claim.py). 조기 반환 경로엔 없어 빈 값 방어.
        final memberName = (data['name'] ?? '').toString();
        await auth.signIn('claim',
            displayName: memberName.isEmpty ? null : memberName);
      }
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil('/shell', (_) => false);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.messageKo;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '연결 실패. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(title: const Text('가입 코드')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp3),
              Text('가입 코드 입력', style: FacingTokens.h1),
              const SizedBox(height: FacingTokens.sp2),
              Text(
                '박스에서 받은 6자리 코드를 입력하면\n'
                '등록된 회원권·계약이 이 폰으로 연결됩니다.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp6),
              const FkSectionLabel('코드'),
              const SizedBox(height: FacingTokens.sp1),
              TextField(
                controller: _codeCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: FacingTokens.h2.copyWith(fontFeatures: FacingTokens.tabular),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  hintStyle: FacingTokens.h2.copyWith(
                      color: FacingTokens.mutedStrong),
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
                    borderSide: const BorderSide(
                        color: FacingTokens.primary, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: FacingTokens.sp3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: FacingTokens.sp3, vertical: FacingTokens.sp2),
                  decoration: BoxDecoration(
                    color: FacingTokens.danger.withValues(alpha: 0.12),
                    border: Border.all(
                        color: FacingTokens.danger.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
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
                      onPressed: _submit, child: const Text('연결')),
              const SizedBox(height: FacingTokens.sp3),
              Text(
                '코드가 없으면 박스 사장님께 발급을 요청해 주세요. 7일간 유효합니다.',
                style: FacingTokens.micro,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
