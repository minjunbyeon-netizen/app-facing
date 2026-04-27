// v1.16 Sprint 8 U5: BTWB/Wodify Import placeholder 화면.
// ⚠️ **가상 UI** — 실제 Import 로직은 Phase 2. OAuth/CSV 파싱 TODO.

import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IMPORT DATA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: [
            const Text('SUPPORTED', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            _SourceRow(
              name: 'BTWB (Beyond the Whiteboard)',
              hint: 'CSV export / API · Phase 2',
            ),
            _SourceRow(
              name: 'Wodify',
              hint: 'API / CSV · Phase 2',
            ),
            _SourceRow(
              name: 'TrainHeroic',
              hint: 'CSV export · Phase 2',
            ),
            _SourceRow(
              name: 'Apple Health · Google Fit',
              hint: 'Cardio / 체중 동기화 · Phase 2',
            ),
            _SourceRow(
              name: 'Whoop · Oura',
              hint: 'HRV · 회복 데이터 · Phase 2',
            ),
            const SizedBox(height: FacingTokens.sp5),

            const Text('PHASE 2 ROADMAP', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const _Note(
              '1. BTWB 계정 OAuth 연동 → 동작별 PR 자동 임포트',
            ),
            const _Note(
              '2. CSV 업로드 (Wodify · TrainHeroic) → 벤치마크 일괄 입력',
            ),
            const _Note(
              '3. Apple Health / Google Fit → 체중·Run 기록 동기화',
            ),
            const _Note(
              '4. Whoop / Oura → HRV 기반 회복 상태 Pacing 보정',
            ),
            const SizedBox(height: FacingTokens.sp5),

            OutlinedButton(
              onPressed: () {
                Haptic.light();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Import는 Phase 2에서 지원 예정.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                // TODO(go): Phase 2 — BTWB OAuth SDK 연결.
              },
              child: const Text('BTWB 계정 연결 (Coming soon)'),
            ),
            const SizedBox(height: FacingTokens.sp3),
            OutlinedButton(
              onPressed: () {
                Haptic.light();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV 업로드는 Phase 2에서 지원 예정.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                // TODO(go): Phase 2 — file_picker + CSV 파서.
              },
              child: const Text('CSV 파일 업로드 (Coming soon)'),
            ),
            const SizedBox(height: FacingTokens.sp5),

            Text(
              '* 현재 Beta Preview. 위 외부 서비스 연동 없음.\n'
              '모든 데이터는 수동 입력 or 데모 계정 프리로드.',
              style: FacingTokens.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String name;
  final String hint;
  const _SourceRow({required this.name, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                )),
          ),
          Text(hint, style: FacingTokens.caption),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('·  ',
              style: TextStyle(color: FacingTokens.accent)),
          Expanded(child: Text(text, style: FacingTokens.body)),
        ],
      ),
    );
  }
}
