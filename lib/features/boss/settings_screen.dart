import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/theme.dart';
import 'boss_api_client.dart';
import 'boss_auth_state.dart';

/// PHASE5 §1-4 — 사장 폰 설정 화면.
///
/// 3 탭: Plans (회원권 마스터) · Points (포인트 정책) · Notifications (알림톡 토글).
/// Backend Phase 1-1·1-2·1-3 endpoint 위에 얹힘. Phase 4-3 자동 금액 매핑·
/// Phase 2-4 포인트 잔액·Phase 5-3 공지사항 자동알림 이 모두 이 설정 의존.
class BossSettingsScreen extends StatefulWidget {
  const BossSettingsScreen({super.key});

  @override
  State<BossSettingsScreen> createState() => _BossSettingsScreenState();
}

class _BossSettingsScreenState extends State<BossSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(
        backgroundColor: FacingTokens.bg,
        elevation: 0,
        title: Text('설정', style: FacingTokens.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FacingTokens.fg),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: FacingTokens.primary,
          labelColor: FacingTokens.fg,
          unselectedLabelColor: FacingTokens.muted,
          labelStyle: FacingTokens.body.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '요금제'),
            Tab(text: '포인트'),
            Tab(text: '알림'),
            Tab(text: '자동 가입'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _PlansTab(),
          _PointsTab(),
          _NotificationsTab(),
          _AutoJoinTab(),
        ],
      ),
    );
  }
}

// ───── Plans 탭 — 회원권 마스터 CRUD ────────────────────────────────
class _PlansTab extends StatefulWidget {
  const _PlansTab();
  @override
  State<_PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<_PlansTab> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<BossAuthState>();
    final api = context.read<BossApiClient>();
    final gid = auth.gymId;
    if (gid == null || gid == 0) {
      setState(() { _loading = false; _error = '박스 정보 없음'; });
      return;
    }
    try {
      final res = await api.get('/api/v1/admin/gyms/$gid/plans');
      final list = (res['plans'] as List?) ?? [];
      setState(() {
        _plans = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false; _error = null;
      });
    } on AppException catch (e) {
      setState(() { _loading = false; _error = e.messageKo; });
    } catch (e) {
      setState(() { _loading = false; _error = '연결 실패'; });
    }
  }

  // _delete 함수는 다음 사이클 plan row 삭제 액션에 연결 예정 — 지금은 _load 사이클만 활용.

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: FacingTokens.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: FacingTokens.body.copyWith(color: FacingTokens.danger)),
      );
    }
    return Column(
      children: [
        Expanded(
          child: _plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('요금제 없음', style: FacingTokens.h3),
                      const SizedBox(height: FacingTokens.sp2),
                      Text('회원권을 추가하면\n회원 등록 시 자동 금액이 떠요.',
                          textAlign: TextAlign.center,
                          style: FacingTokens.caption),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(FacingTokens.sp4),
                  itemCount: _plans.length,
                  separatorBuilder: (ctx, idx) =>
                      const SizedBox(height: FacingTokens.sp2),
                  itemBuilder: (_, i) {
                    final p = _plans[i];
                    final active = p['is_active'] == true;
                    return Container(
                      padding: const EdgeInsets.all(FacingTokens.sp3),
                      decoration: BoxDecoration(
                        color: FacingTokens.surface,
                        border: Border.all(color: FacingTokens.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name']?.toString() ?? '?',
                                    style: FacingTokens.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? FacingTokens.fg
                                            : FacingTokens.muted)),
                                const SizedBox(height: 2),
                                Text(
                                  '${p['price_krw'] ?? 0}₩ · '
                                  '${p['duration_days'] ?? '-'}d · '
                                  '${p['plan_type']}',
                                  style: FacingTokens.caption,
                                ),
                              ],
                            ),
                          ),
                          if (!active)
                            const Padding(
                              padding: EdgeInsets.only(right: FacingTokens.sp2),
                              child: Text('비활성', style: FacingTokens.micro),
                            ),
                          // PHASE5 §1-1 plan soft delete (is_active=false). 활성만 노출.
                          if (active)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: FacingTokens.muted),
                              tooltip: 'Disable plan',
                              onPressed: () async {
                                final id = (p['id'] as num?)?.toInt() ?? 0;
                                if (id == 0) return;
                                final api = context.read<BossApiClient>();
                                try {
                                  await api.delete('/api/v1/admin/plans/$id');
                                } catch (_) {}
                                await _load();
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(FacingTokens.sp3),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCreateSheet(context, onDone: _load),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.primary,
                foregroundColor: FacingTokens.onColor,
                padding: const EdgeInsets.symmetric(
                    vertical: FacingTokens.sp3),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              // v1.33: color 명시 — FacingTokens.body 가 어두운 fg 를 품고 있어
              // 위 foregroundColor(흰색) 를 덮어쓰고 빨간 배경에 어두운 글자가 됐다.
              child: Text('요금제 추가',
                  style: FacingTokens.body.copyWith(
                      color: FacingTokens.onColor,
                      fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showCreateSheet(BuildContext ctx,
    {required Future<void> Function() onDone}) async {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  String planType = 'time_based';
  await showModalBottomSheet<void>(
    context: ctx,
    backgroundColor: FacingTokens.surface,
    isScrollControlled: true,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        left: FacingTokens.sp4,
        right: FacingTokens.sp4,
        top: FacingTokens.sp4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('새 요금제', style: FacingTokens.h2),
          const SizedBox(height: FacingTokens.sp4),
          TextField(
            controller: nameCtrl,
            style: FacingTokens.body.copyWith(color: FacingTokens.fg),
            decoration: const InputDecoration(hintText: '이름 (예: 3개월권)'),
          ),
          const SizedBox(height: FacingTokens.sp2),
          TextField(
            controller: priceCtrl,
            style: FacingTokens.body.copyWith(color: FacingTokens.fg),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '금액 (KRW)'),
          ),
          const SizedBox(height: FacingTokens.sp2),
          TextField(
            controller: daysCtrl,
            style: FacingTokens.body.copyWith(color: FacingTokens.fg),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '기간 일수 (예: 90)'),
          ),
          const SizedBox(height: FacingTokens.sp4),
          ElevatedButton(
            onPressed: () async {
              final api = sheetCtx.read<BossApiClient>();
              final auth = sheetCtx.read<BossAuthState>();
              final gid = auth.gymId ?? 0;
              try {
                await api.post('/api/v1/admin/gyms/$gid/plans', {
                  'name': nameCtrl.text.trim(),
                  'plan_type': planType,
                  'price_krw': int.tryParse(priceCtrl.text.trim()) ?? 0,
                  'duration_days': int.tryParse(daysCtrl.text.trim()),
                });
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                await onDone();
              } catch (_) {
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FacingTokens.primary,
              foregroundColor: FacingTokens.onColor,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
            ),
            child: Text('저장', style: FacingTokens.body),
          ),
          const SizedBox(height: FacingTokens.sp4),
        ],
      ),
    ),
  );
}

// ───── Points 탭 — 박스 포인트 정책 ─────────────────────────────────
class _PointsTab extends StatefulWidget {
  const _PointsTab();
  @override
  State<_PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<_PointsTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<BossAuthState>();
    final api = context.read<BossApiClient>();
    final gid = auth.gymId;
    if (gid == null || gid == 0) {
      setState(() { _loading = false; _error = '박스 정보 없음'; });
      return;
    }
    try {
      final res = await api.get('/api/v1/admin/gyms/$gid/point-settings');
      setState(() {
        _data = Map<String, dynamic>.from(res);
        _loading = false; _error = null;
      });
    } catch (e) {
      setState(() { _loading = false; _error = '연결 실패'; });
    }
  }

  Future<void> _patch(Map<String, dynamic> changes) async {
    final auth = context.read<BossAuthState>();
    final api = context.read<BossApiClient>();
    final gid = auth.gymId ?? 0;
    try {
      final res = await api.patch(
          '/api/v1/admin/gyms/$gid/point-settings', changes);
      setState(() => _data = Map<String, dynamic>.from(res));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: FacingTokens.primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: FacingTokens.body.copyWith(color: FacingTokens.danger)));
    }
    final d = _data ?? const {};
    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        SwitchListTile(
          tileColor: FacingTokens.surface,
          activeThumbColor: FacingTokens.primary,
          title: Text('포인트 활성', style: FacingTokens.body),
          subtitle: Text('박스 전체 포인트 적립·사용 on/off',
              style: FacingTokens.caption),
          value: d['is_active'] == true,
          onChanged: (v) => _patch({'is_active': v}),
        ),
        const SizedBox(height: FacingTokens.sp3),
        // PHASE5 §1-2 후속 — 값 inline 편집. tap 시 prompt-style dialog.
        _EditRow(
          label: '적립률 (%)',
          value: '${d['earn_rate'] ?? 0}',
          onTap: () => _editInt('earn_rate', '적립률 (0~100)',
              (d['earn_rate'] as num?)?.toInt() ?? 0),
        ),
        _EditRow(
          label: '사용 최소 단위 (P)',
          value: '${d['redeem_unit'] ?? 0}',
          onTap: () => _editInt('redeem_unit', '사용 최소 단위 (P)',
              (d['redeem_unit'] as num?)?.toInt() ?? 1000),
        ),
        _EditRow(
          label: '만료 일수',
          value: (d['expiry_days'] ?? 0) == 0
              ? '무기한'
              : '${d['expiry_days']}일',
          onTap: () => _editInt('expiry_days', '만료 일수 (0 = 무기한)',
              (d['expiry_days'] as num?)?.toInt() ?? 365),
        ),
      ],
    );
  }

  Future<void> _editInt(String key, String label, int current) async {
    final ctrl = TextEditingController(text: '$current');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surface,
        title: Text(label, style: FacingTokens.h3),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: FacingTokens.body.copyWith(color: FacingTokens.fg),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소')),
          TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(int.tryParse(ctrl.text.trim())),
              child: const Text('저장')),
        ],
      ),
    );
    if (v == null) return;
    await _patch({key: v});
  }
}

// ───── Notifications 탭 — 알림톡 토글 ──────────────────────────────
class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();
  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<BossAuthState>();
    final api = context.read<BossApiClient>();
    final gid = auth.gymId;
    if (gid == null || gid == 0) {
      setState(() { _loading = false; _error = '박스 정보 없음'; });
      return;
    }
    try {
      final res =
          await api.get('/api/v1/admin/gyms/$gid/notification-settings');
      setState(() {
        _data = Map<String, dynamic>.from(res);
        _loading = false; _error = null;
      });
    } catch (e) {
      setState(() { _loading = false; _error = '연결 실패'; });
    }
  }

  Future<void> _patchKey(String key, bool v) async {
    final auth = context.read<BossAuthState>();
    final api = context.read<BossApiClient>();
    final gid = auth.gymId ?? 0;
    try {
      final res = await api.patch(
          '/api/v1/admin/gyms/$gid/notification-settings', {key: v});
      setState(() => _data = Map<String, dynamic>.from(res));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: FacingTokens.primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: FacingTokens.body.copyWith(color: FacingTokens.danger)));
    }
    final d = _data ?? const {};
    final items = <(String, String, String)>[
      ('enabled', '전체 알림', '박스 전체 알림톡 on/off'),
      ('expiry', '만료 알림', '회원권 만료 7일·3일·당일'),
      ('payment', '결제 알림', '결제 성공·실패'),
      ('reservation', '예약 알림', '예약 확정·취소'),
      ('cancel', '해지 알림', '해지 처리'),
    ];
    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: items
          .map((t) => SwitchListTile(
                tileColor: FacingTokens.surface,
                activeThumbColor: FacingTokens.primary,
                title: Text(t.$2, style: FacingTokens.body),
                subtitle: Text(t.$3, style: FacingTokens.caption),
                value: d[t.$1] == true,
                onChanged: (v) => _patchKey(t.$1, v),
              ))
          .toList(),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _EditRow({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: FacingTokens.body)),
            Text(value, style: FacingTokens.body.copyWith(color: FacingTokens.fg)),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, size: 14, color: FacingTokens.muted),
          ],
        ),
      ),
    );
  }
}

// _Row 는 _EditRow 로 대체되어 제거됨 (사이클 58)

// ───── PHASE5 §4-1 — Auto-Join 토글 탭 (사이클 61) ──────────────────
class _AutoJoinTab extends StatefulWidget {
  const _AutoJoinTab();
  @override
  State<_AutoJoinTab> createState() => _AutoJoinTabState();
}

class _AutoJoinTabState extends State<_AutoJoinTab> {
  bool _enabled = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<BossAuthState>();
    final api = context.read<BossApiClient>();
    final gid = auth.gymId ?? 0;
    if (gid == 0) {
      setState(() { _loading = false; _error = '박스 정보 없음'; });
      return;
    }
    try {
      final res = await api.get('/api/v1/admin/gyms/$gid/auto-approve');
      setState(() {
        _enabled = res['enabled'] == true;
        _loading = false; _error = null;
      });
    } catch (e) {
      setState(() { _loading = false; _error = '연결 실패'; });
    }
  }

  Future<void> _toggle(bool v) async {
    final auth = context.read<BossAuthState>();
    final api = context.read<BossApiClient>();
    final gid = auth.gymId ?? 0;
    try {
      final res = await api.patch(
          '/api/v1/admin/gyms/$gid/auto-approve', {'enabled': v});
      setState(() => _enabled = res['enabled'] == true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: FacingTokens.primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: FacingTokens.body.copyWith(color: FacingTokens.danger)));
    }
    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        SwitchListTile(
          tileColor: FacingTokens.surface,
          activeThumbColor: FacingTokens.primary,
          title: Text('자동 가입 승인', style: FacingTokens.body),
          subtitle: Text(
            '회원이 박스 가입 신청 시 코치 승인 없이 즉시 활성. 무인 박스 권장.',
            style: FacingTokens.caption,
          ),
          value: _enabled,
          onChanged: _toggle,
        ),
        const SizedBox(height: FacingTokens.sp3),
        Text(
          _enabled
              ? '활성: 가입 신청 즉시 approved 처리'
              : '비활성: 코치가 회원 리스트의 대기 탭에서 직접 승인',
          style: FacingTokens.caption,
        ),
      ],
    );
  }
}
