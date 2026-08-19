import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_clock.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import 'boss_api_client.dart';
import 'class_roster_model.dart';

/// G24 (2026-08-18) — 코치 폰 수업 등록 시트.
///
/// 수업 생성은 PC(classes.html)가 주 동선이지만, 자리에 없는 코치가 폰으로
/// 급히 한 타임을 여는 보조 수단이 없었다 (갭대장 G24). 대시보드(예약 현황 탭)
/// '오늘 수업' 헤더의 버튼에서 열린다.
///
/// POST /api/v1/admin/gyms/{gym_id}/classes
///   body: start_at(ISO, 필수) · duration_minutes(기본 60) · capacity(기본 12) ·
///         title · track(≤20자, 선택). color 는 폰에서 받지 않는다 (토큰 정책 —
///         색 지정은 PC 화면 몫).
///
/// 반환: 등록에 성공했으면 true (스와이프로 내리면 null → false).
/// 호출부는 true 일 때 대시보드를 재조회한다.
Future<bool> showClassComposeSheet(BuildContext context, int gymId) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: HyphenTokens.bg,
    isScrollControlled: true,
    builder: (_) => _ClassComposeSheet(gymId: gymId),
  );
  return created == true;
}

/// G24 2차 (2026-08-19) — 같은 시트의 수정 모드. 명단 시트 '수업 수정' 에서
/// 열리고, 명단 응답([ClassRoster])으로 프리필한다.
///
/// PATCH /api/v1/admin/classes/{id}
///   body: title · duration_minutes · capacity · track (빈 문자열 = 트랙 해제).
///   start_at 은 PATCH 계약에 없다 (PC 도 동일) — 시간은 읽기 전용으로 보여주고
///   시간 변경은 수업 취소 후 재등록으로 안내한다.
///
/// 반환: 저장했으면 true. 호출부는 true 일 때 명단·대시보드를 재조회한다.
Future<bool> showClassEditSheet(BuildContext context, ClassRoster roster) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: HyphenTokens.bg,
    isScrollControlled: true,
    builder: (_) => _ClassComposeSheet(edit: roster),
  );
  return saved == true;
}

class _ClassComposeSheet extends StatefulWidget {
  /// 등록 모드에서만 사용 (POST 경로의 gym id). 수정 모드는 null.
  final int? gymId;

  /// null 이면 등록 모드, 있으면 이 수업의 수정 모드.
  final ClassRoster? edit;

  const _ClassComposeSheet({this.gymId, this.edit})
      : assert(gymId != null || edit != null);

  @override
  State<_ClassComposeSheet> createState() => _ClassComposeSheetState();
}

class _ClassComposeSheetState extends State<_ClassComposeSheet> {
  // 백엔드 기본값(60분·12명)을 그대로 보여주고 시작한다 — 대부분의 수업이
  // 이 값이라 코치가 실제로 고르는 것은 시각 하나다.
  final _titleCtrl = TextEditingController(text: '수업');
  final _durationCtrl = TextEditingController(text: '60');
  final _capacityCtrl = TextEditingController(text: '12');
  final _trackCtrl = TextEditingController();

  /// 기본 시작 시각 = 다음 정시. 지금 여는 코치는 대개 "곧 시작할 한 타임"을
  /// 만들므로 지나간 시각을 기본값으로 주지 않는다.
  late DateTime _date;
  late TimeOfDay _time;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    if (edit != null) {
      _titleCtrl.text = edit.title;
      if (edit.durationMinutes != null) {
        _durationCtrl.text = '${edit.durationMinutes}';
      }
      if (edit.capacity != null) _capacityCtrl.text = '${edit.capacity}';
      _trackCtrl.text = edit.track ?? '';
      // 일시는 읽기 전용 표시용 — 파싱 실패 시 오늘 00:00 으로라도 그린다
      // (어차피 전송 안 함).
      final t = DateTime.tryParse(edit.startAt) ?? appClock.now();
      _date = DateTime(t.year, t.month, t.day);
      _time = TimeOfDay(hour: t.hour, minute: t.minute);
      return;
    }
    final now = appClock.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _capacityCtrl.dispose();
    _trackCtrl.dispose();
    super.dispose();
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  String get _dateLabel =>
      '${_date.year}-${_two(_date.month)}-${_two(_date.day)}';

  String get _timeLabel => '${_two(_time.hour)}:${_two(_time.minute)}';

  /// 백엔드 계약 형식 — '2026-08-18T19:00:00' (초는 항상 00).
  String get _startAtIso => '${_dateLabel}T$_timeLabel:00';

  Future<void> _pickDate() async {
    final now = appClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      // '오늘' 링 기준 시각도 appClock — 미지정 시 Material 내부 DateTime.now()
      // 를 써서 골든이 실제 날짜에 흔들린다 (시각은 appClock 만).
      currentDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_saving) return;
    final duration = int.tryParse(_durationCtrl.text.trim());
    if (duration == null || duration <= 0) {
      setState(() => _error = '진행 시간(분)은 1 이상 숫자.');
      return;
    }
    final capacity = int.tryParse(_capacityCtrl.text.trim());
    if (capacity == null || capacity <= 0) {
      setState(() => _error = '정원은 1 이상 숫자.');
      return;
    }
    final title = _titleCtrl.text.trim();
    final track = _trackCtrl.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });
    Haptic.medium();

    // await 전에 BuildContext 의존 객체 캡처 (async gap).
    final api = context.read<BossApiClient>();
    final navigator = Navigator.of(context);
    try {
      if (_isEdit) {
        // track 은 빈 문자열도 보낸다 — 백엔드가 '' 를 None 으로 저장해
        // 트랙 해제가 된다 (admin_patch_class 계약).
        await api.patch(
            '/api/v1/admin/classes/${widget.edit!.classSessionId}', {
          'title': title.isEmpty ? '수업' : title,
          'duration_minutes': duration,
          'capacity': capacity,
          'track': track,
        });
      } else {
        await api.post('/api/v1/admin/gyms/${widget.gymId}/classes', {
          'start_at': _startAtIso,
          'duration_minutes': duration,
          'capacity': capacity,
          'title': title.isEmpty ? '수업' : title,
          if (track.isNotEmpty) 'track': track,
        });
      }
      navigator.pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.messageKo;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _isEdit ? '수업 수정 실패' : '수업 등록 실패';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HyphenTokens.sp4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_isEdit ? '수업 수정' : '수업 등록',
                    style: HyphenTokens.h3.copyWith(color: HyphenTokens.fg)),
                const SizedBox(height: 4),
                Text(
                    _isEdit
                        ? '변경 내용은 회원 화면에 바로 반영됩니다.'
                        : '등록 즉시 회원 예약이 열립니다.',
                    style: HyphenTokens.caption),
                const SizedBox(height: HyphenTokens.sp4),

                TextField(
                  controller: _titleCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                const SizedBox(height: HyphenTokens.sp3),

                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: '날짜',
                        value: _dateLabel,
                        onTap: _saving || _isEdit ? null : _pickDate,
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Expanded(
                      child: _PickerField(
                        label: '시작 시간',
                        value: _timeLabel,
                        onTap: _saving || _isEdit ? null : _pickTime,
                      ),
                    ),
                  ],
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 4),
                  // PATCH 계약에 start_at 이 없다 (PC 동일) — 여기서만 안내.
                  const Text('시간 변경은 수업 취소 후 재등록.',
                      style: HyphenTokens.caption),
                ],
                const SizedBox(height: HyphenTokens.sp3),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _durationCtrl,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: '진행 시간(분)'),
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Expanded(
                      child: TextField(
                        controller: _capacityCtrl,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '정원'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HyphenTokens.sp3),

                TextField(
                  controller: _trackCtrl,
                  enabled: !_saving,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: '트랙 (선택)',
                    hintText: '예: 초급반',
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: HyphenTokens.sp2),
                  Text(_error!,
                      style: HyphenTokens.caption
                          .copyWith(color: HyphenTokens.warning)),
                ],
                const SizedBox(height: HyphenTokens.sp4),

                HkButton.primary(
                  _isEdit ? (_saving ? '저장 중' : '저장') : (_saving ? '등록 중' : '등록'),
                  onPressed: _saving ? null : _submit,
                ),
                const SizedBox(height: HyphenTokens.sp2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 탭하면 피커가 뜨는 읽기 전용 필드 — TextField 와 같은 InputDecoration 규격.
/// (TextField readOnly + 컨트롤러 동기화보다 상태 하나로 끝나는 이쪽이 단순하다.)
class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _PickerField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HyphenTokens.r3),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value,
          style: HyphenTokens.body.copyWith(
            color: HyphenTokens.fg,
            fontFeatures: HyphenTokens.tabular,
          ),
        ),
      ),
    );
  }
}
