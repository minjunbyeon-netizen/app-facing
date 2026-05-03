// 페르소나 디버그 스위처 — v1.19 차수 5+ 트랙 A.
//
// 목적: services/facing/data/personas.json 의 10명 페르소나로 device_id 강제 변경.
// 사용: MyPage 디버그 메뉴 → 선택 → 적용 → 앱 재시작
//
// 안전: kDebugMode 한정. Release 빌드에서는 진입 차단 (호출자 책임).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_mode.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../auth/auth_state.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';
import 'persona_debug_data.dart';

class _Persona {
  final String id;
  final String displayName;
  final String role;
  final String deviceIdSeed;
  final String tier;
  final String? box;
  final String? status;
  final int wodHistoryCount;

  const _Persona({
    required this.id,
    required this.displayName,
    required this.role,
    required this.deviceIdSeed,
    required this.tier,
    required this.box,
    required this.status,
    required this.wodHistoryCount,
  });
}

/// services/facing/data/personas.json 와 동기화 유지. 10명.
const List<_Persona> _kDebugPersonas = [
  _Persona(
    id: 'admin_01',
    displayName: '변민준',
    role: 'admin',
    deviceIdSeed: 'persona-admin-byun-2026',
    tier: 'RX+',
    box: null,
    status: null,
    wodHistoryCount: 8,
  ),
  _Persona(
    id: 'coach_a',
    displayName: '박지훈',
    role: 'coach_owner',
    deviceIdSeed: 'persona-coach-park-2026',
    tier: 'Elite',
    box: 'FACING SEONGSU',
    status: 'owner',
    wodHistoryCount: 14,
  ),
  _Persona(
    id: 'coach_b',
    displayName: '이수민',
    role: 'coach_owner',
    deviceIdSeed: 'persona-coach-lee-2026',
    tier: 'Elite',
    box: 'FACING GANGNAM',
    status: 'owner',
    wodHistoryCount: 12,
  ),
  _Persona(
    id: 'member_a1',
    displayName: '김도윤',
    role: 'member',
    deviceIdSeed: 'persona-member-kim-doyun-2026',
    tier: 'RX',
    box: 'FACING SEONGSU',
    status: 'approved',
    wodHistoryCount: 11,
  ),
  _Persona(
    id: 'member_a2',
    displayName: '정하은',
    role: 'member',
    deviceIdSeed: 'persona-member-jung-haeun-2026',
    tier: 'RX',
    box: 'FACING SEONGSU',
    status: 'approved',
    wodHistoryCount: 9,
  ),
  _Persona(
    id: 'member_a3',
    displayName: '최서윤',
    role: 'member',
    deviceIdSeed: 'persona-member-choi-seoyun-2026',
    tier: 'Scaled',
    box: 'FACING SEONGSU',
    status: 'pending',
    wodHistoryCount: 0,
  ),
  _Persona(
    id: 'member_b1',
    displayName: '강민재',
    role: 'member',
    deviceIdSeed: 'persona-member-kang-minjae-2026',
    tier: 'RX+',
    box: 'FACING GANGNAM',
    status: 'approved',
    wodHistoryCount: 13,
  ),
  _Persona(
    id: 'member_b2',
    displayName: '윤지원',
    role: 'member',
    deviceIdSeed: 'persona-member-yoon-jiwon-2026',
    tier: 'RX',
    box: 'FACING GANGNAM',
    status: 'approved',
    wodHistoryCount: 7,
  ),
  _Persona(
    id: 'member_b3',
    displayName: '한수아',
    role: 'member',
    deviceIdSeed: 'persona-member-han-suah-2026',
    tier: 'Scaled',
    box: 'FACING GANGNAM',
    status: 'rejected',
    wodHistoryCount: 0,
  ),
  _Persona(
    id: 'app_user_01',
    displayName: '송예준',
    role: 'app_user',
    deviceIdSeed: 'persona-app-song-yejun-2026',
    tier: 'RX',
    box: null,
    status: null,
    wodHistoryCount: 6,
  ),
];

class PersonaSwitcherScreen extends StatefulWidget {
  const PersonaSwitcherScreen({super.key});

  @override
  State<PersonaSwitcherScreen> createState() => _PersonaSwitcherScreenState();
}

class _PersonaSwitcherScreenState extends State<PersonaSwitcherScreen> {
  String? _appliedSeed;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _appliedSeed = DeviceIdService.cached;
  }

  Future<void> _apply(_Persona p) async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptic.medium();
    await DeviceIdService.overrideForDebug(p.deviceIdSeed);
    // 페르소나 role 기반 app_mode 자동 매핑.
    final autoMode = switch (p.role) {
      'coach_owner' => AppMode.coach,
      'member' => AppMode.member,
      _ => AppMode.solo, // admin / app_user 등
    };
    await AppModeStore.set(autoMode);
    // AuthState.displayName 갱신 — 미갱신 시 홈 화면 이름이 이전 페르소나 그대로 표시됨.
    if (mounted) {
      await context.read<AuthState>().signIn('demo', displayName: p.displayName);
    }
    // v1.20 (C1 fix): persona switch 즉시 GymState.loadMine() 호출.
    // 기존: "앱 재시작 후 반영" → DemoSwitcher↔GymState 동기화 누락 BLOCKER.
    // 신규: device_id 갱신 직후 백엔드 /gyms/mine 재조회 → membership/role hydrate.
    if (mounted) {
      try {
        await context.read<GymState>().loadMine();
      } catch (_) {
        // 백엔드 OFF 시 다음 화면 진입 시 재시도. UI 진행 차단 X.
      }
    }
    // 페르소나 ProfileState 즉시 교체 — tier 기반 합성 grade + 체형·벤치마크.
    if (mounted) {
      final body = kPersonaBodyMap[p.deviceIdSeed];
      context.read<ProfileState>().applyPersonaSnapshot(
        bodyWeightKg: body?.bodyWeightKg,
        heightCm: body?.heightCm,
        ageYears: body?.ageYears,
        gender: body?.gender ?? 'male',
        experienceYears: body?.experienceYears ?? 0,
        benchmarks: body?.benchmarks ?? const {},
        gradeResult: tierGrade(p.tier),
      );
    }
    if (!mounted) return;
    setState(() {
      _appliedSeed = p.deviceIdSeed;
      _busy = false;
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surface,
        title: Text('Switched.', style: FacingTokens.h3),
        content: Text(
          '페르소나: ${p.displayName} (${p.role})\n'
          'GymState 즉시 재로딩 시도. 화면 갱신 안 되면 앱 재시작 권장.',
          style: FacingTokens.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('PERSONA SWITCHER')),
        body: const Center(
          child: Text(
            'Debug only.\nRelease build 차단.',
            textAlign: TextAlign.center,
            style: FacingTokens.caption,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('PERSONA SWITCHER')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: [
            const Text(
              'DEBUG PERSONA',
              style: FacingTokens.sectionLabel,
            ),
            const SizedBox(height: FacingTokens.sp1),
            const Text(
              'services/facing/data/personas.json 동기화. '
              '선택 시 device_id 덮어쓰기 후 앱 재시작 필요.',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp4),
            for (final p in _kDebugPersonas)
              _PersonaTile(
                persona: p,
                applied: _appliedSeed == p.deviceIdSeed,
                onTap: _busy ? null : () => _apply(p),
              ),
            const SizedBox(height: FacingTokens.sp5),
            Container(
              padding: const EdgeInsets.all(FacingTokens.sp3),
              decoration: BoxDecoration(
                color: FacingTokens.surface,
                border: Border.all(color: FacingTokens.border),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT device_id',
                    style: FacingTokens.sectionLabel,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _appliedSeed ?? '(not loaded)',
                    style: FacingTokens.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonaTile extends StatelessWidget {
  final _Persona persona;
  final bool applied;
  final VoidCallback? onTap;

  const _PersonaTile({
    required this.persona,
    required this.applied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FacingTokens.sp2),
      child: Material(
        color: applied ? FacingTokens.accent.withValues(alpha: 0.1) : FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            persona.displayName,
                            style: FacingTokens.h3,
                          ),
                          const SizedBox(width: FacingTokens.sp2),
                          _Badge(label: persona.tier),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${persona.role} · ${persona.box ?? '무소속'}'
                        '${persona.status != null ? ' · ${persona.status}' : ''}'
                        ' · WOD ${persona.wodHistoryCount}',
                        style: FacingTokens.caption,
                      ),
                    ],
                  ),
                ),
                if (applied)
                  const Padding(
                    padding: EdgeInsets.only(left: FacingTokens.sp2),
                    child: Icon(
                      Icons.check_circle,
                      color: FacingTokens.accent,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FacingTokens.sp2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: FacingTokens.border, width: 1),
        borderRadius: BorderRadius.circular(FacingTokens.r1),
      ),
      child: Text(label, style: FacingTokens.tierLabel),
    );
  }
}
