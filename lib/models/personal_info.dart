class PersonalInfo {
  final String fullName;
  final String jobTitle;
  final String email;
  final String phone;
  final String location;
  final String website;
  final String linkedin;
  final String github;
  final String summary;
  final String photoBase64;

  PersonalInfo({
    this.fullName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.website = '',
    this.linkedin = '',
    this.github = '',
    this.summary = '',
    this.photoBase64 = '',
  });

  PersonalInfo copyWith({
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? location,
    String? website,
    String? linkedin,
    String? github,
    String? summary,
    String? photoBase64,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      linkedin: linkedin ?? this.linkedin,
      github: github ?? this.github,
      summary: summary ?? this.summary,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'jobTitle': jobTitle,
        'email': email,
        'phone': phone,
        'location': location,
        'website': website,
        'linkedin': linkedin,
        'github': github,
        'summary': summary,
        'photoBase64': photoBase64,
      };

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
        fullName: json['fullName'] as String? ?? '',
        jobTitle: (json['jobTitle'] ?? json['title']) as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: json['location'] as String? ?? '',
        website: json['website'] as String? ?? '',
        linkedin: json['linkedin'] as String? ?? '',
        github: json['github'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        photoBase64: json['photoBase64'] as String? ?? '',
      );
}
