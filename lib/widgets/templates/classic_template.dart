import 'package:flutter/material.dart';
import '../../models/cv_data.dart';

class ClassicTemplateView extends StatelessWidget {
  final CvData cv;

  const ClassicTemplateView({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(cv.accentColorHex);
    final p = cv.personalInfo;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Header
          Text(
            p.fullName.isNotEmpty ? p.fullName.toUpperCase() : 'YOUR FULL NAME',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFF111827),
            ),
          ),
          if (p.jobTitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              p.jobTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            [p.email, p.phone, p.location, p.linkedin].where((s) => s.isNotEmpty).join('   |   '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 12),
          _classicDivider(accentColor),
          const SizedBox(height: 14),

          // Content body
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              if (p.summary.isNotEmpty) ...[
                _sectionHeader('PROFESSIONAL SUMMARY', accentColor),
                Text(
                  p.summary,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 11.5, height: 1.5, color: Colors.black),
                ),
                const SizedBox(height: 14),
              ],

              // Experience
              if (cv.experiences.isNotEmpty) ...[
                _sectionHeader('PROFESSIONAL EXPERIENCE', accentColor),
                ...cv.experiences.map((exp) {
                  final compLoc = [exp.company, exp.location].where((s) => s.trim().isNotEmpty).join(', ');

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
                                exp.role,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${exp.startDate} – ${exp.isCurrent ? 'Present' : exp.endDate}',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        if (compLoc.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            compLoc,
                            style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                        const SizedBox(height: 4),
                        ...exp.bullets.map((b) => Padding(
                              padding: const EdgeInsets.only(left: 6, bottom: 2.5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
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

              // Education
              if (cv.educations.isNotEmpty) ...[
                _sectionHeader('EDUCATION & CREDENTIALS', accentColor),
                ...cv.educations.map((edu) {
                  final degreeString = [
                    if (edu.degree.isNotEmpty) edu.degree,
                    if (edu.fieldOfStudy.isNotEmpty) 'in ${edu.fieldOfStudy}',
                  ].join(' ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                degreeString,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF111827)),
                              ),
                              Text(
                                edu.institution,
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF4B5563)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          edu.endDate,
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF4B5563)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],

              // Projects
              if (cv.projects.isNotEmpty) ...[
                _sectionHeader('SELECTED PROJECTS', accentColor),
                ...cv.projects.map((proj) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  proj.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF111827)),
                                ),
                              ),
                              if (proj.link.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(proj.link, style: const TextStyle(fontSize: 10.5, color: Color(0xFF4B5563))),
                              ],
                            ],
                          ),
                          if (proj.technologies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('Core Tools: ${proj.technologies}',
                                  style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF4B5563))),
                            ),
                          Text(proj.description, style: const TextStyle(fontSize: 11, color: Color(0xFF1F2937))),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
              ],

              // Skills
              if (cv.skills.isNotEmpty) ...[
                _sectionHeader('TECHNICAL & PROFESSIONAL SKILLS', accentColor),
                Text(
                  cv.skills.map((s) => s.name).join('   •   '),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF1F2937), height: 1.4),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _classicDivider(Color color) {
    return Column(
      children: [
        Container(height: 1.5, color: const Color(0xFF111827)),
        const SizedBox(height: 2),
        Container(height: 0.7, color: const Color(0xFF6B7280)),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF111827), width: 1)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}
