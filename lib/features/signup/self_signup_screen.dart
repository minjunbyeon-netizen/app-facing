import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';

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
        _error = '박스 목록 불러오기 실패. 잠시 후 다시 시도해 주세요.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final gym = _selected;
    final name = _nameCtrl.text.trim();
    if (gym == null) {
      _toast('박스를 먼저 선택해 주세요.');
      return;
    }
    if (name.isEmpty) {
      _toast('이름을 입력해 주세요.');
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
          if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      final status = (res['status'] ?? 'pending') as String;
      if (status == 'pending') {
        _showApprovalDialog(gym.name);
      } else {
        _toast('이미 가입된 회원이에요.');
      }
    } catch (e) {
      if (!mounted) return;
      _toast('가입 신청 실패. 잠시 후 다시 시도해 주세요.');
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
          '$gymName 박스에 가입 신청했어요.\n사장님 승인 후 이용할 수 있어요.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed('/home');
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

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('가입할 박스', style: FacingTokens.sectionLabel),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _gyms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final g = _gyms[i];
                final selected = _selected?.id == g.id;
                return InkWell(
                  onTap: () => setState(() => _selected = g),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? FacingTokens.surfaceHigh : FacingTokens.surface,
                      border: Border.all(
                        color: selected ? FacingTokens.primary : FacingTokens.border,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              color: FacingTokens.fg,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: FacingTokens.primary, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('이름 *', style: FacingTokens.sectionLabel),
          const SizedBox(height: 4),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: FacingTokens.fg),
            decoration: InputDecoration(
              hintText: '실명',
              hintStyle: const TextStyle(color: FacingTokens.muted),
              filled: true,
              fillColor: FacingTokens.surface,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: FacingTokens.border),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('전화 (선택)', style: FacingTokens.sectionLabel),
          const SizedBox(height: 4),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: FacingTokens.fg),
            decoration: InputDecoration(
              hintText: '010-0000-0000',
              hintStyle: const TextStyle(color: FacingTokens.muted),
              filled: true,
              fillColor: FacingTokens.surface,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: FacingTokens.border),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                  : const Text('가입 신청',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: FacingTokens.fg, height: 1.5)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
