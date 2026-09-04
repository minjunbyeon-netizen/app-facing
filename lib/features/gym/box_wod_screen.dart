import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import '../../widgets/inbox_bell.dart';
import 'gym_state.dart';
import 'week_board.dart';
import 'membership_status_view.dart';

/// v1.15.3: WOD 탭 진입점. GymState 상태 따라 4분기 렌더.
class BoxWodScreen extends StatefulWidget {
  /// 코치 셸에 얹힐 때는 자기 AppBar 를 그리지 않는다 — 상단바는 셸이 하나만
  /// 갖는다 (v3.23). 회원 셸(MainShell)은 종전대로 각 탭이 제목을 갖는다.
  final bool embedded;

  const BoxWodScreen({super.key, this.embedded = false});

  @override
  State<BoxWodScreen> createState() => _BoxWodScreenState();
}

class _BoxWodScreenState extends State<BoxWodScreen> {
  // v2.9 (2026-08-14): 앱바 새로고침이 GymState.loadMine() 만 불러서 주간보드의
  // 수업(class_sessions)은 그대로였다 — PC 에서 코치가 수업을 등록해도 이 버튼으론
  // 안 보이는 버그. 당겨서 새로고침(_WodList._refresh)과 같은 일을 하도록
  // 리스트 상태에 키로 손을 뻗고, 리스트가 없는 분기(미가입·대기·거절)에서만
  // WOD 상태 재로드로 폴백한다.
  final GlobalKey<_WodListState> _listKey = GlobalKey<_WodListState>();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();

    Widget body;
    if (gs.isLoading && !gs.hasGym) {
      body = const HkLoading();
    } else if (!gs.hasGym && gs.error != null) {
      // D118 (2026-09-05 · 에뮬 실주행에서 잡음) — **못 읽은 것을 '미가입' 이라
      // 말하지 않는다.** 종전엔 `hasGym` 만 보고 갈라서, 승인된 회원이 통신 실패
      // 한 번에 '체육관 미가입' 을 봤고 다시 시도할 길이 없어 앱을 껐다 켜야 했다
      // (홈 도전 섹션의 0px 실패 숨김과 같은 병 · 제1원칙: 화면은 거짓말하지 않는다).
      body = HkErrorState(
        message: gs.error!,
        onRetry: () {
          Haptic.light();
          gs.loadMine();
        },
      );
    } else if (!gs.hasGym) {
      // v3.25: 미가입·대기·거절 화면은 MembershipStatusView 한 벌 (셸 게이트와 동일).
      body = const MembershipStatusView.none();
    } else if (gs.membership.isPending) {
      body = MembershipStatusView.pending(
        gymName: gs.membership.gym!.name,
        onRecheck: () {
          Haptic.light();
          gs.loadMine();
        },
      );
    } else if (gs.membership.isRejected) {
      body = MembershipStatusView.rejected(gymName: gs.membership.gym!.name);
    } else {
      // owner or approved member
      body = _WodList(key: _listKey, gymState: gs);
    }

    return Scaffold(
      // v3.23 (2026-08-25 사용자 지시 "상단화면 통일하라고 1개로"): 코치 셸에
      // 얹힐 때는 상단바를 그리지 않는다 — 셸이 하나만 갖는다. 회원 셸에서는
      // 종전 그대로 (제목 '수업' + 종 + 새로고침).
      appBar: widget.embedded
          ? null
          : HkAppBar(
              title: '수업',
              actions: [
                // v3.28: 코치 분기(배지·가입 신청 아이콘) 제거 — 회원 전용 화면.
                const InboxBellAction(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    Haptic.light();
                    final list = _listKey.currentState;
                    if (list != null) {
                      list.refreshAll();
                    } else {
                      context.read<GymState>().loadMine();
                    }
                  },
                ),
              ],
            ),
      // v3.20 (2026-08-25 사용자 지시): '수업 내용 게시' FAB 삭제 —
      // 수업 내용은 PC 에서 쓴다. 폰의 이 탭은 코치에게도 **보는 화면**이다
      // (README §제거된 기능 대장 16). 삭제 아이콘도 같이 내렸다 — 폰에서
      // 지울 수는 있는데 다시 쓸 수는 없으면 그게 더 나쁜 상태다.
      body: SafeArea(child: body),
    );
  }
}

// (구 _NoGymEmpty·_PendingState·_RejectedState 는 v3.25 에서
//  gym/membership_status_view.dart 로 통합 — 셸 게이트와 같은 화면.)

/// v2.4 (2026-08-12 사용자 지시): 주간 아코디언 하나로 통일.
/// 오늘·예정·지난 3섹션 + 하단 수업 목록을 따로 쌓던 구조를 걷고, 그 주 월~일
/// 7줄 안에서 날짜를 눌러 그날 WOD·수업을 함께 본다 (week_board.dart).
class _WodList extends StatefulWidget {
  final GymState gymState;
  const _WodList({super.key, required this.gymState});

  @override
  State<_WodList> createState() => _WodListState();
}

class _WodListState extends State<_WodList> {
  // 새로고침은 WOD(GymState) 와 수업(WeekBoard 내부 fetch) 둘 다 다시
  // 받아야 한다. key 를 갈아 WeekBoard 를 새로 만드는 것이 가장 단순한 배선.
  // v2.9: 앱바 새로고침 버튼도 이 메서드를 쓴다 (당겨서 새로고침과 동일 경로).
  int _tick = 0;

  Future<void> refreshAll() async {
    await context.read<GymState>().loadMine();
    if (mounted) setState(() => _tick++);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: refreshAll,
          child: ListView(
            padding: const EdgeInsets.all(HyphenTokens.sp3),
            children: [
              // 불러오기가 실패한 날에도 요일 줄은 그려진다 — 그대로 두면 '게시된
              // 수업 내용 없음' 으로 읽혀 코치가 안 올린 것처럼 보인다. 실패는
              // 실패라고 먼저 말한다 (2026-08-12).
              //
              // v3.34 (2026-08-27): 그 배너가 `if (error != null)` 로 생겼다
              // 사라지면서 주간 보드·체육관 정보·공지가 통째로 밀렸다 — 앱의 기본
              // 진입 탭이라 체감이 가장 큰 자리다.
              //
              // v3.35 (2026-08-27 실기 확인): 자리를 항상 잡는 방식(HkNoticeSlot)으로
              // 밀림은 없앴으나, 에러는 **거의 안 나는데** 기본 진입 탭 맨 위에 56px 빈
              // 띠가 상시로 남았다 — 갤S22 캡처에서 바로 드러났다. 오프라인 배너와 같은
              // 판단으로 **겹쳐 띄우기**로 바꾼다: 정상일 때 0px, 에러가 떠도 아래 y 불변
              // (widgets/offline_banner.dart OfflineBannerOverlay 와 같은 처방 —
              // DESIGN-SSOT §레이아웃 안정성 "배너는 밀지 말고 겹친다").
              // 말하는 내용·재시도 동선은 그대로다.
              WeekBoard(
                key: ValueKey('week-$_tick'),
                gymState: widget.gymState,
              ),
              // v3.43 (2026-08-29 사용자 지시): 하단 '체육관 정보'·'공지' 아코디언 삭제.
              // 공지는 **홈에서만** 본다(검정 전광판). 체육관 정보는 이 탭의 일이 아니다.
            ],
          ),
        ),
        // 실패 배너는 본문 위에 겹친다 — 정상일 때 0px, 떠도 아래가 안 밀린다.
        if (widget.gymState.error != null)
          Positioned(
            top: 0,
            left: HyphenTokens.sp3,
            right: HyphenTokens.sp3,
            child: HkNoticeSlot(widget.gymState.error, onRetry: refreshAll),
          ),
      ],
    );
  }
}

/// v1.26 (2026-06-11): 박스 공지를 WOD 보드 상단으로 — Rehab 탭 전환에 따라
/// 공지 노출처를 WOD(여기) + Attend(MessagingFeed) 로 이원화.
/// 기본 접힘 — 최신 공지 1건 헤드라인. 펼치면 최신 3건 (pinned 우선).
