// v1.16.2 (2026-05-25) — 역할 라벨 한글 매핑 (gym_managers.role + gym_members.status).
// IdentityCard·CoachDashboard·BoxProfileScreen·MembersList 등에서 공통 사용.
// 정의 출처: ARCHITECTURE_BRIEF §2 RBAC 표.

/// 백엔드 role/status 조합을 한국어 라벨로 변환.
///
/// - `gym_managers.role`: owner/boss/coach/manager
/// - `gym_members.status`: approved/pending/rejected/left
///
/// 둘 다 비어있으면 빈 문자열 반환.
String roleKoLabel({String? role, String? status}) {
  if (role == 'owner') return '코치';
  if (role == 'boss') return '사장';
  if (role == 'coach') return '코치';
  if (role == 'manager') return '매니저';
  if (role == 'member') {
    switch (status) {
      case 'approved':
        return '회원';
      case 'pending':
        return '가입 대기';
      case 'rejected':
        return '거부됨';
      case 'left':
        return '탈퇴';
      default:
        return '회원';
    }
  }
  return '';
}
