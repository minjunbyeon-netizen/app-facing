import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';

/// C-1앱 (2026-06-10) — 전화번호 검증·자동 하이픈.
final RegExp _phoneRe = RegExp(r'^01[016789]-?\d{3,4}-?\d{4}$');

class _PhoneHyphenFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return oldValue;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == (digits.length > 10 ? 7 : 6)) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// PHASE5 Sprint1 F4 — 회원 self-signup flow.
///
/// 어플 다운로드 → 로그인 (Naver/Kakao OAuth) → 박스 선택 → 자동 가입 신청.
/// 기존 [SignupScreen] 의 OAuth 단계 이후 진입. 사장이 admin 에서 승인하면 활성화.
///
/// 백엔드 endpoint:
///   - GET  /api/v1/member/gyms-list           (public, 박스 목록)
///   - POST /api/v1/member/gyms/`<gid>`/self-signup
///     headers: X-Device-Id
///     body: {name, phone?, gender?, birth_date?, level?}
class SelfSignupScreen extends StatefulWidget {
  const SelfSignupScreen({super.key});

  @override
  State<SelfSignupScreen> createState() => _SelfSignupScreenState();
}

class _SelfSignupScreenState extends State<SelfSignupScreen> {
  List<_GymOption> _gyms = const [];
  bool _loading = true;
  String? _error;
  _GymOption? _selected;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final raw = await api.getList('/api/v1/member/gyms-list');
      final list = raw
          .map((e) => _GymOption(
                id: (e['id'] as num).toInt(),
                name: (e['name'] ?? '?') as String,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _gyms = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '박스 목록 로드 실패. 잠시 후 재시도.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final gym = _selected;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (gym == null) {
      _toast('박스를 먼저 선택.');
      return;
    }
    if (name.isEmpty) {
      _toast('이름 입력 필수.');
      return;
    }
    // C-1앱: 입력 시 invalid phone 차단 (백엔드 INVALID_PHONE 과 동일 규칙).
    if (phone.isNotEmpty && !_phoneRe.hasMatch(phone)) {
      _toast('전화번호 형식 확인. (예: 010-1234-5678)');
      return;
    }
    setState(() => _submitting = true);
    Haptic.medium();
    try {
      final api = context.read<ApiClient>();
      final res = await api.post(
        '/api/v1/member/gyms/${gym.id}/self-signup',
        {
          'name': name,
          if (phone.isNotEmpty) 'phone': phone,
        },
      );
      if (!mounted) return;
      final status = (res['status'] ?? 'pending') as String;
      final duplicate = res['duplicate'] == true;
      // B-7: 재신청을 신규 신청과 구분 — "또 신청됐다" 오인 방지.
      if (duplicate) {
        if (status == 'pending') {
          _toast('이미 승인 대기 중. 사장 승인 후 이용 가능.');
        } else {
          _toast('이미 가입된 회원.');
          Navigator.of(context).pushReplacementNamed('/shell');
        }
      } else if (status == 'pending') {
        _showApprovalDialog(gym.name);
      } else {
        _toast('이미 가입된 회원.');
      }
    } on AppException catch (e) {
      if (!mounted) return;
      _toast(e.messageKo);
    } catch (e) {
      if (!mounted) return;
      _toast('가입 신청 실패. 잠시 후 재시도.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showApprovalDialog(String gymName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surface,
        title: const Text('가입 신청 완료'),
        content: Text(
          '$gymName 가입 신청 완료.\n사장 승인 후 이용 가능.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // A-4: /home 은 하단 탭 셸 우회 진입 — 표준 진입점 /shell 로.
              Navigator.of(context).pushReplacementNamed('/shell');
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
        title: const Text('박스 선택 · 가입'),
        backgroundColor: FacingTokens.bg,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _loadGyms)
                : _buildBody(),
      ),
    );
  }

  // E-3 (2026-06-10): 하드코드 fontSize·spacing·radius·Colors.white → FacingTokens.
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          FacingTokens.sp5, FacingTokens.sp3, FacingTokens.sp5, FacingTokens.sp5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('가입할 박스', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          Expanded(
            child: ListView.separated(
              itemCount: _gyms.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: FacingTokens.sp2),
              itemBuilder: (_, i) {
                final g = _gyms[i];
                final selected = _selected?.id == g.id;
                return InkWell(
                  onTap: () => setState(() => _selected = g),
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: FacingTokens.sp4,
                        vertical: FacingTokens.sp3 + 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? FacingTokens.surfaceHigh
                          : FacingTokens.surface,
                      border: Border.all(
                        color: selected
                            ? FacingTokens.primary
                            : FacingTokens.border,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(FacingTokens.r2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.name,
                            style: FacingTokens.body.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: FacingTokens.fg,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: FacingTokens.primary, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: FacingTokens.sp4),
          const Text('이름 *', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp1),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: FacingTokens.fg),
            decoration: _inputDeco('실명'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          const Text('전화 (선택)', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp1),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            // C-1앱: 숫자 입력 시 자동 하이픈 (010-1234-5678)
            inputFormatters: [_PhoneHyphenFormatter()],
            style: const TextStyle(color: FacingTokens.fg),
            decoration: _inputDeco('010-0000-0000'),
          ),
          const SizedBox(height: FacingTokens.sp5),
          SizedBox(
            height: FacingTokens.buttonH,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.primary,
                foregroundColor: FacingTokens.onColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FacingTokens.r2)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: FacingTokens.onColor, strokeWidth: 2.4))
                  : Text('가입 신청',
                      style: FacingTokens.body
                          .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: FacingTokens.muted),
        filled: true,
        fillColor: FacingTokens.surface,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: FacingTokens.border),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
      );
}

class _GymOption {
  final int id;
  final String name;
  const _GymOption({required this.id, required this.name});
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: FacingTokens.fg, height: 1.5)),
            const SizedBox(height: FacingTokens.sp4),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
