import 'package:flutter/material.dart';
import '../../models/cv_data.dart';

class CreativeTemplateView extends StatelessWidget {
  final CvData cv;

  const CreativeTemplateView({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(cv.accentColorHex);
    final p = cv.personalInfo;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 540;
        final sidebarWidth = isNarrow
            ? (constraints.maxWidth * 0.35).clamp(115.0, 160.0)
            : 210.0;
        final mainPadding = isNarrow ? 12.0 : 20.0;

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Creative Full-Width Top Header ---
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 16 : 24,
                  vertical: isNarrow ? 16 : 22,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.08),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: accentColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Designer Monogram Emblem
                    Container(
                      width: isNarrow ? 48 : 56,
                      height: isNarrow ? 48 : 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(p.fullName),
                        style: TextStyle(
                          fontSize: isNarrow ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name, Title, and Quick Contact
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.fullName.isNotEmpty ? p.fullName : 'Your Full Name',
                            style: TextStyle(
                              fontSize: isNarrow ? 18 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (p.jobTitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              p.jobTitle,
                              style: TextStyle(
                                fontSize: isNarrow ? 11.5 : 13.5,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          // Contact details row/wrap
                          Wrap(
                            spacing: isNarrow ? 8 : 12,
                            runSpacing: 4,
                            children: [
                              if (p.email.isNotEmpty)
                                _headerContact(Icons.email_outlined, p.email, isNarrow),
                              if (p.phone.isNotEmpty)
                                _headerContact(Icons.phone_outlined, p.phone, isNarrow),
                              if (p.location.isNotEmpty)
                                _headerContact(Icons.location_on_outlined, p.location, isNarrow),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. Two-Column Body Section ---
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column (Sidebar for Skills, Education, Links)
                    Container(
                      width: sidebarWidth,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 10 : 16,
                        vertical: isNarrow ? 14 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Additional Links (LinkedIn, GitHub)
                          if (p.linkedin.isNotEmpty || p.github.isNotEmpty) ...[
                            _sidebarHeader('PROFILES', accentColor, isNarrow),
                            if (p.linkedin.isNotEmpty)
                              _sidebarContact(Icons.link_rounded, p.linkedin, isNarrow),
                            if (p.github.isNotEmpty)
                              _sidebarContact(Icons.code_rounded, p.github, isNarrow),
                            const SizedBox(height: 14),
                          ],

                          // Skills in sidebar
                          if (cv.skills.isNotEmpty) ...[
                            _sidebarHeader('CORE SKILLS', accentColor, isNarrow),
                            Wrap(
                              spacing: 4,
                              runSpacing: 5,
                              children: cv.skills
                                  .map(
                                    (s) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isNarrow ? 6 : 8,
                                        vertical: isNarrow ? 3 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: accentColor.withValues(alpha: 0.25),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        s.name,
                                        style: TextStyle(
                                          fontSize: isNarrow ? 9.5 : 11,
                                          fontWeight: FontWeight.w600,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Education in sidebar
                          if (cv.educations.isNotEmpty) ...[
                            _sidebarHeader('EDUCATION', accentColor, isNarrow),
                            ...cv.educations.map((edu) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${edu.degree}${edu.fieldOfStudy.isNotEmpty ? " in ${edu.fieldOfStudy}" : ""}',
                                        style: TextStyle(
                                          fontSize: isNarrow ? 10 : 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        edu.institution,
                                        style: TextStyle(
                                          fontSize: isNarrow ? 9.5 : 11,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                      if (edu.endDate.isNotEmpty) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          edu.endDate,
                                          style: TextStyle(
                                            fontSize: isNarrow ? 8.5 : 10,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),

                    // Right Main Content Column
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(mainPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary
                            if (p.summary.isNotEmpty) ...[
                              _sectionHeader('Profile Overview', accentColor, isNarrow),
                              Text(
                                p.summary,
                                style: TextStyle(
                                  fontSize: isNarrow ? 10.5 : 12,
                                  height: 1.45,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              SizedBox(height: isNarrow ? 12 : 16),
                            ],

                            // Work Experience
                            if (cv.experiences.isNotEmpty) ...[
                              _sectionHeader('Professional Experience', accentColor, isNarrow),
                              ...cv.experiences.map((exp) {
                                final companyLoc = [exp.company, exp.location]
                                    .where((s) => s.trim().isNotEmpty)
                                    .join(' • ');

                                return Padding(
                                  padding: EdgeInsets.only(bottom: isNarrow ? 10 : 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              exp.role,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isNarrow ? 11.5 : 13.5,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                                            style: TextStyle(
                                              fontSize: isNarrow ? 9.5 : 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (companyLoc.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          companyLoc,
                                          style: TextStyle(
                                            fontSize: isNarrow ? 10 : 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      ...exp.bullets.map((b) => Padding(
                                            padding: const EdgeInsets.only(left: 2, bottom: 3),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 4,
                                                  margin: const EdgeInsets.only(top: 5, right: 6),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: accentColor,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    b,
                                                    style: TextStyle(
                                                      fontSize: isNarrow ? 10 : 11.5,
                                                      height: 1.4,
                                                      color: const Color(0xFF334155),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],

                            // Projects
                            if (cv.projects.isNotEmpty) ...[
                              _sectionHeader('Key Projects & Portfolio', accentColor, isNarrow),
                              ...cv.projects.map((proj) => Padding(
                                    padding: EdgeInsets.only(bottom: isNarrow ? 8 : 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                proj.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isNarrow ? 11 : 12.5,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            if (proj.link.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                proj.link,
                                                style: TextStyle(
                                                  fontSize: isNarrow ? 9.5 : 11,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (proj.technologies.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Text(
                                              'Stack: ${proj.technologies}',
                                              style: TextStyle(
                                                fontSize: isNarrow ? 9.5 : 11,
                                                color: accentColor,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          proj.description,
                                          style: TextStyle(
                                            fontSize: isNarrow ? 10 : 11.5,
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerContact(IconData icon, String text, bool isNarrow) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isNarrow ? 11 : 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: isNarrow ? 9.5 : 11,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _sidebarHeader(String title, Color color, bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isNarrow ? 9.5 : 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: color,
        ),
      ),
    );
  }

  Widget _sidebarContact(IconData icon, String text, bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isNarrow ? 11 : 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isNarrow ? 9 : 10.5,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, bool isNarrow) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isNarrow ? 6 : 10),
      padding: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isNarrow ? 11.5 : 13,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'CV';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
