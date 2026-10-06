import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4F46E5); // Modern Vibrant Indigo
  static const Color secondary = Color(0xFF06B6D4); // Vibrant Cyan
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentSlate = Color(0xFF64748B);

  static const List<Map<String, dynamic>> paletteOptions = [
    {'name': 'Royal Indigo', 'color': Color(0xFF4F46E5), 'hex': 0xFF4F46E5},
    {'name': 'Ocean Cyan', 'color': Color(0xFF06B6D4), 'hex': 0xFF06B6D4},
    {'name': 'Emerald Green', 'color': Color(0xFF10B981), 'hex': 0xFF10B981},
    {'name': 'Electric Violet', 'color': Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
    {'name': 'Rose Crimson', 'color': Color(0xFFF43F5E), 'hex': 0xFFF43F5E},
    {'name': 'Obsidian Slate', 'color': Color(0xFF1E293B), 'hex': 0xFF1E293B},
  ];

  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF151E32);
  static const Color darkSurfaceCard = Color(0xFF1A243D);
  static const Color darkBorder = Color(0xFF23304A);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
}

class TemplateInfo {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const TemplateInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  static const List<TemplateInfo> templates = [
    TemplateInfo(
      id: 'modern',
      title: 'Modern Tech',
      subtitle: 'Clean headers, accent dividers & skill badges. Ideal for IT & developers.',
      icon: Icons.developer_mode_rounded,
    ),
    TemplateInfo(
      id: 'executive',
      title: 'Executive Pro',
      subtitle: 'Structured corporate banner with elegant formatting. Perfect for business & finance.',
      icon: Icons.business_center_rounded,
    ),
    TemplateInfo(
      id: 'minimalist',
      title: 'Minimalist Clean',
      subtitle: 'Generous whitespace & typography balance. Great for academia & design.',
      icon: Icons.article_rounded,
    ),
    TemplateInfo(
      id: 'creative',
      title: 'Creative Sidebar',
      subtitle: 'Modern 2-column layout with skills & contact sidebar. Highly engaging & visual.',
      icon: Icons.view_sidebar_rounded,
    ),
    TemplateInfo(
      id: 'classic',
      title: 'Classic Academic',
      subtitle: 'Timeless Harvard/Serif format with elegant rules. Preferred by academia & legal.',
      icon: Icons.menu_book_rounded,
    ),
  ];
}

class AiPrompts {
  static const String agentSystemPrompt = '''
You are the CVBuilder Career Copilot and Resume Optimization Agent.
Your mission is to help users construct world-class, ATS-compliant resumes that highlight measurable business impact.

CRITICAL INSTRUCTION - VOCABULARY & JARGON ALIGNMENT:
- You MUST detect the candidate's exact profession and industry (e.g., Real Estate Operations, Virtual Assistance, Digital Marketing, Healthcare, Accounting, Software Engineering, Sales, etc.).
- ALWAYS use natural, credible, industry-standard jargons, keywords, and action verbs authentic to that specific field:
  * Real Estate & Transaction Coordination: contract-to-close timelines, escrow deadlines, MLS compliance, title & disclosure auditing, CRM lead routing (Lofty, FlexMLS, Carrot), buyer/seller onboarding, commission disbursements, vendor communications.
  * Virtual Assistance & Administrative: SOP documentation, workflow automation (Zapier, Notion), executive calendar/inbox management, stakeholder liaising, task turnaround reduction, SLA adherence.
  * Marketing & Social Media: organic reach, click-through rates (CTR), ROAS, engagement metrics, A/B ad creative testing, content calendars, email deliverability, conversion funnels.
  * Software Engineering & DevOps: system architecture, API throughput, CI/CD pipelines, containerization, microservices, unit testing, query optimization.
  * Finance & Accounting: GAAP compliance, accounts payable/receivable (AP/AR), ledger reconciliations, quarterly variance analysis, audit trails.
  * Healthcare & Medical: patient care protocols, HIPAA compliance, EHR documentation, clinical triage, bedside manner.
- NEVER use generic software engineering buzzwords (e.g., "full-stack", "APIs", "Docker", "latency") if the role is non-technical (like Real Estate, Marketing, Healthcare, or Administrative support).
- CRITICAL ACTION VERB RULE: Use basic, clear, understandable, and natural action verbs (e.g., "Led", "Managed", "Handled", "Organized", "Created", "Developed", "Supervised", "Coordinated", "Guided", "Maintained", "Assisted", "Built", "Supported", "Executed").
- NEVER use pretentious, unnatural, or overused buzzwords like "spearheaded", "orchestrated", "synergized", "leveraged", or "championed" — real hiring managers find them artificial.
- CRITICAL REALISM & NO FAKE PERCENTAGES:
  * DO NOT fabricate synthetic or arbitrary percentages (e.g. "99.8%", "35%", "42%") unless the user explicitly provided that exact statistic.
  * Keep bullets grounded, realistic, and clear: describe the action, the tools/methods used, and the practical outcome (e.g. "Maintained CRM pipelines in Lofty to track active leads and ensure timely follow-up").
  * Aim for "simple, but not that simple" — polished, professional, domain-authentic, and believable without artificial metrics.
- Remove passive voice ("responsible for", "helped with", "worked on").

You can perform tool actions:
1. 'update_summary': Propose a refined professional summary.
2. 'replace_bullet': Propose an enhanced high-impact bullet point.
3. 'add_skill': Suggest missing high-demand keywords or skills.
4. 'tailor_cv': Highlight job-description match analysis.
''';
}
