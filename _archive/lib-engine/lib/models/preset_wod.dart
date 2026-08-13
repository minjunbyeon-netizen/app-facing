class PresetWodItem {
  final String movementSlug;
  final int? reps;
  final int? distanceM;
  final double? loadValue;
  final String loadUnit;
  final int position;

  const PresetWodItem({
    required this.movementSlug,
    this.reps,
    this.distanceM,
    this.loadValue,
    this.loadUnit = '',
    required this.position,
  });

  factory PresetWodItem.fromJson(Map<String, dynamic> j) => PresetWodItem(
    movementSlug: j['movement_slug'] as String,
    reps: (j['reps'] as num?)?.toInt(),
    distanceM: (j['distance_m'] as num?)?.toInt(),
    loadValue: (j['load_value'] as num?)?.toDouble(),
    loadUnit: (j['load_unit'] as String?) ?? '',
    position: (j['position'] as num? ?? 0).toInt(),
  );
}

class PresetWod {
  final String slug;
  final String nameKo;
  final String descriptionKo;
  final String category;
  final String wodType;
  final int? timeCapSec;
  final int? rounds;
  final List<PresetWodItem> items;
  final int? rxTimeAdvancedSec;

  const PresetWod({
    required this.slug,
    required this.nameKo,
    required this.descriptionKo,
    required this.category,
    required this.wodType,
    required this.timeCapSec,
    required this.rounds,
    required this.items,
    required this.rxTimeAdvancedSec,
  });

  factory PresetWod.fromJson(Map<String, dynamic> j) => PresetWod(
    slug: j['slug'] as String,
    nameKo: j['name_ko'] as String,
    descriptionKo: (j['description_ko'] as String?) ?? '',
    category: (j['category'] as String?) ?? 'girl',
    wodType: j['wod_type'] as String,
    timeCapSec: (j['time_cap_sec'] as num?)?.toInt(),
    rounds: (j['rounds'] as num?)?.toInt(),
    items: ((j['items'] as List?) ?? const [])
        .map((e) => PresetWodItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    rxTimeAdvancedSec: (j['rx_time_advanced_sec'] as num?)?.toInt(),
  );

  String get typeLabelKo {
    switch (wodType) {
      case 'for_time': return 'For Time';
      case 'amrap': return 'AMRAP';
      case 'emom': return 'EMOM';
      default: return wodType;
    }
  }

  String get timeCapLabelKo {
    if (timeCapSec == null) return '';
    final m = timeCapSec! ~/ 60;
    return '$m분';
  }
}
