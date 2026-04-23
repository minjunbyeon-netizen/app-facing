/// facing-app 용어 사전 SSOT.
/// GlossaryTip 위젯에서 long-press 시 표시.
/// VISUAL_CONCEPT.md · CLAUDE.md 용어 팔레트 동기화.
const Map<String, String> kGlossary = {
  '1RM': '1회 최대 중량. Max 1 rep.',
  'AMRAP': '정해진 시간 동안 최대 라운드.',
  'EMOM': '매 분 시작 시 동작 수행.',
  'RFT': 'Rounds For Time. 라운드 × N 최단 시간.',
  'Chipper': '동작 리스트를 위에서 아래로 한 번.',
  'Split': '라운드 사이 속도·분할 패턴.',
  'Burst': 'Split 중 폭발하는 전력 구간.',
  'Engine': '6 카테고리 종합 피지컬.',
  'Unbroken': '끊지 않고 연속 완료.',
  'UB': 'Unbroken 약자.',
  'RX': '표준 중량·난이도 완료.',
  'RX+': 'RX 초과 고난도.',
  'Scaled': '강도 낮춘 스케일드 버전.',
  'Elite': 'Regionals 급.',
  'Games': 'CrossFit Games 출전급.',
  'Metcon': 'Metabolic Conditioning. 대사 컨디셔닝.',
  'T2B': 'Toes To Bar. 바에 발끝 터치.',
  'HSPU': 'Handstand Push-Up. 물구나무 푸쉬업.',
  'WOD': "Workout of the Day. 오늘의 운동.",
  'PR': 'Personal Record. 개인 최고 기록.',
};

String? glossaryOf(String term) => kGlossary[term.toUpperCase()];
