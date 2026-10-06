import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cv_data.dart';

class PdfExportService {
  /// Generates a PDF Document based on the CV data and selected template
  static Future<Uint8List> generateCvPdf(CvData cv) async {
    final pdf = pw.Document();
    final accentColor = PdfColor.fromInt(cv.accentColorHex);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (pw.Context context) {
          switch (cv.selectedTemplate) {
            case 'executive':
              return _buildExecutivePdf(cv, accentColor);
            case 'minimalist':
              return _buildMinimalistPdf(cv, accentColor);
            case 'creative':
              return _buildCreativePdf(cv, accentColor);
            case 'classic':
              return _buildClassicPdf(cv, accentColor);
            case 'modern':
            default:
              return _buildModernPdf(cv, accentColor);
          }
        },
      ),
    );

    return pdf.save();
  }

  /// 1-click preview and print/share dialog (for backwards compatibility)
  static Future<void> printOrShare(CvData cv) async {
    await shareOrSavePdf(cv);
  }

  /// Downloads / saves / shares the PDF directly to device storage or apps
  static Future<void> shareOrSavePdf(CvData cv) async {
    final pdfBytes = await generateCvPdf(cv);
    final rawName = cv.personalInfo.fullName.isNotEmpty
        ? cv.personalInfo.fullName
        : (cv.title.isNotEmpty ? cv.title : 'Resume');
    final sanitized = rawName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${sanitized}_CV.pdf',
    );
  }

  /// Opens the system Print dialog / Android Print Spooler (with Save as PDF option)
  static Future<void> printPdf(CvData cv) async {
    final pdfBytes = await generateCvPdf(cv);
    final rawName = cv.personalInfo.fullName.isNotEmpty
        ? cv.personalInfo.fullName
        : (cv.title.isNotEmpty ? cv.title : 'Resume');
    final sanitized = rawName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${sanitized}_CV.pdf',
    );
  }

  // ==========================================
  // --- 1. Modern Tech Template ---
  // ==========================================
  static List<pw.Widget> _buildModernPdf(CvData cv, PdfColor accentColor) {
    final p = cv.personalInfo;
    return [
      // Header
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  p.fullName.isNotEmpty ? p.fullName : 'Your Name',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  p.jobTitle.isNotEmpty ? p.jobTitle : 'Professional Title',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (p.email.isNotEmpty) _pdfContactItem(p.email),
              if (p.phone.isNotEmpty) _pdfContactItem(p.phone),
              if (p.location.isNotEmpty) _pdfContactItem(p.location),
              if (p.linkedin.isNotEmpty) _pdfContactItem(p.linkedin),
              if (p.github.isNotEmpty) _pdfContactItem(p.github),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(height: 2, color: accentColor),
      pw.SizedBox(height: 12),

      // Summary
      if (p.summary.isNotEmpty) ...[
        _pdfSectionHeader('Professional Summary', accentColor),
        pw.Text(
          p.summary,
          style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4, color: PdfColors.black),
        ),
        pw.SizedBox(height: 12),
      ],

      // Experience
      if (cv.experiences.isNotEmpty) ...[
        _pdfSectionHeader('Work Experience', accentColor),
        ...cv.experiences.map((exp) {
          final compLoc = [exp.company, exp.location].where((s) => s.trim().isNotEmpty).join('  |  ');

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        exp.role,
                        style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                if (compLoc.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    compLoc,
                    style: pw.TextStyle(fontSize: 9.5, color: accentColor, fontWeight: pw.FontWeight.bold),
                  ),
                ],
                pw.SizedBox(height: 4),
                ...exp.bullets.map((b) => _pdfBullet(b, accentColor)),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 6),
      ],

      // Projects
      if (cv.projects.isNotEmpty) ...[
        _pdfSectionHeader('Key Projects', accentColor),
        ...cv.projects.map((proj) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          proj.title,
                          style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      if (proj.link.isNotEmpty) ...[
                        pw.SizedBox(width: 8),
                        pw.Text(
                          proj.link,
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blueGrey700),
                        ),
                      ],
                    ],
                  ),
                  if (proj.technologies.isNotEmpty)
                    pw.Text('Tech Stack: ${proj.technologies}',
                        style: pw.TextStyle(fontSize: 8.5, color: accentColor, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    proj.description,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800, lineSpacing: 1.3),
                  ),
                ],
              ),
            )),
        pw.SizedBox(height: 6),
      ],

      // Education
      if (cv.educations.isNotEmpty) ...[
        _pdfSectionHeader('Education', accentColor),
        ...cv.educations.map((edu) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${edu.degree} in ${edu.fieldOfStudy}',
                          style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(edu.institution, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (edu.gradeOrGpa.isNotEmpty)
                          pw.Text(edu.gradeOrGpa, style: pw.TextStyle(fontSize: 8.5, color: accentColor)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    '${edu.startDate} - ${edu.endDate}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            )),
        pw.SizedBox(height: 6),
      ],

      // Skills
      if (cv.skills.isNotEmpty) ...[
        _pdfSectionHeader('Technical Proficiencies', accentColor),
        pw.Wrap(
          spacing: 6,
          runSpacing: 4,
          children: cv.skills
              .map(
                (s) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: accentColor, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    s.name,
                    style: pw.TextStyle(fontSize: 8.5, color: accentColor, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ];
  }

  // ==========================================
  // --- 2. Executive Pro Template ---
  // ==========================================
  static List<pw.Widget> _buildExecutivePdf(CvData cv, PdfColor accentColor) {
    final p = cv.personalInfo;
    final contactString = [p.email, p.phone, p.location, p.linkedin].where((s) => s.isNotEmpty).join('   |   ');

    return [
      // Banner Header
      pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          color: accentColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              p.fullName.isNotEmpty ? p.fullName.toUpperCase() : 'YOUR NAME',
              style: const pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 1.5,
              ),
            ),
            if (p.jobTitle.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                p.jobTitle.toUpperCase(),
                style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.white, letterSpacing: 1.2),
              ),
            ],
            if (contactString.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                contactString,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 14),

      // Summary
      if (p.summary.isNotEmpty) ...[
        _pdfExecutiveHeader('EXECUTIVE PROFILE', accentColor),
        pw.Text(p.summary, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4)),
        pw.SizedBox(height: 10),
      ],

      // Experience
      if (cv.experiences.isNotEmpty) ...[
        _pdfExecutiveHeader('PROFESSIONAL EXPERIENCE', accentColor),
        ...cv.experiences.map((exp) {
          final compLoc = [exp.company, exp.location].where((s) => s.trim().isNotEmpty).join('  |  ');

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        exp.role,
                        style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                if (compLoc.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    compLoc,
                    style: pw.TextStyle(fontSize: 9.5, color: accentColor, fontWeight: pw.FontWeight.bold),
                  ),
                ],
                pw.SizedBox(height: 3),
                ...exp.bullets.map((b) => _pdfBullet(b, accentColor)),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 4),
      ],

      // Projects
      if (cv.projects.isNotEmpty) ...[
        _pdfExecutiveHeader('KEY PROJECTS', accentColor),
        ...cv.projects.map((proj) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(proj.title, style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      if (proj.link.isNotEmpty) ...[
                        pw.SizedBox(width: 8),
                        pw.Text(proj.link, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blueGrey700)),
                      ],
                    ],
                  ),
                  if (proj.technologies.isNotEmpty)
                    pw.Text('Technologies: ${proj.technologies}',
                        style: pw.TextStyle(fontSize: 8.5, color: accentColor, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 2),
                  pw.Text(proj.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900, lineSpacing: 1.3)),
                ],
              ),
            )),
        pw.SizedBox(height: 4),
      ],

      // Education
      if (cv.educations.isNotEmpty) ...[
        _pdfExecutiveHeader('EDUCATION & CREDENTIALS', accentColor),
        ...cv.educations.map((edu) {
          final degString = [
            if (edu.degree.isNotEmpty) edu.degree,
            if (edu.fieldOfStudy.isNotEmpty) edu.fieldOfStudy,
            if (edu.institution.isNotEmpty) edu.institution,
          ].join(' - ');

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(degString, style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(width: 8),
                pw.Text(edu.endDate, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 4),
      ],

      // Skills
      if (cv.skills.isNotEmpty) ...[
        _pdfExecutiveHeader('CORE COMPETENCIES', accentColor),
        pw.Wrap(
          spacing: 6,
          runSpacing: 4,
          children: cv.skills
              .map(
                (s) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    s.name,
                    style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ];
  }

  // ==========================================
  // --- 3. Minimalist Clean Template ---
  // ==========================================
  static List<pw.Widget> _buildMinimalistPdf(CvData cv, PdfColor accentColor) {
    final p = cv.personalInfo;
    final contactLine = [p.email, p.phone, p.location, p.linkedin].where((s) => s.isNotEmpty).join('   |   ');

    return [
      pw.Text(
        p.fullName.isNotEmpty ? p.fullName : 'Your Full Name',
        style: const pw.TextStyle(fontSize: 24, color: PdfColors.black),
      ),
      if (p.jobTitle.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          p.jobTitle,
          style: const pw.TextStyle(fontSize: 11.5, color: PdfColors.grey700),
        ),
      ],
      if (contactLine.isNotEmpty) ...[
        pw.SizedBox(height: 5),
        pw.Text(
          contactLine,
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
        ),
      ],
      pw.SizedBox(height: 8),
      pw.Divider(thickness: 0.6, color: PdfColors.grey400),
      pw.SizedBox(height: 10),

      if (p.summary.isNotEmpty) ...[
        pw.Text('ABOUT', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
        pw.SizedBox(height: 3),
        pw.Text(p.summary, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4)),
        pw.SizedBox(height: 10),
      ],

      if (cv.experiences.isNotEmpty) ...[
        pw.Text('EXPERIENCE', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
        pw.SizedBox(height: 4),
        ...cv.experiences.map((exp) {
          final title = [exp.role, exp.company].where((s) => s.isNotEmpty).join(' - ');

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(title, style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 3),
                ...exp.bullets.map((b) => _pdfBullet(b, PdfColors.black)),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 6),
      ],

      if (cv.projects.isNotEmpty) ...[
        pw.Text('PROJECTS', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
        pw.SizedBox(height: 4),
        ...cv.projects.map((proj) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(proj.title, style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  if (proj.technologies.isNotEmpty)
                    pw.Text('Stack: ${proj.technologies}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.SizedBox(height: 2),
                  pw.Text(proj.description, style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.3)),
                ],
              ),
            )),
        pw.SizedBox(height: 6),
      ],

      if (cv.educations.isNotEmpty) ...[
        pw.Text('EDUCATION', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
        pw.SizedBox(height: 4),
        ...cv.educations.map((edu) {
          final deg = [
            if (edu.degree.isNotEmpty) edu.degree,
            if (edu.fieldOfStudy.isNotEmpty) 'in ${edu.fieldOfStudy}',
            if (edu.institution.isNotEmpty) edu.institution,
          ].join(', ');

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(deg, style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.SizedBox(width: 8),
                pw.Text(edu.endDate, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 6),
      ],

      if (cv.skills.isNotEmpty) ...[
        pw.Text('SKILLS', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
        pw.SizedBox(height: 3),
        pw.Text(cv.skills.map((s) => s.name).join('   /   '),
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
      ],
    ];
  }

  // ==========================================
  // --- 4. Creative Sidebar Template ---
  // ==========================================
  static List<pw.Widget> _buildCreativePdf(CvData cv, PdfColor accentColor) {
    final p = cv.personalInfo;
    final initials = _getInitials(p.fullName);
    final contactParts = [
      if (p.email.isNotEmpty) p.email,
      if (p.phone.isNotEmpty) p.phone,
      if (p.location.isNotEmpty) p.location,
    ].join('   |   ');

    return [
      // Top Creative Header with Monogram Badge
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF8FAFC),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 1),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Monogram Badge
            pw.Container(
              width: 44,
              height: 44,
              decoration: pw.BoxDecoration(
                color: accentColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                initials,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    p.fullName.isNotEmpty ? p.fullName : 'Your Name',
                    style: const pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  if (p.jobTitle.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      p.jobTitle,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                  if (contactParts.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      contactParts,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),

      // Two-Column Body
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left Sidebar Column
          pw.Container(
            width: 160,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Profiles
                if (p.linkedin.isNotEmpty || p.github.isNotEmpty) ...[
                  _pdfSectionHeader('PROFILES', accentColor),
                  if (p.linkedin.isNotEmpty) _pdfContactItem(p.linkedin),
                  if (p.github.isNotEmpty) _pdfContactItem(p.github),
                  pw.SizedBox(height: 10),
                ],

                // Skills
                if (cv.skills.isNotEmpty) ...[
                  _pdfSectionHeader('SKILLS', accentColor),
                  pw.Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: cv.skills
                        .map(
                          (s) => pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: accentColor, width: 0.6),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                            ),
                            child: pw.Text(
                              s.name,
                              style: pw.TextStyle(fontSize: 7.5, color: accentColor, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Education
                if (cv.educations.isNotEmpty) ...[
                  _pdfSectionHeader('EDUCATION', accentColor),
                  ...cv.educations.map((edu) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${edu.degree} ${edu.fieldOfStudy.isNotEmpty ? "in ${edu.fieldOfStudy}" : ""}',
                              style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(edu.institution, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                            pw.Text(edu.endDate, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),

          pw.SizedBox(width: 14),

          // Right Main Column
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (p.summary.isNotEmpty) ...[
                  _pdfSectionHeader('PROFILE', accentColor),
                  pw.Text(p.summary, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4)),
                  pw.SizedBox(height: 12),
                ],

                if (cv.experiences.isNotEmpty) ...[
                  _pdfSectionHeader('WORK EXPERIENCE', accentColor),
                  ...cv.experiences.map((exp) {
                    final compLoc = [exp.company, exp.location].where((s) => s.trim().isNotEmpty).join('  |  ');

                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(exp.role, style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                          if (compLoc.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(compLoc, style: pw.TextStyle(fontSize: 9, color: accentColor, fontWeight: pw.FontWeight.bold)),
                          ],
                          pw.SizedBox(height: 3),
                          ...exp.bullets.map((b) => _pdfBullet(b, accentColor)),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 6),
                ],

                if (cv.projects.isNotEmpty) ...[
                  _pdfSectionHeader('FEATURED PROJECTS', accentColor),
                  ...cv.projects.map((proj) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(proj.title, style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                                ),
                                if (proj.link.isNotEmpty) ...[
                                  pw.SizedBox(width: 6),
                                  pw.Text(proj.link, style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey700)),
                                ],
                              ],
                            ),
                            if (proj.technologies.isNotEmpty)
                              pw.Text('Technologies: ${proj.technologies}',
                                  style: pw.TextStyle(fontSize: 8, color: accentColor, fontStyle: pw.FontStyle.italic)),
                            pw.SizedBox(height: 2),
                            pw.Text(proj.description, style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.3)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    ];
  }

  // ==========================================
  // --- 5. Classic Academic Template ---
  // ==========================================
  static List<pw.Widget> _buildClassicPdf(CvData cv, PdfColor accentColor) {
    final p = cv.personalInfo;
    final contactLine = [p.email, p.phone, p.location, p.linkedin].where((s) => s.isNotEmpty).join('   |   ');

    return [
      // Centered Classic Heading
      pw.Center(
        child: pw.Text(
          p.fullName.isNotEmpty ? p.fullName.toUpperCase() : 'YOUR FULL NAME',
          style: const pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 2,
            color: PdfColors.black,
          ),
        ),
      ),
      if (p.jobTitle.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            p.jobTitle,
            style: const pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
          ),
        ),
      ],
      if (contactLine.isNotEmpty) ...[
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            contactLine,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
        ),
      ],
      pw.SizedBox(height: 8),
      pw.Container(height: 1.2, color: PdfColors.black),
      pw.SizedBox(height: 1.5),
      pw.Container(height: 0.6, color: PdfColors.grey600),
      pw.SizedBox(height: 10),

      // Summary
      if (p.summary.isNotEmpty) ...[
        _pdfClassicHeader('PROFESSIONAL SUMMARY'),
        pw.Text(p.summary, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4)),
        pw.SizedBox(height: 10),
      ],

      // Experience
      if (cv.experiences.isNotEmpty) ...[
        _pdfClassicHeader('PROFESSIONAL EXPERIENCE'),
        ...cv.experiences.map((exp) {
          final compLoc = [exp.company, exp.location].where((s) => s.trim().isNotEmpty).join(', ');

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(exp.role, style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                      style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                if (compLoc.isNotEmpty) ...[
                  pw.SizedBox(height: 1.5),
                  pw.Text(compLoc, style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.black)),
                ],
                pw.SizedBox(height: 3),
                ...exp.bullets.map((b) => _pdfBullet(b, PdfColors.black)),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 6),
      ],

      // Education
      if (cv.educations.isNotEmpty) ...[
        _pdfClassicHeader('EDUCATION & ACADEMIC CREDENTIALS'),
        ...cv.educations.map((edu) {
          final deg = [
            if (edu.degree.isNotEmpty) edu.degree,
            if (edu.fieldOfStudy.isNotEmpty) 'in ${edu.fieldOfStudy}',
          ].join(' ');

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(deg, style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text(edu.institution, style: const pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(edu.endDate, style: const pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 6),
      ],

      // Projects
      if (cv.projects.isNotEmpty) ...[
        _pdfClassicHeader('SELECTED PROJECTS'),
        ...cv.projects.map((proj) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(proj.title, style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      if (proj.link.isNotEmpty) ...[
                        pw.SizedBox(width: 8),
                        pw.Text(proj.link, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ],
                  ),
                  if (proj.technologies.isNotEmpty)
                    pw.Text('Tools: ${proj.technologies}',
                        style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                  pw.SizedBox(height: 2),
                  pw.Text(proj.description, style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.3)),
                ],
              ),
            )),
        pw.SizedBox(height: 6),
      ],

      // Skills
      if (cv.skills.isNotEmpty) ...[
        _pdfClassicHeader('TECHNICAL & PROFESSIONAL SKILLS'),
        pw.Text(cv.skills.map((s) => s.name).join('   |   '),
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
      ],
    ];
  }

  // ==========================================
  // --- Reusable PDF Helper Widgets ---
  // ==========================================

  /// Clean vector bullet point that never renders broken square glyphs
  static pw.Widget _pdfBullet(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 4, bottom: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3.5,
            height: 3.5,
            margin: const pw.EdgeInsets.only(top: 4, right: 6),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: color,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.35, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSectionHeader(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Container(height: 1, width: 36, color: color),
        ],
      ),
    );
  }

  static pw.Widget _pdfExecutiveHeader(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6, bottom: 5),
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: color, letterSpacing: 1.2),
      ),
    );
  }

  static pw.Widget _pdfClassicHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 5),
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
      ),
      child: pw.Text(
        title,
        style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  static pw.Widget _pdfContactItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
      ),
    );
  }

  static String _getInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'CV';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
