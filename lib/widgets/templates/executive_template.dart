import 'package:flutter/material.dart';
import '../../models/cv_data.dart';

class ExecutiveTemplateView extends StatelessWidget {
  final CvData cv;

  const ExecutiveTemplateView({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(cv.accentColorHex);
    final p = cv.personalInfo;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Header
          Container(
            width: double.infinity,
            color: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  p.fullName.isNotEmpty ? p.fullName.toUpperCase() : 'YOUR FULL NAME',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                if (p.jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.jobTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (p.email.isNotEmpty) _bannerContact(Icons.email_outlined, p.email),
                    if (p.phone.isNotEmpty) _bannerContact(Icons.phone_outlined, p.phone),
                    if (p.location.isNotEmpty) _bannerContact(Icons.location_on_outlined, p.location),
                    if (p.linkedin.isNotEmpty) _bannerContact(Icons.link, p.linkedin),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                if (p.summary.isNotEmpty) ...[
                  _executiveHeader('EXECUTIVE PROFILE', accentColor),
                  Text(
                    p.summary,
                    style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                ],

                // Experience
                if (cv.experiences.isNotEmpty) ...[
                  _executiveHeader('PROFESSIONAL EXPERIENCE', accentColor),
                  ...cv.experiences.map((exp) {
                    final companyLocation = [exp.company, exp.location]
                        .where((s) => s.trim().isNotEmpty)
                        .join(' • ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  exp.role,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          if (companyLocation.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              companyLocation,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                          const SizedBox(height: 5),
                          ...exp.bullets.map((b) => Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.only(top: 6, right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        b,
                                        style: const TextStyle(fontSize: 11.5, height: 1.4, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],

                // Projects
                if (cv.projects.isNotEmpty) ...[
                  _executiveHeader('KEY PROJECTS', accentColor),
                  ...cv.projects.map((proj) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    proj.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                if (proj.link.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(proj.link, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                                ],
                              ],
                            ),
                            if (proj.technologies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('Technologies: ${proj.technologies}',
                                    style: TextStyle(fontSize: 11, color: accentColor, fontStyle: FontStyle.italic)),
                              ),
                            Text(proj.description, style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                ],

                // Education
                if (cv.educations.isNotEmpty) ...[
                  _executiveHeader('EDUCATION & ACADEMIC CREDENTIALS', accentColor),
                  ...cv.educations.map((edu) {
                    final degreeDetails = [
                      if (edu.degree.isNotEmpty) edu.degree,
                      if (edu.fieldOfStudy.isNotEmpty) edu.fieldOfStudy,
                      if (edu.institution.isNotEmpty) edu.institution,
                    ].join(' — ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              degreeDetails,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(edu.endDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Skills
                if (cv.skills.isNotEmpty) ...[
                  _executiveHeader('CORE COMPETENCIES', accentColor),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: cv.skills
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _executiveHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.1),
      ),
    );
  }

  Widget _bannerContact(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }
}
