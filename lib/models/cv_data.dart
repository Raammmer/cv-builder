import 'personal_info.dart';
import 'work_experience.dart';
import 'education.dart';
import 'skill.dart';
import 'project.dart';
import 'certification.dart';

class CvData {
  final String id;
  final String title;
  final DateTime lastModified;
  final String selectedTemplate; // 'modern', 'executive', 'minimalist'
  final int accentColorHex;
  final PersonalInfo personalInfo;
  final List<WorkExperience> experiences;
  final List<Education> educations;
  final List<Skill> skills;
  final List<Project> projects;
  final List<Certification> certifications;

  CvData({
    required this.id,
    this.title = 'Untitled Resume',
    DateTime? lastModified,
    this.selectedTemplate = 'modern',
    this.accentColorHex = 0xFF2563EB, // Default Royal Blue
    PersonalInfo? personalInfo,
    List<WorkExperience>? experiences,
    List<Education>? educations,
    List<Skill>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
  })  : lastModified = lastModified ?? DateTime.now(),
        personalInfo = personalInfo ?? PersonalInfo(),
        experiences = experiences ?? [],
        educations = educations ?? [],
        skills = skills ?? [],
        projects = projects ?? [],
        certifications = certifications ?? [];

  CvData copyWith({
    String? id,
    String? title,
    DateTime? lastModified,
    String? selectedTemplate,
    int? accentColorHex,
    PersonalInfo? personalInfo,
    List<WorkExperience>? experiences,
    List<Education>? educations,
    List<Skill>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
  }) {
    return CvData(
      id: id ?? this.id,
      title: title ?? this.title,
      lastModified: lastModified ?? DateTime.now(),
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      personalInfo: personalInfo ?? this.personalInfo,
      experiences: experiences ?? List.from(this.experiences),
      educations: educations ?? List.from(this.educations),
      skills: skills ?? List.from(this.skills),
      projects: projects ?? List.from(this.projects),
      certifications: certifications ?? List.from(this.certifications),
    );
  }

  /// Calculates a completeness score (0-100) based on filled sections
  int get completenessScore {
    int score = 0;
    if (personalInfo.fullName.trim().isNotEmpty) score += 15;
    if (personalInfo.email.trim().isNotEmpty) score += 10;
    if (personalInfo.phone.trim().isNotEmpty) score += 5;
    if (personalInfo.summary.trim().isNotEmpty) score += 15;
    if (experiences.isNotEmpty) {
      score += 20;
      bool hasBullets = experiences.any((e) => e.bullets.isNotEmpty);
      if (hasBullets) score += 5;
    }
    if (educations.isNotEmpty) score += 15;
    if (skills.isNotEmpty) score += 10;
    if (projects.isNotEmpty || certifications.isNotEmpty) score += 5;
    return score.clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'lastModified': lastModified.toIso8601String(),
        'selectedTemplate': selectedTemplate,
        'accentColorHex': accentColorHex,
        'personalInfo': personalInfo.toJson(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'educations': educations.map((e) => e.toJson()).toList(),
        'skills': skills.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
      };

  factory CvData.fromJson(Map<String, dynamic> json) => CvData(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'My Resume',
        lastModified: json['lastModified'] != null
            ? DateTime.tryParse(json['lastModified'] as String) ?? DateTime.now()
            : DateTime.now(),
        selectedTemplate: json['selectedTemplate'] as String? ?? 'modern',
        accentColorHex: (json['accentColorHex'] as num?)?.toInt() ?? 0xFF2563EB,
        personalInfo: json['personalInfo'] != null
            ? PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>)
            : PersonalInfo(),
        experiences: (json['experiences'] as List<dynamic>?)
                ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        educations: (json['educations'] as List<dynamic>?)
                ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        skills: (json['skills'] as List<dynamic>?)
                ?.map((e) => Skill.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        projects: (json['projects'] as List<dynamic>?)
                ?.map((e) => Project.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        certifications: (json['certifications'] as List<dynamic>?)
                ?.map((e) => Certification.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
