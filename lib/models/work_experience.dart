class WorkExperience {
  final String id;
  final String company;
  final String role;
  final String location;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final List<String> bullets;

  WorkExperience({
    required this.id,
    this.company = '',
    this.role = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.isCurrent = false,
    List<String>? bullets,
  }) : bullets = bullets ?? [];

  WorkExperience copyWith({
    String? id,
    String? company,
    String? role,
    String? location,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    List<String>? bullets,
  }) {
    return WorkExperience(
      id: id ?? this.id,
      company: company ?? this.company,
      role: role ?? this.role,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      bullets: bullets ?? List.from(this.bullets),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company': company,
        'role': role,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
        'bullets': bullets,
      };

  factory WorkExperience.fromJson(Map<String, dynamic> json) => WorkExperience(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        company: json['company'] as String? ?? '',
        role: json['role'] as String? ?? '',
        location: json['location'] as String? ?? '',
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
        isCurrent: json['isCurrent'] as bool? ?? false,
        bullets: (json['bullets'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}
