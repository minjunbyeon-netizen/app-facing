import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../gym/gym_state.dart';

/// Coach 모드 진입 직후 박스 등록.
/// Skip 시 mode 는 coach 유지, 박스 없는 상태로 메인 진입 (나중에 box_wod 에서 등록 가능).
class CreateGymScreen extends StatefulWidget {
  const CreateGymScreen({super.key});

  @override
  State<CreateGymScreen> createState() => _CreateGymScreenState();
}

class _CreateGymScreenState extends State<CreateGymScreen> {
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Haptic.medium();
    setState(() => _creating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await context.read<GymState>().createGym(
            name: name,
            location: _locCtrl.text.trim(),
          );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushNamedAndRemoveUntil('/shell', (_) => false);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.read<GymState>().error ?? '박스 생성 실패.'),
          ),
        );
      }
    } on AppException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('박스 생성 실패: ${e.messageKo}')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE BOX'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp2),
              const Text('박스 등록', style: FacingTokens.h2),
              const SizedBox(height: FacingTokens.sp2),
              const Text(
                '코치가 자기 박스를 만들고 WOD 를 게시할 수 있습니다.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp5),
              TextField(
                controller: _nameCtrl,
                enabled: !_creating,
                decoration: const InputDecoration(
                  labelText: 'Box Name',
                  hintText: '예: FACING SEONGSU',
                ),
                maxLength: 80,
              ),
              const SizedBox(height: FacingTokens.sp3),
              TextField(
                controller: _locCtrl,
                enabled: !_creating,
                decoration: const InputDecoration(
                  labelText: 'Location (선택)',
                  hintText: '예: 서울 성수동',
                ),
                maxLength: 200,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _creating ? null : _create,
                child: Text(_creating ? 'Creating.' : 'Create Box'),
              ),
              const SizedBox(height: FacingTokens.sp2),
              TextButton(
                onPressed: _creating
                    ? null
                    : () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/shell', (_) => false);
                      },
                child: const Text(
                  'Skip — 나중에 만들기',
                  style: FacingTokens.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
