import 'dart:convert';
import 'dart:ui' as ui;
import '../../widgets/mascot.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';

/// B-6 (2026-06-10) — 회원 전자계약: 목록 → 상세 → 서명패드 (결정4 풀스펙).
///
/// 백엔드 계약:
///   GET  /api/v1/member/me/contracts                — 목록 (template_name 포함)
///   GET  /api/v1/member/contracts/{id}              — 상세 (draft/sent → viewed 전환)
///   POST /api/v1/member/contracts/{id}/sign         — {signature_image_base64}
/// 서명패드는 외부 패키지 없이 CustomPaint 스트로크 → PNG → base64.
///
/// D102 (2026-08-30) — 상태 라벨(`status_label`)·서명 가능(`signable`)은 서버 정본
/// (services/hyphen api/contracts.py CONTRACT_STATUS_LABELS·contract_flags)을 그대로
/// 쓴다. 종전엔 여기 switch 와 PC 두 화면·검증 페이지가 같은 계약을 다르게 불렀다.

class ContractSummary {
  final int id;
  final String status;
  final String statusLabel;
  final bool signable;
  final String templateName;
  final String? createdAt;
  final String? signedAt;

  const ContractSummary({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.signable,
    required this.templateName,
    this.createdAt,
    this.signedAt,
  });

  factory ContractSummary.fromJson(Map<String, dynamic> j) => ContractSummary(
    id: (j['id'] as num).toInt(),
    status: (j['status'] ?? '') as String,
    statusLabel: (j['status_label'] ?? j['status'] ?? '') as String,
    signable: j['signable'] == true,
    templateName: (j['template_name'] ?? '') as String,
    createdAt: j['created_at'] as String?,
    signedAt: j['signed_at'] as String?,
  );
}

class ContractRepository {
  final ApiClient _api;
  const ContractRepository(this._api);

  Future<List<ContractSummary>> list() async {
    final raw = await _api.getList('/api/v1/member/me/contracts');
    return raw
        .whereType<Map>()
        .map((e) => ContractSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> detail(int id) =>
      _api.get('/api/v1/member/contracts/$id');

  Future<Map<String, dynamic>> sign(int id, String signatureBase64) =>
      _api.post('/api/v1/member/contracts/$id/sign', {
        'signature_image_base64': signatureBase64,
      });
}

// ──────────────────────────────────────────────────────────────────
// 목록 화면
// ──────────────────────────────────────────────────────────────────
class MemberContractsScreen extends StatefulWidget {
  const MemberContractsScreen({super.key});

  @override
  State<MemberContractsScreen> createState() => _MemberContractsScreenState();
}

class _MemberContractsScreenState extends State<MemberContractsScreen> {
  late Future<List<ContractSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = ContractRepository(context.read<ApiClient>()).list();
  }

  void _reload() {
    setState(() {
      _future = ContractRepository(context.read<ApiClient>()).list();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: const HkAppBar(title: '전자계약서'),
      body: SafeArea(
        child: FutureBuilder<List<ContractSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const HkLoading();
            }
            if (snap.hasError) {
              return HkErrorState(message: '불러오기 실패', onRetry: _reload);
            }
            final rows = snap.data ?? const [];
            if (rows.isEmpty) {
              return const HkEmptyState(
                title: '계약 없음',
                caption: '체육관이 계약서를 발급하면 여기에 표시.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              itemCount: rows.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: HyphenTokens.sp2),
              itemBuilder: (context, i) {
                final c = rows[i];
                return InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ContractDetailScreen(contractId: c.id),
                      ),
                    );
                    _reload(); // 서명 후 상태 갱신
                  },
                  child: HkCard(
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    radius: HyphenTokens.r2,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.templateName.isEmpty
                                    ? '계약서 #${c.id}'
                                    : c.templateName,
                                style: HyphenTokens.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (c.createdAt ?? '').split('T').first,
                                style: HyphenTokens.caption,
                              ),
                            ],
                          ),
                        ),
                        HkBadge(
                          c.statusLabel,
                          color: c.signable
                              ? HyphenTokens.primary
                              : HyphenTokens.muted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// 상세 + 서명
// ──────────────────────────────────────────────────────────────────
class ContractDetailScreen extends StatefulWidget {
  final int contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ContractRepository(
      context.read<ApiClient>(),
    ).detail(widget.contractId);
  }

  void _reload() {
    setState(() {
      _future = ContractRepository(
        context.read<ApiClient>(),
      ).detail(widget.contractId);
    });
  }

  Future<void> _openSignPad() async {
    final signed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SignaturePadScreen(contractId: widget.contractId),
      ),
    );
    if (signed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: const HkAppBar(title: '전자계약서'),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const HkLoading();
            }
            if (snap.hasError) {
              return HkErrorState(message: '불러오기 실패', onRetry: _reload);
            }
            final d = snap.data ?? const {};
            final status = (d['status'] ?? '') as String;
            // 서명 가능 여부·라벨은 서버 플래그 그대로 (D102).
            final signable = d['signable'] == true;
            final statusLabel = (d['status_label'] ?? status) as String;
            final vars = (d['variables'] as Map?) ?? const {};
            // 항목 이름은 서버 사전(variable_labels)을 그대로 쓴다 — 앱이
            // 옛날처럼 `member_name` 을 'member name' 으로 풀어 보여주던 자리
            // (2026-08-25 갭 해소. 사전 정본 = services/hyphen api/contracts.py
            // VARIABLE_LABELS §0-B). 사전에 없는 키는 원문 그대로 둔다.
            final varLabels = (d['variable_labels'] as Map?) ?? const {};
            final entries = vars.entries
                .where((e) => !e.key.toString().startsWith('gym_'))
                .toList();
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    children: [
                      Text(
                        (d['template_name'] ?? '') as String,
                        style: HyphenTokens.h2,
                      ),
                      const SizedBox(height: HyphenTokens.sp2),
                      HkBadge(
                        statusLabel,
                        color: signable
                            ? HyphenTokens.primary
                            : HyphenTokens.muted,
                      ),
                      // 서명 전 본문 열람 (2026-08-24 갭 해소 — 서버 렌더 텍스트).
                      if (((d['body_text'] as String?) ?? '').isNotEmpty) ...[
                        const SizedBox(height: HyphenTokens.sp4),
                        const HkSectionLabel('본문'),
                        const SizedBox(height: HyphenTokens.sp2),
                        HkCard(
                          padding: const EdgeInsets.all(HyphenTokens.sp3),
                          width: double.infinity,
                          radius: HyphenTokens.r2,
                          child: Text(
                            (d['body_text'] as String?) ?? '',
                            style: HyphenTokens.caption,
                          ),
                        ),
                      ],
                      const SizedBox(height: HyphenTokens.sp4),
                      const HkSectionLabel('내용'),
                      const SizedBox(height: HyphenTokens.sp2),
                      ...entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: HyphenTokens.sp2,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  varLabels[e.key]?.toString() ??
                                      e.key.toString().replaceAll('_', ' '),
                                  style: HyphenTokens.caption,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${e.value ?? ''}',
                                  style: HyphenTokens.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (d['signed_at'] != null) ...[
                        const SizedBox(height: HyphenTokens.sp3),
                        Text(
                          '서명 완료: ${(d['signed_at'] as String).split('T').first}',
                          style: HyphenTokens.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                if (signable)
                  Padding(
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    child: HkButton.primary('서명', onPressed: _openSignPad),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// 서명패드 — 외부 패키지 없이 CustomPaint 스트로크 → PNG base64
// ──────────────────────────────────────────────────────────────────
class SignaturePadScreen extends StatefulWidget {
  final int contractId;
  const SignaturePadScreen({super.key, required this.contractId});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final List<List<Offset>> _strokes = [];
  bool _submitting = false;
  final GlobalKey _padKey = GlobalKey();

  bool get _hasSignature => _strokes.any((s) => s.length > 1);

  void _start(Offset p) => setState(() => _strokes.add([p]));
  void _extend(Offset p) => setState(() => _strokes.last.add(p));

  Future<String> _exportBase64() async {
    final box = _padKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
    final img = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return base64Encode(bytes!.buffer.asUint8List());
  }

  Future<void> _submit() async {
    if (!_hasSignature || _submitting) return;
    setState(() => _submitting = true);
    Haptic.medium();
    final messenger = HkSnack.of(context);
    final navigator = Navigator.of(context);
    final repo = ContractRepository(context.read<ApiClient>());
    try {
      final b64 = await _exportBase64();
      await repo.sign(widget.contractId, b64);
      Haptic.heavy();
      messenger.info('서명 완료.', mood: MascotMood.happy);
      navigator.pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.fail(e.messageKo);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.fail('서명 제출 실패. 잠시 후 재시도.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: HkAppBar(
        title: '서명',
        actions: [
          HkButton.tertiary(
            '지우기',
            onPressed: _submitting ? null : () => setState(_strokes.clear),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              child: Text(
                '아래 영역에 서명. 전자서명법 제3조에 따라 효력 발생.',
                style: HyphenTokens.caption,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HyphenTokens.sp4,
                ),
                child: Container(
                  key: _padKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: HyphenTokens.border),
                    borderRadius: BorderRadius.circular(HyphenTokens.r2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(HyphenTokens.r2),
                    child: GestureDetector(
                      onPanStart: (d) => _start(d.localPosition),
                      onPanUpdate: (d) => _extend(d.localPosition),
                      child: CustomPaint(
                        painter: _SignaturePainter(_strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              // 버튼 자리 그대로 busy — 누르는 순간 스피너로 갈아 끼우면 위 패드가 밀린다 (D67).
              child: HkButton.primary(
                '제출',
                busy: _submitting,
                onPressed: _hasSignature && !_submitting ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  const _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
