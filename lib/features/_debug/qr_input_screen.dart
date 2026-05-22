// Debug-only: QR 출석 체크인 (토큰 수동 입력).
// 회의 데모용 — 실 카메라 스캐너는 mobile_scanner 패키지 통합 후 Phase 2 후반.
// kDebugMode 가드는 호출자 책임.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

class QrInputScreen extends StatefulWidget {
  const QrInputScreen({super.key});

  @override
  State<QrInputScreen> createState() => _QrInputScreenState();
}

class _QrInputScreenState extends State<QrInputScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _controller.text.trim();
    if (token.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _result = null;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final data = await api.post('/api/v1/attendances', {'token': token});
      setState(() {
        _result = '${data['member_name']} · ${data['checked_at']}';
      });
    } catch (e) {
      setState(() => _error = '실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(
        backgroundColor: FacingTokens.bg,
        title: Text('QR 체크인 (데모)', style: FacingTokens.h3),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('박스 입구 QR 의 토큰을 입력하세요.', style: FacingTokens.body),
            const SizedBox(height: FacingTokens.sp2),
            Text('사장 PC: /checkin 페이지 QR 아래 표시된 토큰',
                style: FacingTokens.caption),
            const SizedBox(height: FacingTokens.sp4),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'token...',
                filled: true,
                fillColor: FacingTokens.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                  borderSide: BorderSide(color: FacingTokens.border),
                ),
              ),
              style: FacingTokens.body,
            ),
            const SizedBox(height: FacingTokens.sp3),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.accent,
                padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
              ),
              child: Text(_busy ? '...' : '출석 체크인',
                  style: FacingTokens.body
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: FacingTokens.sp4),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(FacingTokens.sp3),
                decoration: BoxDecoration(
                  color: FacingTokens.success.withValues(alpha: 0.15),
                  border: Border.all(color: FacingTokens.success),
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                ),
                child: Text('✓ 출석 완료: $_result',
                    style: FacingTokens.body.copyWith(color: FacingTokens.success)),
              ),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(FacingTokens.sp3),
                decoration: BoxDecoration(
                  color: FacingTokens.accent.withValues(alpha: 0.15),
                  border: Border.all(color: FacingTokens.accent),
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                ),
                child: Text(_error!,
                    style: FacingTokens.body.copyWith(color: FacingTokens.accent)),
              ),
          ],
        ),
      ),
    );
  }
}
