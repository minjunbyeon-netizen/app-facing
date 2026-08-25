import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/theme.dart';
import 'boss_api_client.dart';
import 'boss_auth_state.dart';

/// PHASE5 §1-4 — 사장 폰 설정 화면.
///
/// 3 탭: 알림 · 자동 가입 · 예약.
///
/// v3.21 (2026-08-25 사용자 지시): '요금제' 탭 삭제 — 요금제를 만들고 고치는 건
/// PC 몫이다 (README §제거된 기능 대장 17). 백엔드 요금제 API 는 PC 가 계속 쓴다.
/// (구 포인트 탭은 2026-08-24 포인트 이원화 정리로 삭제 — gym_point_settings
/// 가 읽는 코드 0 고아라 API·모델과 함께 제거. 포인트 지급은 리워드 규칙
/// 엔진 + PC 수동 지급 프리셋만.)
class BossSettingsScreen extends StatefulWidget {
  const BossSettingsScreen({super.key});

  @override
  State<BossSettingsScreen> createState() => _BossSettingsScreenState();
}

class _BossSettingsScreenState extends State<BossSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: AppBar(
        backgroundColor: HyphenTokens.bg,
        elevation: 0,
        title: Text('설정', style: HyphenTokens.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HyphenTokens.fg),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // v3.4 (2026-08-21 사용자 지시) — 대시보드 우상단 아이콘만으론 못 찾던
        // 로그아웃을 설정에도 글자 버튼으로 노출 (동작은 대시보드 _logout 동일).
        actions: [
          TextButton(
            onPressed: () async {
              final api = context.read<BossApiClient>();
              final auth = context.read<BossAuthState>();
              try {
                await api.post('/api/v1/admin/logout', {});
              } catch (_) {}
              await auth.clear();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/splash', (_) => false);
            },
            child: Text('로그아웃',
                style: HyphenTokens.body.copyWith(color: HyphenTokens.muted)),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          // 5탭부터 고정폭에선 '자동 가입' 라벨이 잘린다 — 스크롤 탭.
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: HyphenTokens.primary,
          labelColor: HyphenTokens.fg,
          unselectedLabelColor: HyphenTokens.muted,
          labelStyle: HyphenTokens.body.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '알림'),
            Tab(text: '자동 가입'),
            Tab(text: '예약'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _NotificationsTab(),
          _AutoJoinTab(),
          _ReservationTab(),
        ],
      ),
    );
  }
}

// ───── Plans 탭 — 회원권 마스터 CRUD ────────────────────────────────
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
      setState(() { _loading = false; _error = '체육관 정보 없음'; });
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
          child: CircularProgressIndicator(color: HyphenTokens.primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: HyphenTokens.body.copyWith(color: HyphenTokens.danger)));
    }
    final d = _data ?? const {};
    final items = <(String, String, String)>[
      ('enabled', '전체 알림', '체육관 전체 알림톡 on/off'),
      ('expiry', '만료 알림', '회원권 만료 7일·3일·당일'),
      ('payment', '결제 알림', '결제 성공·실패'),
      ('reservation', '예약 알림', '예약 확정·취소'),
      ('cancel', '해지 알림', '해지 처리'),
    ];
    return ListView(
      padding: const EdgeInsets.all(HyphenTokens.sp4),
      children: items
          .map((t) => SwitchListTile(
                tileColor: HyphenTokens.surface,
                activeThumbColor: HyphenTokens.primary,
                title: Text(t.$2, style: HyphenTokens.body),
                subtitle: Text(t.$3, style: HyphenTokens.caption),
                value: d[t.$1] == true,
                onChanged: (v) => _patchKey(t.$1, v),
              ))
          .toList(),
    );
  }
}

// ───── Reservation 탭 — 수업 예약 정책 (2026-08-24) ─────────────────
// 백엔드 gym_class_settings — 하루 예약 한도 (0=무제한, 1~10).
// 집행은 서버 create_reservation 게이트 — 이 탭은 설정값 CRUD 만.
class _ReservationTab extends StatefulWidget {
  const _ReservationTab();
  @override
  State<_ReservationTab> createState() => _ReservationTabState();
}

class _ReservationTabState extends State<_ReservationTab> {
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
      setState(() { _loading = false; _error = '체육관 정보 없음'; });
      return;
    }
    try {
      final res = await api.get('/api/v1/admin/gyms/$gid/class-settings');
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
          '/api/v1/admin/gyms/$gid/class-settings', changes);
      setState(() => _data = Map<String, dynamic>.from(res));
    } on AppException catch (e) {
      // 범위 밖(BAD_RANGE) 등 — 조용히 삼키면 저장된 줄 안다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.messageKo)));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: HyphenTokens.primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: HyphenTokens.body.copyWith(color: HyphenTokens.danger)));
    }
    final d = _data ?? const {};
    final limit = (d['daily_reservation_limit'] as num?)?.toInt() ?? 0;
    return ListView(
      padding: const EdgeInsets.all(HyphenTokens.sp4),
      children: [
        _EditRow(
          label: '하루 예약 한도',
          value: limit == 0 ? '무제한' : '$limit회',
          onTap: () => _editInt(
              'daily_reservation_limit', '하루 예약 한도 (0 = 무제한, 최대 10)',
              limit),
        ),
        const SizedBox(height: HyphenTokens.sp2),
        Text('회원 1명이 하루(수업 날짜 기준)에 잡을 수 있는 예약 수입니다. '
            '한도를 넘으면 예약·대기 신청이 거절됩니다.',
            style: HyphenTokens.caption),
      ],
    );
  }

  Future<void> _editInt(String key, String label, int current) async {
    final ctrl = TextEditingController(text: '$current');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HyphenTokens.surface,
        title: Text(label, style: HyphenTokens.h3),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
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
        padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: HyphenTokens.body)),
            Text(value, style: HyphenTokens.body.copyWith(color: HyphenTokens.fg)),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, size: 14, color: HyphenTokens.muted),
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
      setState(() { _loading = false; _error = '체육관 정보 없음'; });
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
          child: CircularProgressIndicator(color: HyphenTokens.primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: HyphenTokens.body.copyWith(color: HyphenTokens.danger)));
    }
    return ListView(
      padding: const EdgeInsets.all(HyphenTokens.sp4),
      children: [
        SwitchListTile(
          tileColor: HyphenTokens.surface,
          activeThumbColor: HyphenTokens.primary,
          title: Text('자동 가입 승인', style: HyphenTokens.body),
          subtitle: Text(
            '가입 신청 시 코치 승인 없이 즉시 활성. 무인 운영 시 권장.',
            style: HyphenTokens.caption,
          ),
          value: _enabled,
          onChanged: _toggle,
        ),
        const SizedBox(height: HyphenTokens.sp3),
        Text(
          _enabled
              ? '활성: 가입 신청 즉시 approved 처리'
              : '비활성: 코치가 회원 리스트의 대기 탭에서 직접 승인',
          style: HyphenTokens.caption,
        ),
      ],
    );
  }
}
