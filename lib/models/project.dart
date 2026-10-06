class Project {
  final String id;
  final String title;
  final String role;
  final String description;
  final String technologies;
  final String link;

  Project({
    required this.id,
    this.title = '',
    this.role = '',
    this.description = '',
    this.technologies = '',
    this.link = '',
  });

  Project copyWith({
    String? id,
    String? title,
    String? role,
    String? description,
    String? technologies,
    String? link,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      role: role ?? this.role,
      description: description ?? this.description,
      technologies: technologies ?? this.technologies,
      link: link ?? this.link,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'role': role,
        'description': description,
        'technologies': technologies,
        'link': link,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? '',
        role: json['role'] as String? ?? '',
        description: json['description'] as String? ?? '',
        technologies: json['technologies'] as String? ?? '',
        link: json['link'] as String? ?? '',
      );
}
