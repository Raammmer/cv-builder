class Education {
  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startDate;
  final String endDate;
  final String gradeOrGpa;
  final String description;

  Education({
    required this.id,
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.startDate = '',
    this.endDate = '',
    this.gradeOrGpa = '',
    this.description = '',
  });

  Education copyWith({
    String? id,
    String? institution,
    String? degree,
    String? fieldOfStudy,
    String? startDate,
    String? endDate,
    String? gradeOrGpa,
    String? description,
  }) {
    return Education(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gradeOrGpa: gradeOrGpa ?? this.gradeOrGpa,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'institution': institution,
        'degree': degree,
        'fieldOfStudy': fieldOfStudy,
        'startDate': startDate,
        'endDate': endDate,
        'gradeOrGpa': gradeOrGpa,
        'description': description,
      };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        institution: json['institution'] as String? ?? '',
        degree: json['degree'] as String? ?? '',
        fieldOfStudy: json['fieldOfStudy'] as String? ?? '',
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
        gradeOrGpa: json['gradeOrGpa'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}
