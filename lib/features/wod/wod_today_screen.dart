import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../gym/gym_state.dart';

/// PHASE5 §D-6 — 회원 폰 오늘 WOD 화면.
/// 사장이 PC class-templates 페이지에서 배치한 DailyClassPlan 들을 시간순으로 표시.
class WodTodayScreen extends StatefulWidget {
  const WodTodayScreen({super.key});

  @override
  State<WodTodayScreen> createState() => _WodTodayScreenState();
}

class _WodTodayScreenState extends State<WodTodayScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiClient>();
    int? gid;
    try {
      final gs = context.read<GymState>();
      // membership 의 gym.id 사용 (옛 코드 패턴)
      gid = (gs as dynamic).membership?.gym?.id as int?;
    } catch (_) {}
    if (gid == null) {
      setState(() { _loading = false; _error = '소속 박스 없음'; });
      return;
    }
    try {
      final res = await api.get('/api/v1/member/gyms/$gid/daily-plans');
      final list = (res['items'] as List?) ?? [];
      setState(() {
        _plans = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false; _error = null;
      });
    } catch (e) {
      setState(() { _loading = false; _error = '오늘 WOD 가져오기 실패'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(
        backgroundColor: FacingTokens.bg,
        elevation: 0,
        title: Text("Today's WOD.", style: FacingTokens.h3),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: FacingTokens.primary,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: FacingTokens.primary))
            : _error != null
                ? Center(child: Text(_error!, style: FacingTokens.body))
                : _plans.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              children: [
                                Text('No WOD today.',
                                    style: FacingTokens.h3),
                                const SizedBox(height: FacingTokens.sp2),
                                Text('박스에서 오늘 일정 배치 전이에요.',
                                    style: FacingTokens.caption),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(FacingTokens.sp4),
                        itemCount: _plans.length,
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: FacingTokens.sp3),
                        itemBuilder: (_, i) {
                          final p = _plans[i];
                          final hour = p['plan_hour'] as int? ?? 0;
                          return Container(
                            padding: const EdgeInsets.all(FacingTokens.sp4),
                            decoration: BoxDecoration(
                              color: FacingTokens.surface,
                              border:
                                  Border.all(color: FacingTokens.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${hour.toString().padLeft(2, "0")}:00',
                                      style: FacingTokens.h2.copyWith(
                                          color: FacingTokens.primary),
                                    ),
                                    const SizedBox(width: FacingTokens.sp3),
                                    Expanded(
                                      child: Text(
                                        (p['wod_title'] ?? '').toString(),
                                        style: FacingTokens.body.copyWith(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((p['wod_description'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: FacingTokens.sp2),
                                  Text(p['wod_description'].toString(),
                                      style: FacingTokens.caption),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
