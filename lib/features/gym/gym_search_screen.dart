import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import 'gym_repository.dart';
import 'gym_state.dart';

/// v1.15.3: 박스 검색 + 가입 신청.
class GymSearchScreen extends StatefulWidget {
  const GymSearchScreen({super.key});

  @override
  State<GymSearchScreen> createState() => _GymSearchScreenState();
}

class _GymSearchScreenState extends State<GymSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;
  List<GymSummary> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<GymRepository>().search(q);
      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.messageKo;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '검색 실패: $e';
        _loading = false;
      });
    }
  }

  Future<void> _join(GymSummary gym) async {
    Haptic.medium();
    // v1.19 차수 5 (B-ST-9): 이미 소속된 박스 재가입 요청 차단.
    final state = context.read<GymState>();
    final currentGym = state.membership.gym;
    if (currentGym != null && currentGym.id == gym.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 소속된 박스.')),
      );
      return;
    }
    if (currentGym != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('다른 박스 소속 중. 먼저 탈퇴.')),
      );
      return;
    }
    final ok = await state.joinGym(gym.id);
    if (!mounted) return;
    if (ok) {
      final msg = gym.isOfficial
          ? '${gym.name} · 가입 완료. 오늘의 WOD 확인 가능.'
          : '${gym.name} · 가입 요청 전송. 코치 승인 대기.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<GymState>().error ?? '가입 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FIND BOX')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              child: TextField(
                controller: _ctrl,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  labelText: '박스 이름 검색',
                  prefixIcon: Icon(Icons.search, color: FacingTokens.muted),
                ),
                autofocus: true,
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(FacingTokens.sp4),
                child: CircularProgressIndicator(
                    color: FacingTokens.muted, strokeWidth: 2),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: Text(_error!, style: FacingTokens.caption),
              )
            else
              Expanded(
                child: _results.isEmpty
                    ? const Center(
                        child: Text('검색 결과 없음', style: FacingTokens.caption),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: FacingTokens.sp4),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(
                            height: 1, color: FacingTokens.border),
                        itemBuilder: (_, i) {
                          final g = _results[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    g.name,
                                    style: FacingTokens.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (g.isOfficial) ...[
                                  const SizedBox(width: FacingTokens.sp2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: FacingTokens.sp1,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: FacingTokens.accent, width: 1),
                                      borderRadius: BorderRadius.circular(
                                          FacingTokens.r1),
                                    ),
                                    child: Text(
                                      'OFFICIAL',
                                      style: FacingTokens.micro.copyWith(
                                        color: FacingTokens.accent,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              g.isOfficial
                                  ? '공식 박스 · 즉시 승인 · 오늘의 WOD 제공'
                                  : (g.location.isEmpty
                                      ? '${g.memberCount} members'
                                      : '${g.location} · ${g.memberCount} members'),
                              style: FacingTokens.caption,
                            ),
                            trailing: TextButton(
                              onPressed: () => _join(g),
                              child: Text(g.isOfficial ? 'Join' : 'Request'),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
