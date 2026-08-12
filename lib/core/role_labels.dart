// v1.16.2 (2026-05-25) — 역할 라벨 한글 매핑 (gym_managers.role + gym_members.status).
// IdentityCard·CoachDashboard·BoxProfileScreen·MembersList 등에서 공통 사용.
// 정의 출처: ARCHITECTURE_BRIEF §2 RBAC 표.

/// 백엔드 role/status 조합을 한국어 라벨로 변환.
///
/// - `gym_managers.role`: owner/boss/coach/manager
/// - `gym_members.status`: approved/pending/rejected/left
///
/// 둘 다 비어있으면 빈 문자열 반환.
///
/// v2.6 (2026-08-12 사용자 지시) — **운영자 호칭은 '코치' 하나뿐**이다.
/// role 값이 owner든 boss든 manager든 사람이 읽는 말은 전부 '코치'.
/// DB·API 값은 계약이라 그대로 두고, 번역은 여기 한 곳에서만 한다
/// (표기 정본 = `docs/GLOSSARY.md`). 화면 코드에 '사장'·'오너' 직접 타이핑 금지.
String roleKoLabel({String? role, String? status}) {
  if (role == 'owner') return '코치';
  if (role == 'boss') return '코치';
  if (role == 'coach') return '코치';
  if (role == 'manager') return '코치';
  if (role == 'member') {
    switch (status) {
      case 'approved':
        return '회원';
      // v2.6: 역할은 코치·회원·회원신청자 셋뿐 (BRIEF §2-0-1). 심사 대기 중인
      // 사람은 '가입 대기'(상태 말투)가 아니라 '회원신청자'로 부른다.
      case 'pending':
        return '회원신청자';
      case 'rejected':
        return '거절됨';
      case 'left':
        return '탈퇴';
      default:
        return '회원';
    }
  }
  return '';
}
