class Movement {
  final String slug;
  final String nameKo;
  final String unit;
  final String loadType;
  final List<String> requiredMetrics;

  const Movement({
    required this.slug,
    required this.nameKo,
    required this.unit,
    required this.loadType,
    required this.requiredMetrics,
  });

  bool get isCardio => unit == 'meters' || unit == 'calories';
  bool get hasLoad => loadType == 'barbell' || loadType == 'dumbbell';

  factory Movement.fromJson(Map<String, dynamic> j) => Movement(
    slug: j['slug'] as String,
    nameKo: j['name_ko'] as String,
    unit: j['unit'] as String,
    loadType: (j['load_type'] as String?) ?? 'none',
    requiredMetrics: ((j['required_metrics'] as List?) ?? const [])
        .map((e) => e.toString()).toList(),
  );
}

class MovementCategory {
  final String slug;
  final String nameKo;
  final List<Movement> movements;

  const MovementCategory({
    required this.slug,
    required this.nameKo,
    required this.movements,
  });

  factory MovementCategory.fromJson(Map<String, dynamic> j) => MovementCategory(
    slug: j['slug'] as String,
    nameKo: j['name_ko'] as String,
    movements: ((j['movements'] as List?) ?? const [])
        .map((e) => Movement.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}
