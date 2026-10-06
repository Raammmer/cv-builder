import 'package:flutter/material.dart';
import '../../models/cv_data.dart';

class ModernTemplateView extends StatelessWidget {
  final CvData cv;

  const ModernTemplateView({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(cv.accentColorHex);
    final p = cv.personalInfo;

    return Theme(
      data: ThemeData.light(),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF0F172A)),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName.isNotEmpty ? p.fullName : 'Your Full Name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.jobTitle.isNotEmpty ? p.jobTitle : 'Desired Job Title',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (p.email.isNotEmpty) _contactRow(Icons.email_outlined, p.email),
                      if (p.phone.isNotEmpty) _contactRow(Icons.phone_outlined, p.phone),
                      if (p.location.isNotEmpty) _contactRow(Icons.location_on_outlined, p.location),
                      if (p.linkedin.isNotEmpty) _contactRow(Icons.link, p.linkedin),
                      if (p.github.isNotEmpty) _contactRow(Icons.code, p.github),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Container(height: 2.5, color: accentColor),
              const SizedBox(height: 16),

              // Summary
              if (p.summary.isNotEmpty) ...[
                _sectionTitle('Professional Summary', accentColor),
                Text(
                  p.summary,
                  style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black),
                ),
                const SizedBox(height: 16),
              ],

              // Experience
              if (cv.experiences.isNotEmpty) ...[
                _sectionTitle('Work Experience', accentColor),
                ...cv.experiences.map((exp) => Padding(
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
                                '${exp.startDate} – ${exp.isCurrent ? 'Present' : exp.endDate}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          Text(
                            '${exp.company}${exp.location.isNotEmpty ? " • ${exp.location}" : ""}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                          ),
                          const SizedBox(height: 4),
                          ...exp.bullets.map((b) => Padding(
                                padding: const EdgeInsets.only(left: 6, bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        b,
                                        style: const TextStyle(fontSize: 11.5, height: 1.45, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
              ],

              // Projects
              if (cv.projects.isNotEmpty) ...[
                _sectionTitle('Key Projects', accentColor),
                ...cv.projects.map((proj) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(proj.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.black)),
                              ),
                              if (proj.link.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(proj.link, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                              ],
                            ],
                          ),
                          if (proj.technologies.isNotEmpty)
                            Text('Tech: ${proj.technologies}',
                                style: TextStyle(fontSize: 11, color: accentColor, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(proj.description, style: const TextStyle(fontSize: 11.5, color: Colors.black)),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
              ],

              // Education
              if (cv.educations.isNotEmpty) ...[
                _sectionTitle('Education', accentColor),
                ...cv.educations.map((edu) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${edu.degree} in ${edu.fieldOfStudy}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.black)),
                                Text(edu.institution, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                                if (edu.gradeOrGpa.isNotEmpty)
                                  Text(edu.gradeOrGpa, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${edu.startDate} – ${edu.endDate}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
              ],

          // Skills
          if (cv.skills.isNotEmpty) ...[
            _sectionTitle('Technical Proficiencies', accentColor),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cv.skills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    )));
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Container(height: 1.5, width: 40, color: color),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
