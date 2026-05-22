// Brief Phase 4 — 코치 폰 페어링. 사장이 PC 에서 발급한 코드 입력 → device_hash 등록.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

class CoachPairScreen extends StatefulWidget {
  const CoachPairScreen({super.key});

  @override
  State<CoachPairScreen> createState() => _CoachPairScreenState();
}

class _CoachPairScreenState extends State<CoachPairScreen> {
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
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _result = null;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final data = await api.post('/api/v1/coach/pair', {'pairing_code': code});
      setState(() {
        _result = '${data['name']} (${data['role']}) · ${data['gym_name']}';
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
        title: Text('코치 페어링', style: FacingTokens.h3),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('사장이 발급한 페어링 코드 8자리를 입력하세요.', style: FacingTokens.body),
            const SizedBox(height: FacingTokens.sp1),
            Text('한 번만 사용 가능. 이후 이 폰 = 코치 권한.',
                style: FacingTokens.caption),
            const SizedBox(height: FacingTokens.sp4),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'XXXXXXXX',
                filled: true,
                fillColor: FacingTokens.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                  borderSide: BorderSide(color: FacingTokens.border),
                ),
              ),
              style: FacingTokens.h2.copyWith(letterSpacing: 4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FacingTokens.sp3),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.accent,
                padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
              ),
              child: Text(_busy ? '...' : '페어링 등록',
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
                child: Text('✓ 페어링 완료: $_result',
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
