import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
import '../../core/role_labels.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../../core/ui_prefs_state.dart';
import '../../core/unit_state.dart';
import '../../widgets/inbox_bell.dart';
import '../_debug/persona_debug_data.dart';
import '../_debug/persona_switcher_screen.dart';
import '../auth/auth_state.dart';
import '../goals/goals_screen.dart';
import '../gym/coach_dashboard_screen.dart';
import '../gym/gym_search_screen.dart';
import '../gym/gym_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';
import 'algorithm_screen.dart';
import 'edit_profile_screen.dart';
import 'import_screen.dart';
import 'privacy_screen.dart';

/// v1.22: Profile = identity + 측정값 편집 진입 + 잘안쓰는 actions.
/// Engine score · Tier · Radar · Category Tier · Trend · Records · RoleModel 등
/// score 관련 컨텐츠는 모두 Home 으로 이동 (중복 제거).
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: const [InboxBellAction()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
          children: const [
            _IdentityCard(),
            _SectionDivider(),
            _AttendanceCompact(),
            _SectionDivider(),
            _MembershipCard(),
            _LockerCard(),
            _SectionDivider(),
            _MyBoxSection(),
            _SectionDivider(),
            _BodyStats(),
            _SectionDivider(),
            _SettingsSection(),
            _SectionDivider(),
            _ActionsSection(),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: Divider(height: 1, color: FacingTokens.border),
      );
}

/// v1.22: 닉네임 + 아바타 + Edit Profile 버튼.
/// v1.22 rev3: 컴팩트 출석 미니 캘린더 + 1줄 통계.
/// Attend 의 큰 캘린더에서 분리해 Profile 상단에 배치.
class _AttendanceCompact extends StatefulWidget {
  const _AttendanceCompact();

  @override
  State<_AttendanceCompact> createState() => _AttendanceCompactState();
}

class _AttendanceCompactState extends State<_AttendanceCompact> {
  Future<List<WodHistoryItem>>? _future;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _future = repo.listWodHistory(limit: 200);
  }

  int _currentStreak(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    int count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: FutureBuilder<List<WodHistoryItem>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(height: 80);
          }
          final records = snap.data ?? const <WodHistoryItem>[];
          final now = DateTime.now();
          final monthYear = now.year;
          final monthNum = now.month;
          final daysInMonth =
              DateUtils.getDaysInMonth(monthYear, monthNum);
          final firstWeekday =
              DateTime(monthYear, monthNum, 1).weekday % 7;
          final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

          final counts = <int, int>{};
          final allDays = <DateTime>{};
          for (final r in records) {
            final d = r.createdAt.toLocal();
            allDays.add(DateTime(d.year, d.month, d.day));
            if (d.year == monthYear && d.month == monthNum) {
              counts[d.day] = (counts[d.day] ?? 0) + 1;
            }
          }
          int maxCount = 1;
          for (final v in counts.values) {
            if (v > maxCount) maxCount = v;
          }
          final streak = _currentStreak(allDays);
          final attended = counts.keys.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('ATTENDANCE',
                      style: FacingTokens.sectionLabel),
                  const Spacer(),
                  Text(
                    '$monthYear.${monthNum.toString().padLeft(2, '0')}',
                    style: FacingTokens.caption,
                  ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp2),
              // 미니 캘린더 — 일자 숫자 + 강도색 (컴팩트 2px 간격).
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (_, i) {
                  final dayNum = i - firstWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final count = counts[dayNum] ?? 0;
                  final isToday = now.day == dayNum;
                  final intensity =
                      count == 0 ? 0.0 : (0.35 + (count / maxCount) * 0.55);
                  return Container(
                    decoration: BoxDecoration(
                      color: count > 0
                          ? FacingTokens.accent.withValues(alpha: intensity)
                          : FacingTokens.surface,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isToday
                            ? FacingTokens.accent
                            : FacingTokens.border,
                        width: isToday ? 1.5 : 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 8,
                        height: 1,
                        fontWeight: isToday
                            ? FontWeight.w800
                            : FontWeight.w400,
                        color: count > 0
                            ? FacingTokens.fg
                            : FacingTokens.muted.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: FacingTokens.sp3),
              // 1줄 통계 — streak · total · 이달 출석.
              Row(
                children: [
                  _StatBlock(label: 'STREAK', value: '${streak}d'),
                  const SizedBox(width: FacingTokens.sp4),
                  _StatBlock(
                      label: 'TOTAL', value: '${records.length}'),
                  const SizedBox(width: FacingTokens.sp4),
                  _StatBlock(label: 'THIS MONTH', value: '${attended}d'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FacingTokens.microLabel),
        const SizedBox(height: 2),
        Text(value,
            style: FacingTokens.h3.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: FacingTokens.tabular,
              color: FacingTokens.fg,
            )),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final gs = context.watch<GymState>();
    // PC 사장이 등록한 GymMemberProfile.name 우선. 없으면 auth.displayName fallback.
    final mp = gs.membership.memberProfile;
    final boxRegisteredName = (mp?.name ?? '').trim();
    // v1.16.2 — 옛 통문자열 "박지훈 · FACING SEONGSU 코치" 가 SharedPreferences 에
    // 캐시돼 있을 수 있어 ' · ' 첫 부분만 잘라서 진짜 이름만 사용.
    String firstSegment(String s) {
      final i = s.indexOf(' · ');
      return i > 0 ? s.substring(0, i).trim() : s.trim();
    }
    final name = boxRegisteredName.isNotEmpty
        ? boxRegisteredName
        : ((auth.displayName?.trim().isNotEmpty == true)
            ? firstSegment(auth.displayName!)
            : 'Athlete');
    final provider = (auth.provider ?? '').toUpperCase();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 아바타 — 현재는 첫 글자. 향후 사진 설정 시 Avatar 위젯으로 교체.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: FacingTokens.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FacingTokens.accent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: FacingTokens.h2.copyWith(
                    color: FacingTokens.accent,
                  ),
                ),
              ),
              const SizedBox(width: FacingTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: FacingTokens.h2),
                    // v1.16.2 — 박스명 · 역할 라벨 (GymState 데이터 소스)
                    Builder(builder: (_) {
                      final gym = gs.membership.gym;
                      final roleLabel = roleKoLabel(
                        role: gs.membership.role,
                        status: gs.membership.status,
                      );
                      final gymLine = [
                        if (gym?.name != null && gym!.name.isNotEmpty)
                          gym.name,
                        if (roleLabel.isNotEmpty) roleLabel,
                      ].join(' · ');
                      if (gymLine.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          gymLine,
                          style: FacingTokens.caption,
                        ),
                      );
                    }),
                    // 위치 (gyms.location) — 있을 때만 한 줄 더
                    Builder(builder: (_) {
                      final loc = gs.membership.gym?.location ?? '';
                      if (loc.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(loc, style: FacingTokens.caption),
                      );
                    }),
                    if (provider.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(provider, style: FacingTokens.microLabel),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // PC 사장이 등록한 신원정보 카드 (있을 때만).
          if (mp != null && !mp.isEmpty) ...[
            const SizedBox(height: FacingTokens.sp3),
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
                  Row(
                    children: [
                      const Text('GYM RECORD',
                          style: FacingTokens.sectionLabel),
                      const Spacer(),
                      if (mp.updatedAt != null)
                        Text(
                          _fmtUpdated(mp.updatedAt!),
                          style: FacingTokens.micro,
                        ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp2),
                  if ((mp.level ?? '').isNotEmpty)
                    _ProfileRow(label: 'Tier', value: mp.level!),
                  if ((mp.phone ?? '').isNotEmpty)
                    _ProfileRow(label: 'Phone', value: mp.phone!),
                  if ((mp.birthDate ?? '').isNotEmpty)
                    _ProfileRow(label: 'Birth', value: mp.birthDate!),
                  if ((mp.gender ?? '').isNotEmpty)
                    _ProfileRow(label: 'Gender', value: mp.gender!),
                  if ((mp.preferredTimeSlot ?? '').isNotEmpty)
                    _ProfileRow(
                        label: 'Preferred', value: mp.preferredTimeSlot!),
                  if ((mp.safetyNote ?? '').isNotEmpty)
                    _ProfileRow(label: 'Safety', value: mp.safetyNote!),
                  if ((mp.note ?? '').isNotEmpty)
                    _ProfileRow(label: 'Note', value: mp.note!),
                ],
              ),
            ),
          ],
          const SizedBox(height: FacingTokens.sp4),
          OutlinedButton.icon(
            onPressed: () {
              Haptic.light();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ));
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  String _fmtUpdated(DateTime dt) {
    final l = dt.toLocal();
    return '${l.month}/${l.day} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: FacingTokens.micro
                    .copyWith(color: FacingTokens.muted)),
          ),
          Expanded(
            child: Text(value, style: FacingTokens.caption),
          ),
        ],
      ),
    );
  }
}

class _MyBoxSection extends StatelessWidget {
  const _MyBoxSection();

  Future<void> _confirmLeave(BuildContext context, GymState gs) async {
    final gymName = gs.membership.gym?.name ?? '박스';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('Leave Box?'),
        content: Text(
          '$gymName 에서 탈퇴합니다.\n'
          '탈퇴 후 다른 박스에 가입하거나 새로 만들 수 있습니다.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final success = await gs.leaveGym();
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gs.error ?? 'Leave failed.'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    // 탈퇴 성공 → WOD 탭(index 1)으로 이동해 박스 찾기 유도.
    context.read<ShellNavBus>().requestTab(1);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const GymSearchScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('MY BOX', style: FacingTokens.sectionLabel),
              const Spacer(),
              if (gym != null && !gs.isOwner)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: FacingTokens.muted,
                    padding: const EdgeInsets.symmetric(
                        horizontal: FacingTokens.sp2),
                    textStyle: FacingTokens.micro,
                  ),
                  onPressed: () {
                    Haptic.light();
                    _confirmLeave(context, gs);
                  },
                  child: const Text('Change'),
                ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          if (gym == null)
            const Text('No Box. Find Box on WOD tab.',
                style: FacingTokens.caption)
          else ...[
            Text(gym.name,
                style:
                    FacingTokens.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '${gs.isOwner ? 'OWNER' : 'MEMBER'} · ${gs.membership.status ?? '-'} · ${gym.memberCount} members',
              style: FacingTokens.caption,
            ),
            if (gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp3),
              OutlinedButton(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CoachDashboardScreen(),
                  ));
                },
                child: const Text('Manage Members'),
              ),
            ],
            // 클래스 일정 진입 (회원·owner 모두). PC 사장이 등록한 클래스를 본다.
            if (gs.membership.isApprovedMember || gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp2),
              OutlinedButton.icon(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).pushNamed('/classes');
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: const Text('Classes'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BodyStats extends StatelessWidget {
  const _BodyStats();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final unit = context.watch<UnitState>();
    final weightDisplay = p.bodyWeightKg == null
        ? '-'
        : '${_fmt(unit.kgToDisplay(p.bodyWeightKg!)!)} ${unit.weightSuffix}';
    final height = p.heightCm == null ? '-' : '${_fmt(p.heightCm!)} cm';
    final age = p.ageYears == null ? '-' : '${_fmt(p.ageYears!)} yr';
    final sex = p.gender == 'female' ? 'Female' : 'Male';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BODY', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          _Kv(label: 'Weight', value: weightDisplay),
          _Kv(label: 'Height', value: height),
          _Kv(label: 'Age', value: age),
          _Kv(label: 'Sex', value: sex),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  const _Kv({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: FacingTokens.caption)),
          Expanded(
            flex: 5,
            child: Text(value,
                style:
                    FacingTokens.body.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SETTINGS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          const _ModeRow(),
          const SizedBox(height: FacingTokens.sp3),
          Row(
            children: [
              const Expanded(child: Text('Unit', style: FacingTokens.body)),
              Consumer<UnitState>(
                builder: (ctx, u, _) => _UnitToggle(u: u),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          Consumer<UiPrefsState>(
            builder: (ctx, ui, _) => Row(
              children: [
                const Expanded(
                    child: Text('Font Size', style: FacingTokens.body)),
                _TextScaleToggle(current: ui.textScale, state: ui),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextScaleToggle extends StatelessWidget {
  final double current;
  final UiPrefsState state;
  const _TextScaleToggle({required this.current, required this.state});

  @override
  Widget build(BuildContext context) {
    const options = [(1.0, 'A'), (1.15, 'A+'), (1.30, 'A++')];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final selected = (current - o.$1).abs() < 0.01;
        return Padding(
          padding: const EdgeInsets.only(left: FacingTokens.sp1),
          child: InkWell(
            onTap: () {
              Haptic.light();
              state.setTextScale(o.$1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp3,
                vertical: FacingTokens.sp2,
              ),
              decoration: BoxDecoration(
                color: selected ? FacingTokens.fg : FacingTokens.bg,
                border: Border.all(
                  color: selected ? FacingTokens.fg : FacingTokens.border,
                ),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              child: Text(
                o.$2,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final UnitState u;
  const _UnitToggle({required this.u});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(
            label: 'kg',
            selected: u.isKg,
            onTap: () {
              if (!u.isKg) u.toggle();
            }),
        const SizedBox(width: FacingTokens.sp2),
        _Pill(
            label: 'lb',
            selected: !u.isKg,
            onTap: () {
              if (u.isKg) u.toggle();
            }),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FacingTokens.r4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FacingTokens.touchMin),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp4,
              vertical: FacingTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: selected ? FacingTokens.fg : Colors.transparent,
              borderRadius: BorderRadius.circular(FacingTokens.r4),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.muted,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer<AuthState>(
            builder: (ctx, auth, _) {
              if (!auth.isSignedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${auth.provider?.toUpperCase() ?? '-'} · ${auth.displayName ?? ''}',
                        style: FacingTokens.caption,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                      ),
                      onPressed: () => _confirmSignOut(context),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/history'),
            child: const Text('View History'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PrivacyScreen(),
            )),
            child: const Text('Privacy Policy'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ImportScreen(),
            )),
            child: const Text('Import Data'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const GoalsScreen(),
            )),
            child: const Text('Goals'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AlgorithmScreen(),
            )),
            child: const Text('Algorithm'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: FacingTokens.accent,
            ),
            onPressed: () => _confirmReset(context),
            child: const Text('Reset data'),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: FacingTokens.sp5),
            const Divider(),
            const SizedBox(height: FacingTokens.sp3),
            const Text('DEBUG', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp1),
            const Text(
              'Debug 빌드 전용. Release 자동 차단.',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp3),
            const _QuickPersonaBar(),
            const SizedBox(height: FacingTokens.sp2),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PersonaSwitcherScreen(),
              )),
              child: const Text('Persona Switcher (전체)'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('Reset data?'),
        content: const Text(
          '프로필·등급·벤치마크를 전부 삭제합니다.\n'
          '되돌릴 수 없습니다.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('Sign Out.'),
        content: const Text(
          '로그아웃해도 프로필·기록은 이 기기에 그대로 유지됩니다.\n'
          '같은 provider로 다시 로그인하면 모든 데이터 복구.\n'
          '계정 자체를 지우려면 Privacy Policy → Delete Account.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.muted),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/signup', (_) => false);
  }
}

class _ModeRow extends StatefulWidget {
  const _ModeRow();

  @override
  State<_ModeRow> createState() => _ModeRowState();
}

class _ModeRowState extends State<_ModeRow> {
  AppMode? _mode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await AppModeStore.get();
    if (!mounted) return;
    setState(() => _mode = m);
  }

  Future<void> _setMode(AppMode m) async {
    if (_mode == m || _saving) return;
    Haptic.medium();
    setState(() => _saving = true);
    await AppModeStore.set(m);
    if (!mounted) return;
    setState(() {
      _mode = m;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mode → ${_label(m)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _label(AppMode m) => switch (m) {
        AppMode.coach => 'Coach',
        AppMode.member => 'Member',
        AppMode.solo => 'Solo',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Mode', style: FacingTokens.body),
            const SizedBox(width: FacingTokens.sp2),
            if (_saving)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: FacingTokens.muted,
                ),
              ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp2),
        Semantics(
          explicitChildNodes: true,
          container: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: FacingTokens.sp2,
            children: [
              for (final m in AppMode.values)
                Semantics(
                  label:
                      'Mode ${_label(m)}${_mode == m ? " selected" : ""}',
                  button: true,
                  selected: _mode == m,
                  container: true,
                  child: ChoiceChip(
                    label: Text(_label(m)),
                    selected: _mode == m,
                    backgroundColor: FacingTokens.surface,
                    selectedColor: FacingTokens.accent,
                    labelStyle: FacingTokens.caption.copyWith(
                      color:
                          _mode == m ? FacingTokens.fg : FacingTokens.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: _saving ? null : (_) => _setMode(m),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Persona Bar (Debug only)
// 5 avatars: 2 coaches + 3 members. 탭 → 즉시 페르소나 전환 (앱 재시작 불필요).

class _QuickPersonaSpec {
  final String displayName;
  final String role; // 'coach_owner' | 'member'
  final String deviceIdSeed;
  final String shortLabel;
  final String? box;
  final String tier;
  const _QuickPersonaSpec({
    required this.displayName,
    required this.role,
    required this.deviceIdSeed,
    required this.shortLabel,
    required this.tier,
    this.box,
  });
}

const List<_QuickPersonaSpec> _kQuickPersonas = [
  _QuickPersonaSpec(
    displayName: '박지훈',
    role: 'coach_owner',
    deviceIdSeed: 'persona-coach-park-2026',
    shortLabel: 'COACH A',
    tier: 'Elite',
    box: 'SEONGSU',
  ),
  _QuickPersonaSpec(
    displayName: '이수민',
    role: 'coach_owner',
    deviceIdSeed: 'persona-coach-lee-2026',
    shortLabel: 'COACH B',
    tier: 'Elite',
    box: 'GANGNAM',
  ),
  _QuickPersonaSpec(
    displayName: '김도윤',
    role: 'member',
    deviceIdSeed: 'persona-member-kim-doyun-2026',
    shortLabel: 'USER A',
    tier: 'RX',
    box: 'SEONGSU',
  ),
  _QuickPersonaSpec(
    displayName: '정하은',
    role: 'member',
    deviceIdSeed: 'persona-member-jung-haeun-2026',
    shortLabel: 'USER B',
    tier: 'RX',
    box: 'SEONGSU',
  ),
  _QuickPersonaSpec(
    displayName: '강민재',
    role: 'member',
    deviceIdSeed: 'persona-member-kang-minjae-2026',
    shortLabel: 'USER C',
    tier: 'RX+',
    box: 'GANGNAM',
  ),
];

class _QuickPersonaBar extends StatefulWidget {
  const _QuickPersonaBar();

  @override
  State<_QuickPersonaBar> createState() => _QuickPersonaBarState();
}

class _QuickPersonaBarState extends State<_QuickPersonaBar> {
  String? _activeSeed;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _activeSeed = DeviceIdService.cached;
  }

  Future<void> _switch(_QuickPersonaSpec p) async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptic.medium();
    await DeviceIdService.overrideForDebug(p.deviceIdSeed);
    final autoMode =
        p.role == 'coach_owner' ? AppMode.coach : AppMode.member;
    await AppModeStore.set(autoMode);
    // AuthState.displayName 즉시 갱신 — 홈·프로필 상단 이름 반영.
    if (mounted) {
      await context.read<AuthState>().signIn('demo', displayName: p.displayName);
    }
    // GymState 재로딩 — MY BOX 소속 체육관 반영.
    if (mounted) {
      try {
        await context.read<GymState>().loadMine();
      } catch (_) {}
    }
    // ProfileState 즉시 교체 — tier 기반 합성 grade + 체형·벤치마크.
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
      _activeSeed = p.deviceIdSeed;
      _busy = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.displayName} (${p.shortLabel}) · ${p.tier} 전환 완료.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUICK SWITCH', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kQuickPersonas.map((p) {
              final isActive = _activeSeed == p.deviceIdSeed;
              final isCoach = p.role == 'coach_owner';
              final accentCol =
                  isCoach ? FacingTokens.tierElite : FacingTokens.muted;
              return Padding(
                padding: const EdgeInsets.only(right: FacingTokens.sp2),
                child: GestureDetector(
                  onTap: _busy ? null : () => _switch(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accentCol.withValues(alpha: 0.18)
                          : FacingTokens.bg,
                      border: Border.all(
                        color: isActive
                            ? accentCol
                            : FacingTokens.border,
                        width: isActive ? 1.5 : 1,
                      ),
                      borderRadius:
                          BorderRadius.circular(FacingTokens.r2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar circle
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentCol.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentCol.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p.displayName.substring(0, 1),
                              style: FacingTokens.body.copyWith(
                                color: accentCol,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.shortLabel,
                          style: FacingTokens.micro.copyWith(
                            color: isActive ? FacingTokens.fg : FacingTokens.muted,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                          ),
                        ),
                        Text(
                          p.displayName,
                          style: FacingTokens.micro.copyWith(
                            color: FacingTokens.muted,
                            fontSize: 10,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: FacingTokens.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// v1.16.2 (2026-05-24) — 내 회원권 카드 (진행 막대 + 월별 타임라인).
/// GymState.currentMembership 에서 fetch. 회원권 없으면 안 그림.
/// 갱신 시 늘어난 구간은 primary 색, 이미 지난 구간은 muted 색으로 분리.
class _MembershipCard extends StatelessWidget {
  const _MembershipCard();

  @override
  Widget build(BuildContext context) {
    final ms = context.watch<GymState>().currentMembership;
    if (ms == null) return const SizedBox.shrink();
    final days = ms.daysUntilExpiry;
    final progress = ms.progress ?? 0;
    final isExpiringSoon = days != null && days <= 14 && days >= 0;
    final isExpired = days != null && days < 0;
    Color accentColor;
    if (isExpired) {
      accentColor = FacingTokens.danger;
    } else if (isExpiringSoon) {
      accentColor = FacingTokens.warning;
    } else {
      accentColor = FacingTokens.primary;
    }

    DateTime? start;
    DateTime? end;
    try {
      if (ms.startDate != null) start = DateTime.parse(ms.startDate!);
      if (ms.endDate != null) end = DateTime.parse(ms.endDate!);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Container(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FacingTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MEMBERSHIP', style: FacingTokens.sectionLabel),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ms.planName ?? 'Active',
                  style: FacingTokens.h3.copyWith(color: FacingTokens.fg),
                ),
                const Spacer(),
                if (days != null)
                  Text(
                    isExpired ? 'EXPIRED' : 'D-${days.abs()}',
                    style:
                        FacingTokens.h3.copyWith(color: accentColor),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 진행 막대 — 사용 비율 = progress, 남은 비율 = 1-progress
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 8, color: FacingTokens.surfaceMax),
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: FacingTokens.mutedStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% 사용',
                  style: FacingTokens.caption,
                ),
                const Spacer(),
                Text(
                  '${((1 - progress) * 100).toStringAsFixed(0)}% 남음',
                  style: FacingTokens.caption
                      .copyWith(color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 월별 타임라인
            if (start != null && end != null)
              _MembershipTimeline(
                start: start,
                end: end,
                accent: accentColor,
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(ms.startDate ?? '', style: FacingTokens.caption),
                const Spacer(),
                Text(ms.endDate ?? '', style: FacingTokens.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// v1.16.2 — 회원권 월별 타임라인.
/// start ~ end 범위를 6 ~ 12 칸 셀로 분할해서 가로 띠로 렌더.
/// 셀 색: 지난 구간 = mutedStrong / 미래 구간 = accent (primary).
/// today 위치에 ▲ 마커, 위쪽에 월 라벨.
class _MembershipTimeline extends StatelessWidget {
  const _MembershipTimeline({
    required this.start,
    required this.end,
    required this.accent,
  });
  final DateTime start;
  final DateTime end;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final totalDays = end.difference(start).inDays.clamp(1, 9999);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final elapsedDays =
        today.difference(start).inDays.clamp(0, totalDays).toInt();
    final todayFraction = elapsedDays / totalDays;

    // 월 단위 라벨 — 시작 월부터 끝 월까지.
    final monthLabels = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(endMonth)) {
      monthLabels.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final todayX = (width * todayFraction).clamp(0, width).toDouble();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월 라벨 줄
          SizedBox(
            height: 14,
            child: Stack(
              clipBehavior: Clip.none,
              children: monthLabels.map((m) {
                final monthFrac =
                    m.difference(start).inDays / totalDays;
                final clamped = monthFrac.clamp(0, 1).toDouble();
                final x = (width * clamped).clamp(0, width - 22).toDouble();
                return Positioned(
                  left: x,
                  top: 0,
                  child: Text(
                    '${m.month}월',
                    style: FacingTokens.caption.copyWith(
                      color: m.month == now.month && m.year == now.year
                          ? accent
                          : FacingTokens.muted,
                      fontWeight: m.month == now.month && m.year == now.year
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // 타임라인 바 (왼쪽=과거 mutedStrong / 오른쪽=미래 accent)
          SizedBox(
            height: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 전체 배경
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: FacingTokens.surfaceMax,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // 지난 구간
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: todayX,
                  child: Container(
                    decoration: BoxDecoration(
                      color: FacingTokens.mutedStrong,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                // 미래 구간 (남은 회원권)
                Positioned(
                  left: todayX,
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                // today 마커
                Positioned(
                  left: todayX - 1,
                  top: -2,
                  bottom: -2,
                  width: 2,
                  child: Container(color: FacingTokens.fg),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // today 텍스트
          SizedBox(
            height: 14,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (todayX - 12).clamp(0, width - 24).toDouble(),
                  top: 0,
                  child: Text(
                    'TODAY',
                    style: FacingTokens.caption.copyWith(
                      color: FacingTokens.fg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// v1.16.2 (2026-05-24) — 내 락커 카드.
/// GymState.myLocker 에서 fetch. 배정된 락커 없으면 안 그림.
class _LockerCard extends StatelessWidget {
  const _LockerCard();

  @override
  Widget build(BuildContext context) {
    final lk = context.watch<GymState>().myLocker;
    if (lk == null) return const SizedBox.shrink();
    final days = lk.daysUntilExpiry;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4,
        FacingTokens.sp3,
        FacingTokens.sp4,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FacingTokens.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FacingTokens.surfaceMax,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(lk.lockerNo,
                  style:
                      FacingTokens.h3.copyWith(color: FacingTokens.fg)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MY LOCKER', style: FacingTokens.sectionLabel),
                  const SizedBox(height: 4),
                  Text(
                    lk.endDate != null && lk.endDate!.isNotEmpty
                        ? '${lk.endDate} 까지'
                        : '회원권 만료일 자동',
                    style: FacingTokens.body
                        .copyWith(color: FacingTokens.fg),
                  ),
                  if (lk.memo != null && lk.memo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(lk.memo!,
                          style: FacingTokens.caption),
                    ),
                ],
              ),
            ),
            if (days != null && days >= 0 && days <= 14)
              Text('D-$days',
                  style: FacingTokens.h3
                      .copyWith(color: FacingTokens.warning)),
          ],
        ),
      ),
    );
  }
}
