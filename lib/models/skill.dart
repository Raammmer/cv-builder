class Skill {
  final String id;
  final String name;
  final String category;
  final int level; // 1 to 5

  Skill({
    required this.id,
    required this.name,
    this.category = 'Technical',
    this.level = 4,
  });

  Skill copyWith({
    String? id,
    String? name,
    String? category,
    int? level,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'level': level,
      };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? 'Technical',
        level: (json['level'] as num?)?.toInt() ?? 4,
      );
}
