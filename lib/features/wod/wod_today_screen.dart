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
      backgroundColor: HyphenTokens.bg,
      appBar: AppBar(
        backgroundColor: HyphenTokens.bg,
        elevation: 0,
        title: Text("Today's WOD.", style: HyphenTokens.h3),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: HyphenTokens.primary,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: HyphenTokens.primary))
            : _error != null
                ? Center(child: Text(_error!, style: HyphenTokens.body))
                : _plans.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              children: [
                                Text('오늘 WOD 없음.',
                                    style: HyphenTokens.h3),
                                const SizedBox(height: HyphenTokens.sp2),
                                Text('박스에서 오늘 일정 배치 전이에요.',
                                    style: HyphenTokens.caption),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(HyphenTokens.sp4),
                        itemCount: _plans.length,
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: HyphenTokens.sp3),
                        itemBuilder: (_, i) {
                          final p = _plans[i];
                          final hour = p['plan_hour'] as int? ?? 0;
                          final tname = (p['template_name'] ?? '').toString();
                          final tkind = (p['template_kind'] ?? 'regular').toString();
                          final tdesc = (p['template_description'] ?? '').toString();
                          final wdesc = (p['wod_description'] ?? '').toString();
                          return Container(
                            padding: const EdgeInsets.all(HyphenTokens.sp4),
                            decoration: BoxDecoration(
                              color: HyphenTokens.surface,
                              border:
                                  Border.all(color: HyphenTokens.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${hour.toString().padLeft(2, "0")}:00',
                                      style: HyphenTokens.h2.copyWith(
                                          color: HyphenTokens.primary),
                                    ),
                                    const SizedBox(width: HyphenTokens.sp3),
                                    if (tname.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tkind == 'event'
                                              ? HyphenTokens.primary
                                              : HyphenTokens.surfaceMax,
                                          border: Border.all(
                                              color: HyphenTokens.border),
                                        ),
                                        child: Text(
                                          tkind == 'event' ? 'EVENT' : tname,
                                          style: HyphenTokens.micro.copyWith(
                                              color: tkind == 'event'
                                                  ? Colors.white
                                                  : HyphenTokens.fg,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ),
                                if (tname.isNotEmpty && tkind == 'event') ...[
                                  const SizedBox(height: HyphenTokens.sp1),
                                  Text(tname,
                                      style: HyphenTokens.body.copyWith(
                                          fontWeight: FontWeight.w700)),
                                ],
                                const SizedBox(height: HyphenTokens.sp2),
                                Text((p['wod_title'] ?? '').toString(),
                                    style: HyphenTokens.body.copyWith(
                                        fontWeight: FontWeight.w700)),
                                if (wdesc.isNotEmpty) ...[
                                  const SizedBox(height: HyphenTokens.sp1),
                                  Text(wdesc,
                                      style: HyphenTokens.caption),
                                ],
                                if (tdesc.isNotEmpty) ...[
                                  const SizedBox(height: HyphenTokens.sp2),
                                  Container(
                                    padding: const EdgeInsets.all(
                                        HyphenTokens.sp2),
                                    decoration: BoxDecoration(
                                      color: HyphenTokens.surfaceHigh,
                                      border: Border.all(
                                          color: HyphenTokens.border),
                                    ),
                                    child: Text('이 수업이 어떤가요?  $tdesc',
                                        style: HyphenTokens.micro),
                                  ),
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
