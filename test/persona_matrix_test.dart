// 10 페르소나 × 핵심 기능군 회귀 테스트 — v1.20 /go.
//
// services/facing/data/personas.json 시드 SSOT 기반으로:
// 1. Tier.fromOverallNumber 매핑 정합 (overall_number → 5-Tier)
// 2. LevelSystem.compute 가 모든 페르소나 입력에 대해 정상 분포
// 3. GymMembership 권한 분기 (isOwner / isApprovedMember / isPending / isRejected)
//    가 페르소나별 기대값과 일치
//
// 백엔드 endpoint 회귀는 services/facing/tests/test_personas_e2e.py 참조.
// 본 파일은 프론트 클라이언트 사이드 추론 회귀 전용.

import 'package:flutter_test/flutter_test.dart';
import 'package:facing_app/core/level_system.dart';
import 'package:facing_app/core/tier.dart';
import 'package:facing_app/models/gym.dart';

class _Persona {
  final String id;
  final String displayName;
  final String role; // admin | coach_owner | member | app_user
  final String tierLabel; // RX+ | Elite | RX | Scaled
  final int overallNumber; // 1-6
  final String? joinedBoxId;
  final String? membershipStatus; // approved | pending | rejected | null
  final int wodHistoryCount;

  const _Persona({
    required this.id,
    required this.displayName,
    required this.role,
    required this.tierLabel,
    required this.overallNumber,
    required this.joinedBoxId,
    required this.membershipStatus,
    required this.wodHistoryCount,
  });
}

const List<_Persona> _kPersonas = [
  _Persona(
      id: 'admin_01',
      displayName: '변민준',
      role: 'admin',
      tierLabel: 'RX+',
      overallNumber: 4,
      joinedBoxId: null,
      membershipStatus: null,
      wodHistoryCount: 8),
  _Persona(
      id: 'coach_a',
      displayName: '박지훈',
      role: 'coach_owner',
      tierLabel: 'Elite',
      overallNumber: 5,
      joinedBoxId: 'box_seongsu',
      membershipStatus: 'approved',
      wodHistoryCount: 14),
  _Persona(
      id: 'coach_b',
      displayName: '이수민',
      role: 'coach_owner',
      tierLabel: 'Elite',
      overallNumber: 5,
      joinedBoxId: 'box_gangnam',
      membershipStatus: 'approved',
      wodHistoryCount: 12),
  _Persona(
      id: 'member_a1',
      displayName: '김도윤',
      role: 'member',
      tierLabel: 'RX',
      overallNumber: 3,
      joinedBoxId: 'box_seongsu',
      membershipStatus: 'approved',
      wodHistoryCount: 11),
  _Persona(
      id: 'member_a2',
      displayName: '정하은',
      role: 'member',
      tierLabel: 'RX',
      overallNumber: 3,
      joinedBoxId: 'box_seongsu',
      membershipStatus: 'approved',
      wodHistoryCount: 9),
  _Persona(
      id: 'member_a3',
      displayName: '최서윤',
      role: 'member',
      tierLabel: 'Scaled',
      overallNumber: 2,
      joinedBoxId: 'box_seongsu',
      membershipStatus: 'pending',
      wodHistoryCount: 0),
  _Persona(
      id: 'member_b1',
      displayName: '강민재',
      role: 'member',
      tierLabel: 'RX+',
      overallNumber: 4,
      joinedBoxId: 'box_gangnam',
      membershipStatus: 'approved',
      wodHistoryCount: 13),
  _Persona(
      id: 'member_b2',
      displayName: '윤지원',
      role: 'member',
      tierLabel: 'RX',
      overallNumber: 3,
      joinedBoxId: 'box_gangnam',
      membershipStatus: 'approved',
      wodHistoryCount: 7),
  _Persona(
      id: 'member_b3',
      displayName: '한수아',
      role: 'member',
      tierLabel: 'Scaled',
      overallNumber: 2,
      joinedBoxId: 'box_gangnam',
      membershipStatus: 'rejected',
      wodHistoryCount: 0),
  _Persona(
      id: 'app_user_01',
      displayName: '송예준',
      role: 'app_user',
      tierLabel: 'RX',
      overallNumber: 3,
      joinedBoxId: null,
      membershipStatus: null,
      wodHistoryCount: 6),
];

GymMembership _toMembership(_Persona p) {
  GymSummary? gym;
  if (p.joinedBoxId != null) {
    gym = GymSummary(
      id: p.joinedBoxId == 'box_seongsu' ? 1 : 2,
      name: p.joinedBoxId == 'box_seongsu'
          ? 'FACING SEONGSU'
          : 'FACING GANGNAM',
      location: '',
      memberCount: 0,
    );
  }
  String? role;
  if (p.role == 'coach_owner') {
    role = 'owner';
  } else if (p.role == 'member') {
    role = 'member';
  }
  return GymMembership(gym: gym, role: role, status: p.membershipStatus);
}

void main() {
  group('페르소나 × Tier 매핑', () {
    for (final p in _kPersonas) {
      test('${p.id} (${p.displayName}) overall=${p.overallNumber} → ${p.tierLabel}',
          () {
        final t = Tier.fromOverallNumber(p.overallNumber);
        switch (p.tierLabel) {
          case 'Scaled':
            expect(t, Tier.scaled);
            break;
          case 'RX':
            expect(t, Tier.rx);
            break;
          case 'RX+':
            expect(t, Tier.rxPlus);
            break;
          case 'Elite':
            expect(t, Tier.elite);
            break;
          case 'Games':
            expect(t, Tier.games);
            break;
          default:
            fail('Unknown tier label: ${p.tierLabel}');
        }
      });
    }
  });

  group('페르소나 × LevelSystem.compute', () {
    test('모든 페르소나 compute 정상 분포 (Lv 1~50 + 음수 없음)', () {
      for (final p in _kPersonas) {
        final bd = LevelSystem.compute(
          totalSessions: p.wodHistoryCount,
          currentStreakDays: 0, // 시드 단계에서는 streak 미정 → 0 가정
          tierNumber: p.overallNumber,
          prCount: 0,
        );
        expect(bd.totalXp, greaterThanOrEqualTo(0),
            reason: '${p.id} totalXp 음수');
        expect(bd.level, inInclusiveRange(1, LevelSystem.maxLevel),
            reason: '${p.id} level out of range: ${bd.level}');
        expect(bd.progress, inInclusiveRange(0.0, 1.0),
            reason: '${p.id} progress out of [0,1]');
      }
    });

    test('coach_a (14 sessions, tier 5) → 1400+2500=3900 XP, Lv8', () {
      final bd = LevelSystem.compute(
        totalSessions: 14,
        currentStreakDays: 0,
        tierNumber: 5,
      );
      expect(bd.totalXp, 3900);
      // 9500=Lv20. 3900=Lv8 (linear 500/lv → 3500=Lv8 / 4000=Lv9 boundary)
      expect(bd.level, 8);
    });

    test('member_a3 (0 sessions, tier 2) → 0+1000=1000 XP, Lv3', () {
      final bd = LevelSystem.compute(
        totalSessions: 0,
        currentStreakDays: 0,
        tierNumber: 2,
      );
      expect(bd.totalXp, 1000);
      expect(bd.level, 3);
    });

    test('PR 추가 시 XP +250 per PR', () {
      final bd = LevelSystem.compute(
        totalSessions: 8,
        currentStreakDays: 5,
        tierNumber: 4,
        prCount: 2,
      );
      // 800 + 250 + 2000 + 500(PR×2) = 3550
      expect(bd.prXp, 500);
      expect(bd.totalXp, 3550);
    });
  });

  group('페르소나 × GymMembership 권한 분기', () {
    test('admin (no gym) → hasGym=false', () {
      final m = _toMembership(_kPersonas[0]);
      expect(m.hasGym, isFalse);
      expect(m.isOwner, isFalse);
      expect(m.isApprovedMember, isFalse);
    });

    test('coach_a (owner) → isOwner=true, isApprovedMember=false', () {
      final m = _toMembership(_kPersonas[1]);
      expect(m.hasGym, isTrue);
      expect(m.isOwner, isTrue);
      expect(m.isApprovedMember, isFalse);
    });

    test('member_a1 (approved) → isApprovedMember=true', () {
      final m = _toMembership(_kPersonas[3]);
      expect(m.hasGym, isTrue);
      expect(m.isOwner, isFalse);
      expect(m.isApprovedMember, isTrue);
      expect(m.isPending, isFalse);
      expect(m.isRejected, isFalse);
    });

    test('member_a3 (pending) → isPending=true', () {
      final m = _toMembership(_kPersonas[5]);
      expect(m.hasGym, isTrue);
      expect(m.isOwner, isFalse);
      expect(m.isPending, isTrue);
      expect(m.isApprovedMember, isFalse);
      expect(m.isRejected, isFalse);
    });

    test('member_b3 (rejected) → isRejected=true', () {
      final m = _toMembership(_kPersonas[8]);
      expect(m.hasGym, isTrue);
      expect(m.isRejected, isTrue);
      expect(m.isApprovedMember, isFalse);
      expect(m.isPending, isFalse);
    });

    test('app_user (no gym) → hasGym=false, no role/status', () {
      final m = _toMembership(_kPersonas[9]);
      expect(m.hasGym, isFalse);
      expect(m.isOwner, isFalse);
      expect(m.isApprovedMember, isFalse);
      expect(m.isPending, isFalse);
      expect(m.isRejected, isFalse);
    });
  });

  group('Inbox 접근 권한 분기 (UI gate 정합)', () {
    bool canAccessInbox(_Persona p) {
      final m = _toMembership(p);
      // mypage_screen._InboxEntry gate: isOwner || isApprovedMember
      return m.isOwner || m.isApprovedMember;
    }

    test('coach_a / coach_b → 인박스 접근 가능 (owner)', () {
      expect(canAccessInbox(_kPersonas[1]), isTrue); // coach_a
      expect(canAccessInbox(_kPersonas[2]), isTrue); // coach_b
    });

    test('member approved 4명 → 인박스 접근 가능', () {
      expect(canAccessInbox(_kPersonas[3]), isTrue); // a1
      expect(canAccessInbox(_kPersonas[4]), isTrue); // a2
      expect(canAccessInbox(_kPersonas[6]), isTrue); // b1
      expect(canAccessInbox(_kPersonas[7]), isTrue); // b2
    });

    test('admin / pending / rejected / app_user → 인박스 차단', () {
      expect(canAccessInbox(_kPersonas[0]), isFalse); // admin
      expect(canAccessInbox(_kPersonas[5]), isFalse); // a3 pending
      expect(canAccessInbox(_kPersonas[8]), isFalse); // b3 rejected
      expect(canAccessInbox(_kPersonas[9]), isFalse); // app_user
    });
  });

  group('WOD 화면 분기 정합 (BoxWodScreen 4분기)', () {
    String wodScreenState(_Persona p) {
      final m = _toMembership(p);
      if (!m.hasGym) return 'NoGymEmpty';
      if (m.isPending) return 'Pending';
      if (m.isRejected) return 'Rejected';
      return 'WodList'; // owner or approved member
    }

    test('admin → NoGymEmpty', () {
      expect(wodScreenState(_kPersonas[0]), 'NoGymEmpty');
    });
    test('coach_a/b → WodList (owner)', () {
      expect(wodScreenState(_kPersonas[1]), 'WodList');
      expect(wodScreenState(_kPersonas[2]), 'WodList');
    });
    test('member approved → WodList', () {
      for (final i in [3, 4, 6, 7]) {
        expect(wodScreenState(_kPersonas[i]), 'WodList',
            reason: _kPersonas[i].id);
      }
    });
    test('member_a3 pending → Pending', () {
      expect(wodScreenState(_kPersonas[5]), 'Pending');
    });
    test('member_b3 rejected → Rejected', () {
      expect(wodScreenState(_kPersonas[8]), 'Rejected');
    });
    test('app_user → NoGymEmpty', () {
      expect(wodScreenState(_kPersonas[9]), 'NoGymEmpty');
    });
  });

  group('총합 검증', () {
    test('10 페르소나 — 시드 데이터 무결성', () {
      expect(_kPersonas.length, 10);
      final ids = _kPersonas.map((p) => p.id).toSet();
      expect(ids.length, 10, reason: '페르소나 id 중복');
      // 역할 분포 확인 (personas.json _meta.distribution 동기화)
      final byRole = <String, int>{};
      for (final p in _kPersonas) {
        byRole[p.role] = (byRole[p.role] ?? 0) + 1;
      }
      expect(byRole['admin'], 1);
      expect(byRole['coach_owner'], 2);
      expect(byRole['member'], 6);
      expect(byRole['app_user'], 1);
    });

    test('멤버십 상태 분포 — approved 6, pending 1, rejected 1', () {
      final byStatus = <String, int>{};
      for (final p in _kPersonas) {
        if (p.role == 'member' || p.role == 'coach_owner') {
          byStatus[p.membershipStatus ?? 'null'] =
              (byStatus[p.membershipStatus ?? 'null'] ?? 0) + 1;
        }
      }
      expect(byStatus['approved'], 6); // 2 coach + 4 approved member
      expect(byStatus['pending'], 1);
      expect(byStatus['rejected'], 1);
    });
  });
}
