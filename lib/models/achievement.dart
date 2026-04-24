// v1.16: Achievement DTO.

class AchievementCatalog {
  final String code;
  final String name;
  final String description;
  final String rarity; // Common|Rare|Epic|Legendary
  final bool isHidden;
  final int sortOrder;

  const AchievementCatalog({
    required this.code,
    required this.name,
    required this.description,
    required this.rarity,
    required this.isHidden,
    required this.sortOrder,
  });

  factory AchievementCatalog.fromJson(Map<String, dynamic> j) =>
      AchievementCatalog(
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        rarity: (j['rarity'] ?? 'Common').toString(),
        isHidden: j['is_hidden'] == true,
        sortOrder: ((j['sort_order'] ?? 0) as num).toInt(),
      );
}

class AchievementUnlock {
  final String code;
  final DateTime unlockedAt;
  final Map<String, dynamic> context;

  const AchievementUnlock({
    required this.code,
    required this.unlockedAt,
    this.context = const {},
  });

  factory AchievementUnlock.fromJson(Map<String, dynamic> j) =>
      AchievementUnlock(
        code: (j['code'] ?? '').toString(),
        unlockedAt: DateTime.parse(j['unlocked_at'] as String),
        context: j['context'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(j['context'] as Map)
            : const {},
      );
}

class AchievementSnapshot {
  final List<AchievementCatalog> catalog;
  final Map<String, AchievementUnlock> unlocked; // code → unlock
  final int unlockedCount;
  final int visibleCount;

  const AchievementSnapshot({
    required this.catalog,
    required this.unlocked,
    required this.unlockedCount,
    required this.visibleCount,
  });

  bool isUnlocked(String code) => unlocked.containsKey(code);

  factory AchievementSnapshot.fromJson(Map<String, dynamic> j) {
    final catalogRaw = (j['catalog'] as List? ?? const []);
    final unlockedRaw = (j['unlocked'] as List? ?? const []);
    final unlockedMap = <String, AchievementUnlock>{};
    for (final u in unlockedRaw.whereType<Map<String, dynamic>>()) {
      final au = AchievementUnlock.fromJson(u);
      unlockedMap[au.code] = au;
    }
    return AchievementSnapshot(
      catalog: catalogRaw
          .whereType<Map<String, dynamic>>()
          .map(AchievementCatalog.fromJson)
          .toList(),
      unlocked: unlockedMap,
      unlockedCount: ((j['unlocked_count'] ?? 0) as num).toInt(),
      visibleCount: ((j['visible_count'] ?? 0) as num).toInt(),
    );
  }

  static const AchievementSnapshot empty = AchievementSnapshot(
    catalog: [],
    unlocked: {},
    unlockedCount: 0,
    visibleCount: 0,
  );
}

/// POST /check 응답.
class AchievementUnlockResult {
  final String code;
  final String name;
  final String rarity;

  const AchievementUnlockResult({
    required this.code,
    required this.name,
    required this.rarity,
  });

  factory AchievementUnlockResult.fromJson(Map<String, dynamic> j) =>
      AchievementUnlockResult(
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        rarity: (j['rarity'] ?? 'Common').toString(),
      );
}
