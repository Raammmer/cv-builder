class Certification {
  final String id;
  final String name;
  final String issuer;
  final String issueDate;
  final String credentialUrl;

  Certification({
    required this.id,
    this.name = '',
    this.issuer = '',
    this.issueDate = '',
    this.credentialUrl = '',
  });

  Certification copyWith({
    String? id,
    String? name,
    String? issuer,
    String? issueDate,
    String? credentialUrl,
  }) {
    return Certification(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      credentialUrl: credentialUrl ?? this.credentialUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'issuer': issuer,
        'issueDate': issueDate,
        'credentialUrl': credentialUrl,
      };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        issueDate: json['issueDate'] as String? ?? '',
        credentialUrl: json['credentialUrl'] as String? ?? '',
      );
}
