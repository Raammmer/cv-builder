import 'package:flutter/material.dart';
import '../../models/cv_data.dart';

class MinimalistTemplateView extends StatelessWidget {
  final CvData cv;

  const MinimalistTemplateView({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    final p = cv.personalInfo;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.fullName.isNotEmpty ? p.fullName : 'Your Full Name',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w400, color: Color(0xFF0F172A), letterSpacing: -0.5),
          ),
          if (p.jobTitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              p.jobTitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            [p.email, p.phone, p.location, p.linkedin].where((e) => e.isNotEmpty).join('  •  '),
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 0.8, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Summary
          if (p.summary.isNotEmpty) ...[
            _minimalHeader('ABOUT ME'),
            Text(
              p.summary,
              style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black),
            ),
            const SizedBox(height: 16),
          ],

          // Experience
          if (cv.experiences.isNotEmpty) ...[
            _minimalHeader('EXPERIENCE'),
            ...cv.experiences.map((exp) {
              final title = [exp.role, exp.company].where((s) => s.isNotEmpty).join(' — ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${exp.startDate} – ${exp.isCurrent ? 'Present' : exp.endDate}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...exp.bullets.map((b) => Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('– ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
            const SizedBox(height: 12),
          ],

          // Projects
          if (cv.projects.isNotEmpty) ...[
            _minimalHeader('PROJECTS'),
            ...cv.projects.map((proj) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(proj.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A))),
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
                          child: Text('Stack: ${proj.technologies}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontStyle: FontStyle.italic)),
                        ),
                      Text(proj.description, style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B))),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Education
          if (cv.educations.isNotEmpty) ...[
            _minimalHeader('EDUCATION'),
            ...cv.educations.map((edu) {
              final degreeInfo = [
                if (edu.degree.isNotEmpty) edu.degree,
                if (edu.fieldOfStudy.isNotEmpty) 'in ${edu.fieldOfStudy}',
                if (edu.institution.isNotEmpty) edu.institution,
              ].join(', ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(degreeInfo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
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
            _minimalHeader('SKILLS & PROFICIENCIES'),
            Text(
              cv.skills.map((s) => s.name).join('   /   '),
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _minimalHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF0F172A)),
      ),
    );
  }
}
