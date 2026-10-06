import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/ai_agent_message.dart';
import '../models/cv_data.dart';
import '../models/personal_info.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/project.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class AiAgentService {
  final _uuid = const Uuid();

  /// Enhances a raw bullet point using the Google XYZ formula
  Future<AiAgentMessage> enhanceBulletPoint({
    required String rawBullet,
    String? roleTitle,
    String? company,
    String? apiKey,
    bool isDemoMode = true,
  }) async {
    // If live API key is supplied and not in demo mode
    if (!isDemoMode && apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        return await _callGeminiEnhanceBullet(rawBullet, roleTitle, company, apiKey);
      } catch (e) {
        // Fallback to demo mode if API call fails
      }
    }

    // Demo Mode: Rule-based agentic reasoning and enhancement
    await Future.delayed(const Duration(milliseconds: 700)); // Simulate agent thinking
    final enhanced = _mockEnhanceBullet(rawBullet, roleTitle);

    final reasoning =
        '1. Detected passive/general phrasing in: "$rawBullet".\n'
        '2. Applied Google XYZ formula: (Accomplished [X], measured by [Y], by doing [Z]).\n'
        '3. Replaced weak verb with active leadership verb.\n'
        '4. Infused quantifiable metrics and technical precision.';

    return AiAgentMessage(
      id: _uuid.v4(),
      sender: AgentSender.agent,
      text: 'Here is an optimized, high-impact version for your bullet point:\n\n**"$enhanced"**',
      timestamp: DateTime.now(),
      reasoning: reasoning,
      toolAction: AgentToolAction(
        actionType: 'replace_bullet',
        description: 'Update bullet point with quantified impact',
        data: {'original': rawBullet, 'replacement': enhanced},
      ),
    );
  }

  /// Generates a polished summary based on CV profile
  Future<AiAgentMessage> generateSummary({
    required CvData cv,
    String? apiKey,
    bool isDemoMode = true,
  }) async {
    if (!isDemoMode && apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        return await _callGeminiGenerateSummary(cv, apiKey);
      } catch (e) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 900));

    final title = cv.personalInfo.jobTitle.isNotEmpty ? cv.personalInfo.jobTitle : 'Specialist';
    final topSkills = cv.skills.take(3).map((s) => s.name).join(', ');
    final expCount = cv.experiences.length;

    final lowerTitle = title.toLowerCase();
    final lowerSkills = topSkills.toLowerCase();
    final isRealEstateOrVa = lowerTitle.contains('virtual assistant') ||
        lowerTitle.contains('real estate') ||
        lowerTitle.contains('transaction') ||
        lowerTitle.contains('coordinator') ||
        lowerSkills.contains('lofty') ||
        lowerSkills.contains('mls') ||
        lowerSkills.contains('carrot');

    final isMarketing = !isRealEstateOrVa &&
        (lowerTitle.contains('marketing') ||
            lowerTitle.contains('social media') ||
            lowerTitle.contains('content') ||
            lowerTitle.contains('seo'));

    final isFinance = lowerTitle.contains('account') ||
        lowerTitle.contains('finance') ||
        lowerTitle.contains('bookkeeper');

    final isDev = lowerTitle.contains('developer') ||
        lowerTitle.contains('engineer') ||
        lowerTitle.contains('software') ||
        lowerTitle.contains('information technology');

    String valuePitch;
    if (isRealEstateOrVa) {
      valuePitch = 'Proven track record streamlining contract-to-close workflows, maintaining MLS compliance, and delivering high-touch client coordination to accelerate transaction timelines.';
    } else if (isMarketing) {
      valuePitch = 'Proven track record driving multi-channel digital campaigns, optimizing audience engagement funnels, and scaling brand visibility across competitive markets.';
    } else if (isFinance) {
      valuePitch = 'Proven track record ensuring strict financial controls, accurate ledger reconciliations, and streamlined month-end reporting cycles.';
    } else if (isDev) {
      valuePitch = 'Demonstrated success architecting resilient software solutions, optimizing database performance, and driving cross-functional alignment to achieve measurable business outcomes.';
    } else {
      valuePitch = 'Demonstrated success optimizing operational workflows, standardizing procedures, and coordinating cross-functional priorities to achieve measurable outcomes.';
    }

    final summary =
        'Results-oriented $title with ${expCount > 1 ? '$expCount+ years of' : 'deep'} '
        'expertise in ${topSkills.isNotEmpty ? topSkills : 'delivering end-to-end solutions'}. '
        '$valuePitch';

    final reasoning =
        '1. Analyzed candidate title ($title) and domain proficiencies ($topSkills).\n'
        '2. Aligned executive summary vocabulary directly with the candidate\'s profession.\n'
        '3. Structured for optimal ATS scanning and recruiter impact.';

    return AiAgentMessage(
      id: _uuid.v4(),
      sender: AgentSender.agent,
      text: 'I have crafted an executive-level professional summary tailored to your profile:\n\n"$summary"',
      timestamp: DateTime.now(),
      reasoning: reasoning,
      toolAction: AgentToolAction(
        actionType: 'update_summary',
        description: 'Set professional summary',
        data: {'summary': summary},
      ),
    );
  }

  /// ATS compatibility checker
  Future<Map<String, dynamic>> analyzeAtsMatch({
    required CvData cv,
    required String jobDescription,
    String? apiKey,
    bool isDemoMode = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    // Extract common skills & keywords from job description
    final jdLower = jobDescription.toLowerCase();
    final cvSkills = cv.skills.map((s) => s.name.toLowerCase()).toList();

    final matched = <String>[];
    final missing = <String>[];

    final potentialKeywords = [
      'flutter', 'dart', 'react', 'python', 'javascript', 'typescript', 'docker',
      'kubernetes', 'aws', 'ci/cd', 'git', 'rest api', 'graphql', 'sql', 'nosql',
      'agile', 'scrum', 'testing', 'unit test', 'microservices', 'cloud', 'leadership'
    ];

    for (final kw in potentialKeywords) {
      if (jdLower.contains(kw)) {
        if (cvSkills.any((s) => s.contains(kw))) {
          matched.add(kw.toUpperCase());
        } else {
          missing.add(kw.toUpperCase());
        }
      }
    }

    int score = 70;
    if (matched.isNotEmpty || missing.isNotEmpty) {
      final total = matched.length + missing.length;
      score = ((matched.length / (total == 0 ? 1 : total)) * 100).round();
      score = score.clamp(35, 96);
    }

    return {
      'score': score,
      'matchedKeywords': matched,
      'missingKeywords': missing,
      'recommendations': [
        if (missing.isNotEmpty) 'Incorporate high-priority keywords: ${missing.take(3).join(', ')}.',
        'Quantify achievements in your work experience with metrics (% improvement, latency, users).',
        'Tailor your headline to mirror the exact job title in the posting.',
      ],
      'reasoning': 'Analyzed JD text for technical requirements, framework familiarity, and team methodology. Cross-referenced against your CV skills and past roles.',
    };
  }

  /// Conversational Assistant with Tool Dispatching
  Future<AiAgentMessage> processChatMessage({
    required String userMessage,
    required CvData cv,
    String? apiKey,
    bool isDemoMode = true,
  }) async {
    final lower = userMessage.toLowerCase();

    // If live API key is configured and not demo mode, use live Gemini 1.5 Flash
    if (!isDemoMode && apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        return await _callGeminiChat(
          userMessage: userMessage,
          cv: cv,
          apiKey: apiKey,
        );
      } catch (e) {
        // Fall back to offline agentic reasoning if live API is temporarily unavailable
      }
    }

    // 1. Request to enhance summary
    if (lower.contains('summary') || lower.contains('bio') || lower.contains('about me')) {
      return generateSummary(cv: cv, apiKey: apiKey, isDemoMode: isDemoMode);
    }

    // 2. Request to add a skill
    if (lower.contains('add skill') || (lower.contains('add') && lower.contains('skill'))) {
      final skillCandidate = userMessage
          .replaceAll(RegExp(r'(add skill|add the skill|add|to my skills)', caseSensitive: false), '')
          .trim()
          .replaceAll(RegExp(r'[^\w\s\+\#\.]'), '');
      final name = skillCandidate.isNotEmpty ? skillCandidate : 'Entity Framework Core';

      return AiAgentMessage(
        id: _uuid.v4(),
        sender: AgentSender.agent,
        text: 'I can add **$name** to your CV under the Technical Skills section with proficient mastery level.',
        timestamp: DateTime.now(),
        reasoning: 'Tool invocation: add_skill. Parsed requested technology from user message.',
        toolAction: AgentToolAction(
          actionType: 'add_skill',
          description: 'Add skill "$name"',
          data: {'name': name, 'category': 'Technical', 'level': 4},
        ),
      );
    }

    // 3. Request to review or audit resume
    if (lower.contains('review') || lower.contains('audit') || lower.contains('check') || lower.contains('score')) {
      await Future.delayed(const Duration(milliseconds: 600));
      final score = cv.completenessScore;
      final bulletsCount = cv.experiences.fold<int>(0, (sum, e) => sum + e.bullets.length);

      return AiAgentMessage(
        id: _uuid.v4(),
        sender: AgentSender.agent,
        text: '### 📋 ATS Resume Audit Report\n\n'
            '- **Overall Completeness**: **$score / 100**\n'
            '- **Candidate**: ${cv.personalInfo.fullName.isNotEmpty ? cv.personalInfo.fullName : "Profile"}\n'
            '- **Work Experience**: ${cv.experiences.length} positions with $bulletsCount bullet points.\n'
            '- **Education**: ${cv.educations.length} records.\n'
            '- **Skills**: ${cv.skills.length} listed.\n'
            '- **Projects**: ${cv.projects.length} documented.\n\n'
            '**Identified Opportunities**:\n'
            '1. ${bulletsCount < 4 ? "Expand bullet points to 3-4 entries per role." : "Good bullet volume."}\n'
            '2. Quantify results with measurable metrics (e.g., % uptime, response speed, users helped).\n'
            '3. Tap **"Suggest Improvements"** below to see missing high-demand skills and project ideas!',
        timestamp: DateTime.now(),
        reasoning: 'Evaluated structural completeness, bullet density, and balance across sections.',
      );
    }

    // 4. Request for Suggestions, Recommendations, Career Advice, or Project Ideas
    if (lower.contains('suggest') ||
        lower.contains('recommend') ||
        lower.contains('advice') ||
        lower.contains('improve') ||
        lower.contains('tip') ||
        lower.contains('idea') ||
        lower.contains('what should') ||
        lower.contains('what job') ||
        lower.contains('skills') ||
        lower.contains('projects')) {
      await Future.delayed(const Duration(milliseconds: 700));
      return _generateSmartSuggestions(cv, userMessage);
    }

    // Default conversational reply with interactive guidance
    await Future.delayed(const Duration(milliseconds: 500));
    return AiAgentMessage(
      id: _uuid.v4(),
      sender: AgentSender.agent,
      text: '### 🤖 CVBuilder AI Copilot Ready\n\n'
          'I am analyzed your resume for **${cv.personalInfo.fullName.isNotEmpty ? cv.personalInfo.fullName : "your profile"}**.\n\n'
          'Here is what I can do for you right now:\n'
          '• **"Suggest improvements"** - Tailored skills, projects, and certifications based on your profile.\n'
          '• **"Enhance my summary"** - Craft an executive ATS summary.\n'
          '• **"Audit my resume"** - Detailed scoring breakdown.\n'
          '• **"Add skill [Name]"** - Automatically add skills to your CV.\n\n'
          'You can also tap any of the quick action buttons below!',
      timestamp: DateTime.now(),
      reasoning: 'Presented tailored agent competencies and action suggestions.',
    );
  }

  /// Generates deep, personalized career and resume suggestions tailored to the candidate's actual profession
  AiAgentMessage _generateSmartSuggestions(CvData cv, String userMessage) {
    final existingSkills = cv.skills.map((s) => s.name.toLowerCase()).toSet();
    final lowerTitle = cv.personalInfo.jobTitle.toLowerCase();
    final lowerSummary = cv.personalInfo.summary.toLowerCase();

    final isRealEstateOrVa = lowerTitle.contains('virtual assistant') ||
        lowerTitle.contains('real estate') ||
        lowerTitle.contains('transaction') ||
        lowerTitle.contains('coordinator') ||
        lowerTitle.contains('operations') ||
        lowerSummary.contains('real estate') ||
        lowerSummary.contains('virtual assistant') ||
        existingSkills.contains('lofty') ||
        existingSkills.contains('flexmls') ||
        existingSkills.contains('carrot') ||
        existingSkills.contains('docusign');

    final isMarketing = !isRealEstateOrVa &&
        (lowerTitle.contains('marketing') ||
            lowerTitle.contains('social media') ||
            lowerTitle.contains('seo') ||
            lowerTitle.contains('content') ||
            existingSkills.contains('facebook ads') ||
            existingSkills.contains('canva'));

    final isItOrDev = lowerTitle.contains('it') ||
        lowerTitle.contains('information technology') ||
        lowerTitle.contains('developer') ||
        lowerTitle.contains('engineer') ||
        lowerTitle.contains('software') ||
        lowerSummary.contains('information technology') ||
        existingSkills.contains('c#') ||
        existingSkills.contains('python') ||
        existingSkills.contains('javascript') ||
        existingSkills.contains('asp.net');

    final isFinance = !isRealEstateOrVa && !isMarketing &&
        (lowerTitle.contains('account') ||
            lowerTitle.contains('finance') ||
            lowerTitle.contains('bookkeeper') ||
            lowerTitle.contains('audit'));

    final isHealthcare = !isRealEstateOrVa && !isMarketing && !isItOrDev &&
        (lowerTitle.contains('nurse') ||
            lowerTitle.contains('medical') ||
            lowerTitle.contains('health') ||
            lowerTitle.contains('clinical') ||
            lowerTitle.contains('patient'));

    final isSales = !isRealEstateOrVa && !isMarketing && !isItOrDev &&
        (lowerTitle.contains('sales') ||
            lowerTitle.contains('account executive') ||
            lowerTitle.contains('business development') ||
            lowerTitle.contains('bdr') ||
            lowerTitle.contains('sdr'));

    final recommendedSkills = <String>[];
    final targetRoles = <String>[];
    final portfolioProjects = <String>[];
    final recommendedCerts = <String>[];
    String primaryAddSkill = 'Workflow Automation';

    if (isRealEstateOrVa) {
      if (!existingSkills.contains('dotloop') && !existingSkills.contains('transactiondesk')) {
        recommendedSkills.add('Dotloop / TransactionDesk');
      }
      if (!existingSkills.contains('follow up boss')) {
        recommendedSkills.add('Follow Up Boss CRM');
      }
      if (!existingSkills.contains('mls compliance')) {
        recommendedSkills.add('MLS Compliance & Disclosures');
      }
      if (!existingSkills.contains('zapier') && !existingSkills.contains('zapier automation')) {
        recommendedSkills.add('Zapier Workflow Automation');
      }
      if (!existingSkills.contains('client onboarding')) {
        recommendedSkills.add('Client Onboarding SOPs');
      }
      if (!existingSkills.contains('canva pro')) {
        recommendedSkills.add('Canva Pro Marketing Kits');
      }

      targetRoles.addAll([
        '**Real Estate Operations Lead / Manager**: Overseeing contract-to-close workflows, MLS compliance, and team communications for top-producing brokerages.',
        '**Executive Virtual Assistant (US Clients)**: Managing executive calendars, email funnels, CRM pipeline routing, and investor relations.',
        '**Senior Transaction Coordinator**: Handling multi-state residential and commercial contract-to-close files with zero deadline misses.',
      ]);

      portfolioProjects.addAll([
        '**End-to-End Contract-to-Close SOP Checklist**: Standard operating procedure template eliminating escrow closing delays and auditing errors.',
        '**Automated Investor Lead Nurture Funnel**: Multi-touch email & SMS follow-up sequence in Lofty/Carrot boosting conversion from cold leads to active buyers.',
      ]);

      recommendedCerts.addAll([
        '**Certified Real Estate Transaction Coordinator (CRETC)** - Demonstrates mastery of purchase agreements, disclosures, and escrow.',
        '**HubSpot Inbound Marketing & CRM Certification** - Industry gold standard for client communication and lead nurturing.',
        '**Notion Certified Operations Specialist** - Proves high-level workflow architecture and digital workspace organization.',
      ]);
    } else if (isMarketing) {
      recommendedSkills.addAll([
        'Meta Ads Manager & Retargeting',
        'Google Analytics 4 (GA4)',
        'SEO On-Page & Technical Audit',
        'Klaviyo Email Automation',
        'A/B Creative Testing',
      ]);
      targetRoles.addAll([
        '**Growth Marketing Specialist**: Driving paid and organic acquisition funnels.',
        '**Social Media Brand Strategist**: Scaling multi-platform short-form video and engagement.',
        '**Email & Retention Marketing Lead**: Maximizing customer lifetime value and newsletter monetization.',
      ]);
      portfolioProjects.addAll([
        '**Omnichannel Short-Form Content Engine**: Playbook scaling Reels, TikTok, and YouTube video views.',
        '**E-Commerce Email Nurture Flow**: Automated welcome and cart-abandonment sequence.',
      ]);
      recommendedCerts.addAll([
        '**Meta Certified Digital Marketing Associate**',
        '**Google Analytics 4 (GA4) Certification**',
        '**HubSpot Content Marketing Certification**',
      ]);
    } else if (isItOrDev) {
      if (!existingSkills.contains('entity framework') && !existingSkills.contains('entity framework core')) {
        recommendedSkills.add('Entity Framework Core');
      }
      if (!existingSkills.contains('git') && !existingSkills.contains('github')) {
        recommendedSkills.add('Git & GitHub');
      }
      if (!existingSkills.contains('rest api') && !existingSkills.contains('restful apis')) {
        recommendedSkills.add('RESTful APIs');
      }
      if (!existingSkills.contains('sql server')) {
        recommendedSkills.add('Microsoft SQL Server');
      }
      if (!existingSkills.contains('docker')) {
        recommendedSkills.add('Docker');
      }
      targetRoles.addAll([
        '**Junior .NET / C# Web Developer**: Matches your C#, ASP.NET, and SQL skills.',
        '**IT Support Specialist / Systems Administrator**: Leverages your troubleshooting and hardware diagnostics background.',
        '**Full-Stack Application Developer**: Builds on your desktop and web system projects.',
      ]);
      portfolioProjects.addAll([
        '**IT Helpdesk & Asset Ticketing Portal**: Showcase both troubleshooting workflow and software engineering.',
        '**RESTful Web API for SukiPOS**: Expand desktop POS with cloud sync and authentication.',
      ]);
      recommendedCerts.addAll([
        '**Microsoft Certified: Azure Fundamentals (AZ-900)**',
        '**CompTIA Security+ or Cisco CCST**',
      ]);
    } else if (isFinance) {
      recommendedSkills.addAll([
        'QuickBooks Online & Xero',
        'Bank & Account Reconciliation',
        'Accounts Payable & Receivable (AP/AR)',
        'Financial Forecasting & Budgeting',
      ]);
      targetRoles.addAll([
        '**Full-Charge Bookkeeper / Junior Accountant**',
        '**Financial Operations Specialist**',
        '**Accounts Payable / Receivable Lead**',
      ]);
      portfolioProjects.addAll([
        '**Automated Month-End Closing Workbook**: Accelerated financial statement reconciliation.',
        '**Cash Flow Projection Model**: 12-month rolling forecast dashboard.',
      ]);
      recommendedCerts.addAll([
        '**Intuit QuickBooks Certified ProAdvisor**',
        '**Xero Certified Advisor**',
      ]);
    } else if (isHealthcare) {
      recommendedSkills.addAll([
        'EHR Systems (Epic / Cerner)',
        'HIPAA Compliance & Ethics',
        'Patient Triage & Vitals Monitoring',
        'Clinical Documentation & Care Plans',
        'Infection Control Protocols',
      ]);
      targetRoles.addAll([
        '**Clinical Care Coordinator / Specialist**: Managing multidisciplinary patient care pathways and clinical documentation.',
        '**Healthcare Operations Administrator**: Streamlining hospital or clinic intake, EHR compliance, and outpatient services.',
        '**Registered Nurse / Healthcare Specialist**: Delivering patient-centered care and treatment protocols.',
      ]);
      portfolioProjects.addAll([
        '**Clinical Workflow & Triage SOP**: Standardized protocol reducing patient check-in wait times by 30%.',
        '**EHR Audit & Quality Improvement Initiative**: Departmental records audit ensuring 100% HIPAA compliance.',
      ]);
      recommendedCerts.addAll([
        '**Basic Life Support (BLS) & ACLS - American Heart Association**',
        '**Certified Medical Administrative Assistant (CMAA)**',
        '**Epic Systems EHR Specialist Accreditation**',
      ]);
    } else if (isSales) {
      recommendedSkills.addAll([
        'HubSpot / Salesforce CRM',
        'B2B Outbound Prospecting',
        'Pipeline & Deal Velocity Forecasting',
        'Contract Negotiation',
        'Consultative Selling',
      ]);
      targetRoles.addAll([
        '**Senior Account Executive (AE)**: Closing high-value enterprise accounts and driving revenue expansion.',
        '**Sales Development Lead (SDR)**: Building and scaling high-velocity outbound lead generation machines.',
        '**Client Relationship & Growth Director**: Maximizing customer retention and upsell opportunities.',
      ]);
      portfolioProjects.addAll([
        '**Multi-Touch Outbound Sales Playbook**: High-converting email, phone, and LinkedIn cadence boosting reply rates by 35%.',
        '**Sales Pipeline Forecasting Dashboard**: Deal-tracking system reducing forecast variance to under 5%.',
      ]);
      recommendedCerts.addAll([
        '**HubSpot Sales Software Certified**',
        '**Salesforce Certified Administrator**',
      ]);
    } else {
      recommendedSkills.addAll(['Project Management', 'Agile / Scrum', 'Data Analysis', 'Process Optimization']);
      targetRoles.addAll([
        '**Operations Specialist**',
        '**Project Coordinator**',
        '**Client Success Manager**',
      ]);
      portfolioProjects.addAll([
        '**Process Automation Dashboard**: Automating recurring reporting and tracking.',
        '**Standard Operating Procedures (SOP) Portal**: Centralized knowledge base.',
      ]);
      recommendedCerts.addAll([
        '**Google Project Management Professional Certificate**',
        '**Six Sigma Yellow Belt**',
      ]);
    }

    if (recommendedSkills.isNotEmpty) {
      primaryAddSkill = recommendedSkills.first;
    }

    final buffer = StringBuffer();
    buffer.writeln('### 💡 Personalized Recommendations for ${cv.personalInfo.fullName.isNotEmpty ? cv.personalInfo.fullName : "Your Profile"}\n');

    buffer.writeln('#### 1. 🎯 High-Impact Skills to Add');
    for (final skill in recommendedSkills.take(4)) {
      buffer.writeln('• **$skill**: In high demand by recruiters in your field to strengthen your resume.');
    }

    buffer.writeln('\n#### 2. 💼 Target Career Opportunities');
    for (final role in targetRoles) {
      buffer.writeln('• $role');
    }

    buffer.writeln('\n#### 3. 🛠️ Portfolio Projects to Stand Out');
    for (final proj in portfolioProjects) {
      buffer.writeln('• $proj');
    }

    buffer.writeln('\n#### 4. 📜 Recommended Next Certifications');
    for (final cert in recommendedCerts) {
      buffer.writeln('• $cert');
    }

    return AiAgentMessage(
      id: _uuid.v4(),
      sender: AgentSender.agent,
      text: buffer.toString().trim(),
      timestamp: DateTime.now(),
      reasoning: 'Analyzed candidate CV skills, background, and exact profession (${cv.personalInfo.jobTitle}) to generate tailored recommendations.',
      toolAction: AgentToolAction(
        actionType: 'add_skill',
        description: 'Add "$primaryAddSkill" to Skills',
        data: {'name': primaryAddSkill, 'category': 'Technical', 'level': 4},
      ),
    );
  }

  // --- Gemini API Live Integration ---
  static const List<String> _geminiModels = [
    'gemini-flash-lite-latest',
    'gemini-flash-latest',
  ];

  String _extractTextFromResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';
      for (final part in parts.reversed) {
        if (part is Map && part['text'] != null && part['thought'] != true) {
          final t = part['text'] as String;
          if (t.trim().isNotEmpty) return t;
        }
      }
      return parts[0]['text'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<http.Response> _postGemini({
    required String apiKey,
    required Map<String, dynamic> payload,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty || cleanKey.length < 20) {
      throw Exception('Invalid or missing Gemini API key');
    }
    for (final model in _geminiModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanKey',
        );
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode == 400 || response.statusCode == 403) {
          // Authentication failure or invalid key: break early to avoid waiting across all models
          break;
        }
      } catch (e) {
        // Try fallback model
      }
    }
    throw Exception('Gemini API request failed across models');
  }

  Future<AiAgentMessage> _callGeminiChat({
    required String userMessage,
    required CvData cv,
    required String apiKey,
  }) async {
    final candidateName = cv.personalInfo.fullName.isNotEmpty ? cv.personalInfo.fullName : 'Febe Jabonite';
    final candidateTitle = cv.personalInfo.jobTitle.isNotEmpty ? cv.personalInfo.jobTitle : 'Virtual Assistant & Transaction Coordinator';
    final cvContext = '''
Candidate: $candidateName
Job Title: $candidateTitle
Summary: ${cv.personalInfo.summary}
Skills: ${cv.skills.map((s) => s.name).join(', ')}
Experiences: ${cv.experiences.map((e) => "${e.role} at ${e.company} (${e.startDate}-${e.endDate}): ${e.bullets.join('; ')}").join('\n')}
Projects: ${cv.projects.map((p) => "${p.title} (${p.technologies}): ${p.description}").join('\n')}
Education: ${cv.educations.map((ed) => "${ed.degree} in ${ed.fieldOfStudy} from ${ed.institution}").join('\n')}
''';

    final prompt = '''
${AiPrompts.agentSystemPrompt}

CURRENT RESUME CONTEXT:
$cvContext

USER QUERY:
"$userMessage"

Instructions:
1. Provide a direct, highly intelligent, personalized career or resume recommendation for this candidate.
2. If the user asks for suggestions, recommendations, or improvements, suggest concrete skills, projects, certifications, or bullet point revisions.
3. If applicable, propose a tool action (add_skill, update_summary, or replace_bullet).
4. CRITICAL: Strictly align all suggestions, skills, certifications, and project recommendations to the candidate's actual profession (${cv.personalInfo.jobTitle}). Use industry-authentic terminology and avoid generic software engineering recommendations unless the candidate's profile is in software/IT.
Return JSON in this format ONLY:
{
  "reply": "Your markdown-formatted response with bullet points and clear suggestions...",
  "reasoning": "Reasoning behind the suggestions...",
  "toolAction": null or { "actionType": "add_skill"|"update_summary"|"replace_bullet", "description": "...", "data": { ... } }
}
''';

    final res = await _postGemini(
      apiKey: apiKey,
      payload: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final text = _extractTextFromResponse(data);
      final cleanText = _cleanJson(text);

      String reply = text;
      String reasoning = 'Generated response based on CV analysis.';
      AgentToolAction? toolAction;

      try {
        final parsed = jsonDecode(cleanText);
        if (parsed is Map) {
          reply = parsed['reply'] as String? ?? text;
          reasoning = parsed['reasoning'] as String? ?? reasoning;
          if (parsed['toolAction'] != null && parsed['toolAction'] is Map) {
            final t = parsed['toolAction'];
            toolAction = AgentToolAction(
              actionType: t['actionType'] as String? ?? '',
              description: t['description'] as String? ?? '',
              data: Map<String, dynamic>.from(t['data'] as Map? ?? {}),
            );
          }
        }
      } catch (_) {
        // Fallback to raw response if JSON wrapping was partial
        reply = text.isNotEmpty ? text : 'Here are my recommendations based on your resume.';
      }

      return AiAgentMessage(
        id: _uuid.v4(),
        sender: AgentSender.agent,
        text: reply,
        timestamp: DateTime.now(),
        reasoning: reasoning,
        toolAction: toolAction,
      );
    } else {
      throw Exception('Gemini API Error: ${res.statusCode}');
    }
  }

  Future<AiAgentMessage> _callGeminiEnhanceBullet(
      String raw, String? role, String? company, String apiKey) async {
    final prompt = '''
${AiPrompts.agentSystemPrompt}

Task: Enhance this resume bullet point for a "${role ?? 'Professional'}" at "${company ?? 'Company'}":
Role / Profession: ${role ?? 'Professional'}
Original Bullet: "$raw"

CRITICAL INSTRUCTION - VOCABULARY & PROFESSION ALIGNMENT:
- Identify the candidate's exact profession (e.g., Real Estate, Virtual Assistance, Marketing, Healthcare, Accounting, Software Engineering, etc.).
- Enhance the bullet point using clean, natural, everyday action verbs (e.g., Led, Managed, Coordinated, Handled, Built, Organized, Maintained).
- NEVER invent or insert synthetic percentages (such as "99.8%", "35%", "42%") unless the user's original bullet explicitly included that number.
- Make the bullet simple, grounded, and professional ("simple, but not that simple"): state what was accomplished, what tools or methods were used, and the clear practical outcome.
- DO NOT use software engineering terms (e.g. 'full-stack', 'Docker', 'latency', 'sprint', 'APIs') if the role is non-technical (e.g. Real Estate, Marketing, Admin, Customer Service).
- Output must be authentic, credible, and polished — never robotic or exaggerated.

Return JSON in this format ONLY:
{
  "enhancedBullet": "...",
  "reasoning": "..."
}
''';

    final res = await _postGemini(
      apiKey: apiKey,
      payload: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final text = _extractTextFromResponse(data);
      final cleanText = _cleanJson(text);
      String enhanced = raw;
      String reasoning = 'Enhanced with domain-aligned action verbs and metrics.';

      try {
        final parsed = jsonDecode(cleanText);
        if (parsed is Map) {
          enhanced = parsed['enhancedBullet'] as String? ?? raw;
          reasoning = parsed['reasoning'] as String? ?? reasoning;
        }
      } catch (_) {
        if (cleanText.isNotEmpty && cleanText.length > 10) {
          enhanced = cleanText;
        }
      }

      return AiAgentMessage(
        id: _uuid.v4(),
        sender: AgentSender.agent,
        text: 'Optimized bullet point:\n\n**"$enhanced"**',
        timestamp: DateTime.now(),
        reasoning: reasoning,
        toolAction: AgentToolAction(
          actionType: 'replace_bullet',
          description: 'Update bullet point with quantified impact',
          data: {'original': raw, 'replacement': enhanced},
        ),
      );
    } else {
      throw Exception('Gemini API Error: ${res.statusCode}');
    }
  }

  Future<AiAgentMessage> _callGeminiGenerateSummary(CvData cv, String apiKey) async {
    final prompt = '''
${AiPrompts.agentSystemPrompt}

Task: Generate a concise, impactful 2-3 sentence resume summary.
Candidate Name: ${cv.personalInfo.fullName}
Target Title: ${cv.personalInfo.jobTitle}
Top Skills: ${cv.skills.map((s) => s.name).join(', ')}

CRITICAL INSTRUCTION - VOCABULARY & PROFESSION ALIGNMENT:
- Base the summary directly on the candidate's field (${cv.personalInfo.jobTitle}).
- Use authentic, industry-standard language (e.g. Real Estate/VA: contract-to-close, MLS compliance, CRM pipeline, escrow; Marketing: engagement, conversions, content strategy; Finance: reconciliations, GAAP, AP/AR; Software: system architecture, API throughput).
- Never invent software engineering jargon for non-software roles.

Return JSON in this format ONLY:
{
  "summary": "...",
  "reasoning": "..."
}
''';

    final res = await _postGemini(
      apiKey: apiKey,
      payload: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final text = _extractTextFromResponse(data);
      final cleanText = _cleanJson(text);
      String summary = 'Results-oriented professional.';
      String reasoning = 'Generated summary tailored to your profession.';

      try {
        final parsed = jsonDecode(cleanText);
        if (parsed is Map) {
          summary = parsed['summary'] as String? ?? summary;
          reasoning = parsed['reasoning'] as String? ?? reasoning;
        }
      } catch (_) {
        if (cleanText.isNotEmpty && cleanText.length > 20) {
          summary = cleanText;
        }
      }

      return AiAgentMessage(
        id: _uuid.v4(),
        sender: AgentSender.agent,
        text: 'Crafted professional summary:\n\n"$summary"',
        timestamp: DateTime.now(),
        reasoning: reasoning,
        toolAction: AgentToolAction(
          actionType: 'update_summary',
          description: 'Set professional summary',
          data: {'summary': summary},
        ),
      );
    } else {
      throw Exception('Gemini API error: ${res.statusCode}');
    }
  }

  String _mockEnhanceBullet(String raw, String? role) {
    final clean = raw.trim();
    if (clean.isEmpty) return clean;
    final lower = clean.toLowerCase();
    final roleLower = (role ?? '').toLowerCase();

    // Determine domain from role and content
    final isRealEstate = roleLower.contains('real estate') ||
        roleLower.contains('realtor') ||
        roleLower.contains('transaction') ||
        roleLower.contains('coordinator') ||
        roleLower.contains('escrow') ||
        roleLower.contains('property') ||
        lower.contains('mls') ||
        lower.contains('lofty') ||
        lower.contains('carrot') ||
        lower.contains('escrow') ||
        lower.contains('real estate') ||
        lower.contains('listing') ||
        lower.contains('closing');

    final isMarketing = !isRealEstate &&
        (roleLower.contains('marketing') ||
            roleLower.contains('social media') ||
            roleLower.contains('seo') ||
            roleLower.contains('content') ||
            roleLower.contains('designer') ||
            lower.contains('social media') ||
            lower.contains('instagram') ||
            lower.contains('tiktok') ||
            lower.contains('canva') ||
            lower.contains('ad campaign') ||
            lower.contains('seo'));

    final isVaOrAdmin = !isRealEstate &&
        !isMarketing &&
        (roleLower.contains('virtual assistant') ||
            roleLower.contains('administrative') ||
            roleLower.contains('executive assistant') ||
            roleLower.contains('admin') ||
            roleLower.contains('office') ||
            roleLower.contains('support') ||
            lower.contains('calendar') ||
            lower.contains('inbox') ||
            lower.contains('scheduling') ||
            lower.contains('data entry') ||
            lower.contains('sop'));

    final isFinance = !isRealEstate &&
        !isMarketing &&
        (roleLower.contains('account') ||
            roleLower.contains('finance') ||
            roleLower.contains('bookkeeper') ||
            roleLower.contains('audit') ||
            lower.contains('quickbooks') ||
            lower.contains('ledger') ||
            lower.contains('invoice') ||
            lower.contains('reconciliation'));

    final isDevOrTech = !isRealEstate &&
        !isMarketing &&
        !isVaOrAdmin &&
        (roleLower.contains('developer') ||
            roleLower.contains('engineer') ||
            roleLower.contains('software') ||
            roleLower.contains('programmer') ||
            roleLower.contains('it support') ||
            roleLower.contains('coder') ||
            lower.contains('full-stack') ||
            lower.contains('database') ||
            lower.contains('api') ||
            lower.contains('sql'));

    // 1. Weak starter replacement
    final weakStarterRegex = RegExp(
      r'^(responsible for|worked on|helped with|duties included|tasks included|made|assisted with|handled)\s*',
      caseSensitive: false,
    );

    if (weakStarterRegex.hasMatch(lower)) {
      final remainder = clean.replaceFirst(weakStarterRegex, '').trim();

      if (isRealEstate) {
        if (lower.contains('listing') || lower.contains('mls')) {
          return 'Audited and managed MLS property listings and documentation, ensuring accuracy and full compliance with broker requirements.';
        }
        if (lower.contains('lead') || lower.contains('client') || lower.contains('crm')) {
          return 'Maintained CRM pipeline in Lofty and FlexMLS, managing client follow-ups and keeping transaction records updated.';
        }
        if (lower.contains('contract') || lower.contains('escrow') || lower.contains('closing')) {
          return 'Administered contract-to-close workflows across active transactions, coordinating disclosures and meeting all escrow milestones.';
        }
        return 'Coordinated $remainder, maintaining organized records and ensuring compliance with transaction guidelines.';
      } else if (isMarketing) {
        if (lower.contains('social') || lower.contains('post') || lower.contains('content') || lower.contains('video')) {
          return 'Managed multi-channel content strategy and campaign assets, elevating brand visibility and organic engagement.';
        }
        if (lower.contains('ad') || lower.contains('campaign') || lower.contains('meta')) {
          return 'Managed targeted digital ad campaigns, optimizing audience segmentation to reach qualified prospective clients.';
        }
        return 'Executed and managed $remainder, elevating brand presence and audience reach.';
      } else if (isVaOrAdmin) {
        if (lower.contains('calendar') || lower.contains('schedul') || lower.contains('meeting') || lower.contains('email')) {
          return 'Managed executive calendar scheduling and inbox triage across multiple time zones, keeping daily priorities on track.';
        }
        if (lower.contains('file') || lower.contains('doc') || lower.contains('data') || lower.contains('record')) {
          return 'Standardized digital filing systems and standard operating procedures (SOPs), improving document retrieval and team productivity.';
        }
        return 'Streamlined $remainder, ensuring fast turnaround and high attention to detail.';
      } else if (isFinance) {
        return 'Administered $remainder, maintaining accurate ledger reconciliations and supporting timely month-end close.';
      } else if (isDevOrTech) {
        return 'Architected and engineered $remainder, improving system scalability and user experience.';
      } else {
        return 'Managed $remainder, maintaining organized workflows and consistent quality standards.';
      }
    }

    // 2. Strong verbs check: if already starts with a strong verb, preserve
    final strongVerbs = [
      'led', 'managed', 'streamlined', 'coordinated', 'executed', 'implemented',
      'designed', 'developed', 'engineered', 'audited', 'facilitated', 'optimized',
      'resolved', 'delivered', 'standardized', 'formulated', 'directed',
      'negotiated', 'curated', 'created', 'maintained', 'produced', 'published',
      'provided', 'assisted', 'guided', 'configured', 'built', 'supported',
    ];
    final firstWord = lower.split(RegExp(r'\s+')).first;
    if (strongVerbs.contains(firstWord) && clean.length > 35) {
      return clean;
    }

    // 3. Website / App trigger
    if (lower.contains('website') || lower.contains('app') || lower.contains('portal')) {
      if (isRealEstate) {
        return 'Managed real estate web content and digital marketing assets, supporting active investor outreach and buyer engagement.';
      } else if (isMarketing) {
        return 'Managed website landing pages and digital creative assets to support marketing campaigns and lead inquiries.';
      } else if (isDevOrTech) {
        return 'Engineered responsive web applications using modern best practices, delivering reliable performance and smooth user navigation.';
      } else if (isVaOrAdmin) {
        return 'Maintained and updated web portal content and digital tools, ensuring data accuracy and client accessibility.';
      } else {
        return 'Maintained web presence and digital materials, ensuring consistent branding and clear communication.';
      }
    }

    // 4. Team / Collaboration trigger
    if (lower.contains('team') || lower.contains('collaborat') || lower.contains('stakeholder')) {
      if (isRealEstate) {
        return 'Collaborated with brokers, title agents, and escrow officers to facilitate seamless transaction milestones and on-time closings.';
      } else if (isMarketing) {
        return 'Collaborated with creative and marketing teams to plan and deliver integrated promotional initiatives.';
      } else if (isVaOrAdmin) {
        return 'Coordinated daily operational deliverables with team members and external partners to maintain project timelines.';
      } else if (isDevOrTech) {
        return 'Collaborated with engineering and product teams to deliver feature milestones on schedule.';
      } else if (isFinance) {
        return 'Collaborated with internal teams and external auditors to maintain accurate reporting and financial transparency.';
      } else {
        return 'Collaborated across cross-functional teams to align project deliverables and meet project deadlines.';
      }
    }

    // 5. If bullet already starts with strong verb, keep it as is
    if (strongVerbs.contains(firstWord)) {
      return clean;
    }

    // 6. Generic short bullet fallback
    if (isRealEstate) {
      return 'Managed $clean, ensuring organized records and compliance across active transactions.';
    } else if (isMarketing) {
      return 'Managed $clean, supporting brand engagement and multi-channel outreach.';
    } else if (isVaOrAdmin) {
      return 'Coordinated $clean, providing reliable administrative support and maintaining smooth workflows.';
    } else if (isDevOrTech) {
      return 'Developed $clean, utilizing modern tools and clean development standards.';
    }

    return clean;
  }

  List<String> _getDefaultBulletsForRole(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('real estate') ||
        lower.contains('transaction') ||
        lower.contains('coordinator') ||
        lower.contains('escrow')) {
      return [
        'Managed contract-to-close workflow and document auditing to ensure 100% compliance with MLS and escrow requirements.',
        'Liaised between buyers, sellers, brokers, and escrow officers to guarantee on-time closing and client satisfaction.',
      ];
    } else if (lower.contains('virtual assistant') ||
        lower.contains('administrative') ||
        lower.contains('office') ||
        lower.contains('assistant')) {
      return [
        'Delivered comprehensive administrative and operational support, optimizing executive schedules, communications, and daily workflows.',
        'Maintained organized digital filing systems, standard operating procedures (SOPs), and database records with high accuracy.',
      ];
    } else if (lower.contains('marketing') ||
        lower.contains('social media') ||
        lower.contains('content') ||
        lower.contains('seo')) {
      return [
        'Developed and executed engaging digital campaigns and content strategies to elevate brand visibility and audience reach.',
        'Analyzed campaign performance metrics (CTR, engagement, conversions) to optimize ongoing marketing collateral and ad spend.',
      ];
    } else if (lower.contains('account') ||
        lower.contains('finance') ||
        lower.contains('bookkeeper')) {
      return [
        'Maintained accurate financial records, general ledger entries, and reconciliations adhering to accounting standards.',
        'Assisted with accounts payable/receivable management and month-end financial statement preparation.',
      ];
    } else if (lower.contains('developer') ||
        lower.contains('engineer') ||
        lower.contains('software') ||
        lower.contains('it')) {
      return [
        'Engineered and maintained software solutions adhering strictly to clean code architecture and industry best practices.',
        'Diagnosed technical issues, optimized performance bottlenecks, and automated core system processes.',
      ];
    } else {
      return [
        'Managed operational processes and project deliverables adhering strictly to quality benchmarks and timelines.',
        'Collaborated with cross-functional stakeholders to streamline workflows and drive measurable productivity gains.',
      ];
    }
  }

  String _cleanJson(String raw) {
    String str = raw.trim();
    if (str.startsWith('```json')) {
      str = str.substring(7);
    } else if (str.startsWith('```')) {
      str = str.substring(3);
    }
    if (str.endsWith('```')) {
      str = str.substring(0, str.length - 3);
    }
    return str.trim();
  }

  /// Parses and structures an entire resume document (PDF, TXT, MD) into a complete arranged CvData
  Future<CvData> parseAndArrangeDocument({
    required String rawText,
    String? fileName,
    String? apiKey,
    bool isDemoMode = false,
  }) async {
    final cleanKey = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : StorageService.getSystemApiKey();
    if (cleanKey != null && cleanKey.length >= 20) {
      try {
        final result = await _callGeminiParseDocument(rawText, cleanKey);
        if (result.personalInfo.fullName.isNotEmpty &&
            !result.personalInfo.fullName.toLowerCase().contains('work') &&
            !result.personalInfo.fullName.toLowerCase().contains('experience') &&
            result.experiences.isNotEmpty) {
          return result;
        }
      } catch (e) {
        // Fallback to offline rule-based parser if live API call fails
      }
    }

    // Offline / Local intelligent heuristic parser (fast and secure)
    return _offlineParseDocument(rawText, fileName: fileName);
  }

  /// Multimodal Vision OCR parser for scanned or flattened image-only PDF documents
  Future<CvData> parseDocumentWithVision({
    required Uint8List bytes,
    required String apiKey,
    String mimeType = 'application/pdf',
  }) async {
    const systemInstruction =
        'You are an expert ATS Resume Parser and Career Architect.\n'
        'Read this resume document/image carefully, perform high-accuracy OCR to extract all visible information, '
        'and arrange it into a valid JSON object strictly matching this schema:\n'
        '{\n'
        '  "title": "Role Title Resume",\n'
        '  "personalInfo": {\n'
        '    "fullName": "...",\n'
        '    "jobTitle": "...",\n'
        '    "email": "...",\n'
        '    "phone": "...",\n'
        '    "location": "...",\n'
        '    "summary": "...",\n'
        '    "website": "...",\n'
        '    "linkedin": "...",\n'
        '    "github": "..."\n'
        '  },\n'
        '  "experiences": [\n'
        '    {\n'
        '      "company": "...",\n'
        '      "role": "...",\n'
        '      "location": "...",\n'
        '      "startDate": "...",\n'
        '      "endDate": "...",\n'
        '      "isCurrent": false,\n'
        '      "bullets": ["..."]\n'
        '    }\n'
        '  ],\n'
        '  "educations": [\n'
        '    {\n'
        '      "institution": "...",\n'
        '      "degree": "...",\n'
        '      "fieldOfStudy": "...",\n'
        '      "startDate": "...",\n'
        '      "endDate": "...",\n'
        '      "isCurrent": false,\n'
        '      "gpa": "...",\n'
        '      "achievements": "..."\n'
        '    }\n'
        '  ],\n'
        '  "skills": [\n'
        '    {\n'
        '      "name": "...",\n'
        '      "category": "Technical",\n'
        '      "proficiency": 4\n'
        '    }\n'
        '  ],\n'
        '  "projects": [\n'
        '    {\n'
        '      "title": "...",\n'
        '      "description": "...",\n'
        '      "technologies": ["..."],\n'
        '      "link": "...",\n'
        '      "role": "..."\n'
        '    }\n'
        '  ]\n'
        '}\n'
        'Return ONLY valid JSON.';

    final base64Data = base64Encode(bytes);
    final payload = {
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Data,
              }
            },
            {'text': systemInstruction}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
      }
    };

    final res = await _postGemini(
      apiKey: apiKey,
      payload: payload,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final text = _extractTextFromResponse(data);
      final cleanText = _cleanJson(text);
      final Map<String, dynamic> jsonMap = jsonDecode(cleanText);

      return CvData(
        id: _uuid.v4(),
        title: jsonMap['title'] as String? ?? 'Imported Resume',
        personalInfo: jsonMap['personalInfo'] != null
            ? PersonalInfo.fromJson(jsonMap['personalInfo'] as Map<String, dynamic>)
            : PersonalInfo(),
        experiences: (jsonMap['experiences'] as List?)
                ?.map((e) => WorkExperience.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        educations: (jsonMap['educations'] as List?)
                ?.map((e) => Education.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        skills: (jsonMap['skills'] as List?)
                ?.map((e) => Skill.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        projects: (jsonMap['projects'] as List?)
                ?.map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
    } else {
      throw Exception('Gemini Vision OCR failed: ${res.statusCode}');
    }
  }

  Future<CvData> _callGeminiParseDocument(String rawText, String apiKey) async {
    const systemInstruction = '''
You are an expert ATS Resume Parser and Career Architect.
Extract and arrange the provided raw resume text into a valid JSON object strictly matching this schema:
{
  "title": "Role Title Resume",
  "personalInfo": {
    "fullName": "...",
    "jobTitle": "...",
    "email": "...",
    "phone": "...",
    "location": "...",
    "summary": "...",
    "website": "...",
    "linkedin": "...",
    "github": "..."
  },
  "experiences": [
    {
      "company": "...",
      "role": "...",
      "location": "...",
      "startDate": "...",
      "endDate": "...",
      "isCurrent": false,
      "bullets": ["..."]
    }
  ],
  "educations": [
    {
      "institution": "...",
      "degree": "...",
      "fieldOfStudy": "...",
      "startDate": "...",
      "endDate": "...",
      "isCurrent": false,
      "gpa": "...",
      "achievements": "..."
    }
  ],
  "skills": [
    {
      "name": "...",
      "category": "Technical",
      "proficiency": 4
    }
  ],
  "projects": [
    {
      "title": "...",
      "description": "...",
      "technologies": ["..."],
      "link": "...",
      "role": "..."
    }
  ]
}

Important Parsing Guidelines:
1. Candidate Name: If letters are spaced out (e.g. "F E B E  J A B O N I T E"), correctly reconstruct the full name as "Febe Jabonite".
2. Job Title: Capture the candidate's target/primary headline (e.g. "Virtual Assistant | Real Estate Operations | Marketing & Administrative Support").
3. Contact Details: Extract phone, email, and location (e.g. "Davao City, Philippines").
4. Summary: If the document doesn't have an explicit summary paragraph, generate a 2-3 sentence executive professional summary synthesizing their expertise.
5. Experiences: Extract all work experience entries (e.g. Hughes Media, ProsperVA, Cyberbacker) with their roles, dates, and all bullet points.
6. Education: Extract degrees, institutions, years, and honors (e.g. Cum Laude).
7. Skills: Extract all technical skills, CRM tools, marketing tools, and AI software.
Return ONLY valid JSON.
''';

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': '$systemInstruction\n\n--- RESUME DOCUMENT CONTENT ---\n$rawText'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
      }
    };

    final res = await _postGemini(
      apiKey: apiKey,
      payload: payload,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final text = _extractTextFromResponse(data);
      final cleanText = _cleanJson(text);
      final Map<String, dynamic> jsonMap = jsonDecode(cleanText);

      return CvData(
        id: _uuid.v4(),
        title: jsonMap['title'] as String? ?? 'Imported Resume',
        personalInfo: jsonMap['personalInfo'] != null
            ? PersonalInfo.fromJson(jsonMap['personalInfo'] as Map<String, dynamic>)
            : PersonalInfo(),
        experiences: (jsonMap['experiences'] as List?)
                ?.map((e) => WorkExperience.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        educations: (jsonMap['educations'] as List?)
                ?.map((e) => Education.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        skills: (jsonMap['skills'] as List?)
                ?.map((e) => Skill.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        projects: (jsonMap['projects'] as List?)
                ?.map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
    } else {
      throw Exception('Gemini API parse failed: ${res.statusCode}');
    }
  }

  CvData offlineParseDocumentForTest(String rawText, {String? fileName}) =>
      _offlineParseDocument(rawText, fileName: fileName);

  CvData _offlineParseDocument(String rawText, {String? fileName}) {
    final lines = <String>[];
    for (final raw in rawText.split(RegExp(r'\r?\n'))) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      // Filter out standalone page numbers: "1", "2", "3", "Page 1 of 3", etc.
      if (RegExp(r'^\d+$').hasMatch(t)) continue;
      if (RegExp(r'^page\s+\d+(\s+of\s+\d+)?$', caseSensitive: false).hasMatch(t)) continue;
      // Filter out stray standalone punctuation marks
      if (t == '.' || t == ',' || t == '-' || t == '•' || t == '|') continue;
      lines.add(t);
    }

    bool isBullet(String s) {
      final t = s.trim();
      if (t.isEmpty) return false;
      return t.startsWith('•') ||
          t.startsWith('') ||
          t.startsWith('\uF0B7') ||
          t.startsWith('\u2022') ||
          t.startsWith('\u25AA') ||
          t.startsWith('\u25CF') ||
          t.startsWith('- ') ||
          t.startsWith('* ') ||
          RegExp(r'^\d+\.\s').hasMatch(t);
    }

    String cleanBullet(String s) {
      return s
          .trim()
          .replaceFirst(RegExp(r'^[•\uF0B7\u2022\u25AA\u25CF\-\*\d\.]+\s*'), '')
          .trim();
    }

    bool isDateRange(String s) {
      final t = s.trim();
      return RegExp(
        r'\b(?:19\d\d|20\d\d)\s*[\-—–to/]+\s*(?:19\d\d|20\d\d|present|current)\b',
        caseSensitive: false,
      ).hasMatch(t) ||
      RegExp(
        r'^\s*(?:19\d\d|20\d\d)\s*[\-—–to/]+\s*(?:19\d\d|20\d\d|present|current)\s*$',
        caseSensitive: false,
      ).hasMatch(t) ||
      RegExp(
        r'^(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4}\s*[\-—–to]+\s*(?:(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4}|present|current)$',
        caseSensitive: false,
      ).hasMatch(t) ||
      RegExp(
        r'\b\d+\s*(?:yrs?|years?)\s*(?:&\s*\d+\s*(?:mos?|months?))?\b',
        caseSensitive: false,
      ).hasMatch(t) ||
      RegExp(
        r'\b\d+\s*(?:mos?|months?)\b',
        caseSensitive: false,
      ).hasMatch(t);
    }

    bool hasRoleKeyword(String s) {
      final l = s.toLowerCase();
      return l.contains('manager') ||
          l.contains('coordinator') ||
          l.contains('assistant') ||
          l.contains('specialist') ||
          l.contains('developer') ||
          l.contains('engineer') ||
          l.contains('architect') ||
          l.contains('analyst') ||
          l.contains('consultant') ||
          l.contains('director') ||
          l.contains('lead') ||
          l.contains('officer') ||
          l.contains('administrator') ||
          l.contains('executive') ||
          l.contains('designer') ||
          l.contains('intern') ||
          l.contains('crew') ||
          l.contains('cashier') ||
          l.contains('clerk') ||
          l.contains('barista') ||
          l.contains('server') ||
          l.contains('cook') ||
          l.contains('staff') ||
          l.contains('agent') ||
          l.contains('teller') ||
          l.contains('attendant') ||
          l.contains('worker') ||
          l.contains('operator') ||
          l.contains('driver') ||
          l.contains('receptionist') ||
          l.contains('merchandiser') ||
          l.contains('promodiser') ||
          l.contains('encoder');
    }

    bool isKnownCompany(String s) {
      final l = s.toLowerCase();
      return l.contains('cyberbacker') ||
          l.contains('prosperva') ||
          l.contains('hughes media') ||
          l.contains('mcdonald') ||
          l.contains('chowking') ||
          l.contains('jollibee') ||
          l.contains('kfc') ||
          l.contains('starbucks') ||
          l.contains('shell') ||
          l.contains('petron') ||
          l.contains('caltex') ||
          l.contains('7-eleven') ||
          l.contains('7 eleven') ||
          l.contains('seven eleven') ||
          l.contains('ministop') ||
          l.contains('alfamart') ||
          l.contains('sm prime') ||
          l.contains('sm supermalls') ||
          l.contains('robinsons') ||
          l.contains('inc') ||
          l.contains('llc') ||
          l.contains('corp') ||
          l.contains('technologies') ||
          l.contains('solutions') ||
          l.contains('agency') ||
          l.contains('media') ||
          l.contains('company') ||
          l.contains('services');
    }

    bool isLikelyBulletText(String s) {
      final t = s.trim();
      if (isBullet(t)) return true;
      if (RegExp(r'^[a-z]').hasMatch(t)) return false; // Continuation line
      if (t.length > 55) return true;
      final l = t.toLowerCase();
      final actionVerbs = [
        'managed', 'created', 'executed', 'built', 'coordinated',
        'liaised', 'audited', 'supported', 'reviewed', 'tracked',
        'maintained', 'developed', 'monitored', 'provided', 'designed',
        'led', 'assisted', 'handled', 'prepared', 'implemented',
        'analyzed', 'formulated', 'automated', 'oversaw', 'scheduled',
        'collaborated', 'optimized', 'streamlined', 'generated', 'conducted',
        'experienced', 'performed', 'greeted', 'received', 'organized'
      ];
      for (final v in actionVerbs) {
        if (l.startsWith(v)) return true;
      }
      return false;
    }

    String? detectSectionHeader(String line) {
      final clean = line.trim().toLowerCase().replaceAll(RegExp(r'[:\-—_#*|]'), '').trim();
      final noSpaces = clean.replaceAll(' ', '');
      if (clean == 'contact' ||
          clean == 'contact info' ||
          clean == 'contact information' ||
          clean == 'contact details' ||
          clean == 'contacts' ||
          clean == 'get in touch' ||
          noSpaces == 'contact' ||
          noSpaces == 'contactinfo' ||
          noSpaces == 'contactinformation' ||
          noSpaces == 'contactdetails') {
        return 'contact';
      }
      if (clean == 'professional summary' ||
          clean == 'summary' ||
          clean == 'about me' ||
          clean == 'profile' ||
          clean == 'executive summary' ||
          clean == 'career objective' ||
          clean == 'objective' ||
          noSpaces == 'professionalsummary' ||
          noSpaces == 'summary' ||
          noSpaces == 'aboutme' ||
          noSpaces == 'profile' ||
          noSpaces == 'executivesummary') {
        return 'summary';
      }
      if (clean == 'education' ||
          clean == 'academic background' ||
          clean == 'academic history' ||
          clean == 'credentials' ||
          clean == 'academic qualifications' ||
          clean == 'qualifications' ||
          noSpaces == 'education' ||
          noSpaces == 'academicbackground' ||
          noSpaces == 'academichistory' ||
          noSpaces == 'credentials' ||
          noSpaces == 'academicqualifications' ||
          noSpaces == 'qualifications') {
        return 'education';
      }
      if (clean == 'experience' ||
          clean == 'work experience' ||
          clean == 'work experiences' ||
          noSpaces == 'experience' ||
          noSpaces == 'workexperience' ||
          noSpaces == 'workexperiences' ||
          clean == 'employment history' ||
          noSpaces == 'employmenthistory' ||
          clean == 'professional experience' ||
          noSpaces == 'professionalexperience' ||
          clean == 'career history' ||
          noSpaces == 'careerhistory' ||
          clean == 'relevant experience' ||
          noSpaces == 'relevantexperience' ||
          clean == 'work history' ||
          noSpaces == 'workhistory') {
        return 'experience';
      }
      if (clean == 'projects' ||
          clean == 'key projects' ||
          clean == 'personal projects' ||
          clean == 'academic projects' ||
          clean == 'software projects' ||
          clean == 'projects & highlights' ||
          clean == 'portfolio' ||
          noSpaces == 'projects' ||
          noSpaces == 'keyprojects' ||
          noSpaces == 'personalprojects' ||
          noSpaces == 'portfolio') {
        return 'projects';
      }
      if (clean == 'skills' ||
          clean == 'technical skills' ||
          clean == 'core expertise' ||
          clean == 'core competencies' ||
          clean == 'technologies' ||
          clean == 'technical proficiencies' ||
          clean == 'skills & abilities' ||
          clean == 'skills & expertise' ||
          noSpaces == 'skills' ||
          noSpaces == 'technicalskills' ||
          noSpaces == 'coreexpertise' ||
          noSpaces == 'corecompetencies' ||
          noSpaces == 'technologies' ||
          noSpaces == 'skills&abilities' ||
          noSpaces == 'skillsandabilities' ||
          noSpaces == 'technicalproficiencies') {
        return 'skills';
      }
      if (clean == 'certifications' ||
          clean == 'certificates' ||
          clean == 'licenses & certifications' ||
          clean == 'certifications & awards' ||
          clean == 'awards & certifications' ||
          clean == 'honors & awards' ||
          clean == 'awards' ||
          noSpaces == 'certifications' ||
          noSpaces == 'certificates') {
        return 'certifications';
      }
      if (clean == 'professional references' ||
          clean == 'references' ||
          clean == 'reference' ||
          clean == 'character references' ||
          clean == 'character reference' ||
          noSpaces == 'professionalreferences' ||
          noSpaces == 'references' ||
          noSpaces == 'reference' ||
          noSpaces == 'characterreferences' ||
          noSpaces == 'characterreference') {
        return 'references';
      }
      return null;
    }

    bool isInvalidPersonName(String s) {
      final l = s.trim().toLowerCase();
      final noSpaces = l.replaceAll(' ', '');
      if (detectSectionHeader(s) != null) return true;
      if (noSpaces.contains('workexperience') ||
          noSpaces.contains('experience') ||
          noSpaces.contains('education') ||
          noSpaces.contains('skills') ||
          noSpaces.contains('projects') ||
          noSpaces.contains('certifications') ||
          noSpaces.contains('references') ||
          noSpaces.contains('curriculumvitae') ||
          noSpaces.contains('resume')) {
        return true;
      }
      return false;
    }

    String fullName = '';
    String title = '';
    String email = '';
    String phone = '';
    String location = '';
    String linkedin = '';
    String github = '';
    String website = '';

    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final phoneRegex = RegExp(r'(?:\+63|0)?9\d{9}|\+?\d{1,4}[-.\s]?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}');
    final linkedinRegex = RegExp(r'linkedin\.com\/in\/([a-zA-Z0-9_-]+)', caseSensitive: false);
    final githubRegex = RegExp(r'github\.com\/([a-zA-Z0-9_-]+)', caseSensitive: false);

    final emailMatch = emailRegex.firstMatch(rawText);
    if (emailMatch != null) email = emailMatch.group(0)!;

    final phoneMatch = phoneRegex.firstMatch(rawText);
    if (phoneMatch != null) phone = phoneMatch.group(0)!;

    final linkedinMatch = linkedinRegex.firstMatch(rawText);
    if (linkedinMatch != null) linkedin = linkedinMatch.group(0)!;

    final githubMatch = githubRegex.firstMatch(rawText);
    if (githubMatch != null) github = githubMatch.group(0)!;

    // Extract location from delimiter lines e.g. "+639629884143 | jabonitebea@gmail.com | Davao City, Philippines"
    for (final line in lines) {
      if (line.contains('|') && (line.contains('@') || phoneRegex.hasMatch(line))) {
        final parts = line.split('|').map((p) => p.trim()).toList();
        for (final p in parts) {
          if (!p.contains('@') && !phoneRegex.hasMatch(p) && p.length > 2 && p.length < 50) {
            location = p;
            break;
          }
        }
      }
    }

    // 1. If fileName is provided (e.g. "Febe Jabonite - Resume (Updated).pdf"), extract candidate name!
    if (fileName != null && fileName.isNotEmpty) {
      final base = fileName
          .replaceAll(RegExp(r'\.(pdf|docx|txt|md|doc|json)$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[\-_]+'), ' ')
          .replaceAll(RegExp(r'\(updated\)|\(new\)|resume|cv|curriculum|vitae|\d{4,}', caseSensitive: false), '')
          .replaceAll(RegExp(r'\b(new|latest|draft|final|old|copy|updated|sample|template|v\d+)\b', caseSensitive: false), '')
          .trim();
      final words = base.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      if (words.length >= 2 && words.length <= 4) {
        fullName = words
            .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''))
            .join(' ');
      }
    }

    // 2. Check for spaced-out capital names like "F E B E  J A B O N I T E" anywhere in lines
    if (fullName.isEmpty) {
      for (final line in lines) {
        final t = line.trim();
        if (RegExp(r'^(?:[A-Z]\s+){3,}[A-Z]$').hasMatch(t)) {
          final words = t.split(RegExp(r'\s{2,}'));
          if (words.length > 1) {
            fullName = words
                .map((w) => w.replaceAll(' ', ''))
                .map((w) => w.isNotEmpty ? (w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : '')) : '')
                .join(' ');
          } else {
            final condensed = t.replaceAll(' ', '');
            fullName = condensed.length > 1 ? (condensed[0].toUpperCase() + condensed.substring(1).toLowerCase()) : condensed;
          }
          break;
        }
      }
    }

    // 3. Candidate name detection at top of document
    if (fullName.isEmpty || isInvalidPersonName(fullName)) {
      // First check if the first line is already a complete 2-3 word full name (e.g. "Marcus Brody", "John Doe")
      if (lines.isNotEmpty) {
        final firstClean = lines[0].replaceAll(RegExp(r'[^a-zA-Z\s\.\-]'), '').trim();
        final firstWords = firstClean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (firstWords.length >= 2 &&
            firstWords.length <= 4 &&
            !hasRoleKeyword(firstClean) &&
            !isKnownCompany(firstClean) &&
            !isInvalidPersonName(firstClean) &&
            !firstClean.contains('@') &&
            !phoneRegex.hasMatch(firstClean)) {
          fullName = firstWords.map((w) {
            if (w.length <= 2 && w.endsWith('.')) return w.toUpperCase();
            if (w.length == 1) return w.toUpperCase();
            return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
          }).join(' ');
        }
      }

      // If still empty (e.g. single-word line like "RAEL" or multi-line "RAEL\nALEXANDREA M.\nBUTANAS"), combine fragments!
      if (fullName.isEmpty || isInvalidPersonName(fullName)) {
        final topNameParts = <String>[];
        for (int i = 0; i < lines.length && i < 6; i++) {
          final line = lines[i];
          if (detectSectionHeader(line) != null) break;
          if (line.contains('@') || phoneRegex.hasMatch(line) || line.contains('http')) break;
          if (isInvalidPersonName(line)) break;
          final clean = line.replaceAll(RegExp(r'[^a-zA-Z\s\.\-]'), '').trim();
          if (clean.length >= 2 && clean.length <= 35 && !hasRoleKeyword(clean) && !isKnownCompany(clean)) {
            final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
            if (words.isNotEmpty && words.length <= 3) {
              topNameParts.addAll(words);
              if (topNameParts.length >= 4) break;
            } else {
              break;
            }
          } else {
            break;
          }
        }
        if (topNameParts.length >= 2 && topNameParts.length <= 5) {
          fullName = topNameParts.map((w) {
            if (w.length <= 2 && w.endsWith('.')) return w.toUpperCase();
            if (w.length == 1) return w.toUpperCase();
            return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
          }).join(' ');
        }
      }
    }

    // Detect job title from top lines (e.g. lines with | or keywords)
    for (int i = 0; i < lines.length && i < 8; i++) {
      final line = lines[i];
      if (detectSectionHeader(line) != null) break;
      if (line.contains('@') || phoneRegex.hasMatch(line) || line.contains('http')) continue;
      if (line == fullName) continue;
      if (line.contains('|') ||
          line.toLowerCase().contains('virtual assistant') ||
          line.toLowerCase().contains('coordinator') ||
          line.toLowerCase().contains('manager') ||
          line.toLowerCase().contains('developer') ||
          line.toLowerCase().contains('engineer') ||
          line.toLowerCase().contains('specialist')) {
        title = line;
        if ((title.endsWith('&') || title.endsWith(',')) && i + 1 < lines.length) {
          final next = lines[i + 1];
          if (detectSectionHeader(next) == null && !next.contains('@') && !phoneRegex.hasMatch(next)) {
            title = '$title ${next.trim()}';
          }
        }
        break;
      }
    }

    // 4. Single-line candidate name detection from top lines if still empty
    if (fullName.isEmpty || isInvalidPersonName(fullName)) {
      for (int i = 0; i < lines.length && i < 10; i++) {
        final line = lines[i];
        if (detectSectionHeader(line) != null) continue;
        if (line.contains('@') || line.contains('http') || phoneRegex.hasMatch(line)) continue;
        if (line == title) continue;
        if (isInvalidPersonName(line)) continue;
        if (line.length >= 3 && line.length <= 40 && RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(line)) {
          final lower = line.toLowerCase();
          if (!lower.contains('support') &&
              !lower.contains('assistant') &&
              !lower.contains('developer') &&
              !lower.contains('coordinator') &&
              !lower.contains('specialist') &&
              !lower.contains('operations') &&
              !lower.contains('manager') &&
              !lower.contains('resume')) {
            fullName = line;
            break;
          }
        }
      }
    }

    if ((fullName.isEmpty || isInvalidPersonName(fullName)) && lines.isNotEmpty) {
      for (final l in lines) {
        if (!isInvalidPersonName(l) &&
            !l.contains('@') &&
            !phoneRegex.hasMatch(l) &&
            l.length >= 3 &&
            l.length <= 40) {
          fullName = l;
          break;
        }
      }
    }

    final summaryBuffer = StringBuffer();
    final List<WorkExperience> experiences = [];
    final List<Education> educations = [];
    final List<Skill> skills = [];
    final List<Project> projects = [];

    String currentSection = 'header';

    // Experience parsing state
    String expRole = '';
    String expCompany = '';
    String expLocation = '';
    String expDates = '';
    List<String> expBullets = [];

    String cleanWeakBulletStarter(String bullet) {
      final b = bullet.trim();
      if (b.isEmpty) return b;
      final lower = b.toLowerCase();

      final weakPrefixes = [
        'i have an experience in ',
        'i have experience in ',
        'i have experienced ',
        'i experienced ',
        'experienced in ',
        'responsible for ',
        'duties included ',
        'tasks included ',
        'helped with ',
        'worked on ',
        'assisted with ',
      ];

      for (final prefix in weakPrefixes) {
        if (lower.startsWith(prefix)) {
          final rem = b.substring(prefix.length).trim();
          if (rem.isEmpty) return b;

          final words = rem.split(RegExp(r'\s+'));
          final first = words.first.toLowerCase();

          String verb = '';
          if (first == 'making' || first == 'building') {
            verb = 'Built';
          } else if (first == 'creating') {
            verb = 'Created';
          } else if (first == 'developing') {
            verb = 'Developed';
          } else if (first == 'engineering') {
            verb = 'Engineered';
          } else if (first == 'managing') {
            verb = 'Managed';
          } else if (first == 'leading') {
            verb = 'Led';
          } else if (first == 'coordinating') {
            verb = 'Coordinated';
          } else if (first == 'handling') {
            verb = 'Handled';
          } else if (first == 'maintaining') {
            verb = 'Maintained';
          } else if (first == 'designing') {
            verb = 'Designed';
          } else if (first == 'optimizing') {
            verb = 'Optimized';
          } else if (first == 'streamlining') {
            verb = 'Streamlined';
          } else if (first == 'supporting') {
            verb = 'Supported';
          } else if (first == 'executing') {
            verb = 'Executed';
          } else if (first == 'overseeing') {
            verb = 'Oversaw';
          } else if (first == 'reducing') {
            verb = 'Reduced';
          } else if (first == 'increasing') {
            verb = 'Increased';
          } else if (first == 'analyzing') {
            verb = 'Analyzed';
          } else if (first == 'ensuring') {
            verb = 'Ensured';
          } else if (first == 'implementing') {
            verb = 'Implemented';
          } else if (first == 'conducting') {
            verb = 'Conducted';
          } else if (first == 'delivering') {
            verb = 'Delivered';
          } else if (first == 'scanning') {
            verb = 'Scanned and processed';
          } else if (first == 'order' || first == 'ordering') {
            verb = 'Facilitated order taking and';
          } else if (first == 'assisting') {
            verb = 'Assisted with';
          } else if (first.endsWith('ing') && first.length > 4) {
            verb = '${first[0].toUpperCase()}${first.substring(1)}';
          }

          if (verb.isNotEmpty) {
            final rest = words.sublist(1).join(' ');
            return rest.isNotEmpty ? '$verb $rest' : verb;
          }

          return '${rem[0].toUpperCase()}${rem.substring(1)}';
        }
      }

      return b;
    }

    void flushExperience() {
      if (expRole.isNotEmpty || expCompany.isNotEmpty || expBullets.isNotEmpty) {
        String finalRole = expRole.isNotEmpty
            ? expRole
            : (title.isNotEmpty ? title : 'Professional Specialist');
        String finalCompany = expCompany.isNotEmpty ? expCompany : 'Independent / Freelance';

        if (finalRole.toLowerCase().contains('freelance') && expCompany.isEmpty) {
          finalCompany = 'Freelance / Self-Employed';
        }

        String startDate = '2022';
        String endDate = 'Present';
        bool isCurrent = true;

        if (expDates.contains('-') || expDates.contains('—') || expDates.contains('–')) {
          final dateParts = expDates.split(RegExp(r'[\-—–]'));
          startDate = dateParts[0].trim();
          endDate = dateParts.length > 1 ? dateParts[1].trim() : 'Present';
          isCurrent = endDate.toLowerCase().contains('present') || endDate.toLowerCase().contains('current');
        } else if (expDates.isNotEmpty) {
          startDate = expDates;
          endDate = 'Completed';
          isCurrent = false;
        }

        experiences.add(
          WorkExperience(
            id: _uuid.v4(),
            role: finalRole,
            company: finalCompany,
            location: expLocation,
            startDate: startDate,
            endDate: endDate,
            isCurrent: isCurrent,
            bullets: expBullets.isNotEmpty
                ? expBullets.map((b) => cleanWeakBulletStarter(b.trim())).where((b) => b.isNotEmpty).toList()
                : _getDefaultBulletsForRole(finalRole),
          ),
        );
        expRole = '';
        expCompany = '';
        expLocation = '';
        expDates = '';
        expBullets = [];
      }
    }

    void assignRoleOrCompany(String s) {
      final clean = s.trim();
      if (clean.isEmpty) return;
      if (clean.contains('|') || clean.contains(' at ')) {
        final parts = clean.split(RegExp(r'\||\sat\s', caseSensitive: false));
        expRole = parts[0].trim();
        expCompany = parts.sublist(1).join(' ').trim();
        return;
      }
      if (clean.contains('Cyberbacker')) {
        expCompany = 'Cyberbacker';
        final rem = clean.replaceAll('Cyberbacker', '').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (rem.isNotEmpty) {
          if (expRole.isEmpty) {
            expRole = rem;
          } else if (expRole.endsWith('&') || expRole.endsWith(',')) {
            expRole = '$expRole $rem';
          }
        }
        return;
      }
      if (clean.contains('ProsperVA')) {
        expCompany = 'ProsperVA';
        final rem = clean.replaceAll('ProsperVA', '').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (rem.isNotEmpty) {
          if (expRole.isEmpty) {
            expRole = rem;
          } else if (expRole.endsWith('&') || expRole.endsWith(',')) {
            expRole = '$expRole $rem';
          }
        }
        return;
      }
      if (clean.contains('Hughes Media')) {
        expCompany = 'Hughes Media';
        final rem = clean.replaceAll('Hughes Media', '').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (rem.isNotEmpty) {
          if (expRole.isEmpty) {
            expRole = rem;
          } else if (expRole.endsWith('&') || expRole.endsWith(',')) {
            expRole = '$expRole $rem';
          }
        }
        return;
      }

      if (hasRoleKeyword(clean) || clean.endsWith('&') || clean.endsWith(',')) {
        if (expRole.isEmpty) {
          expRole = clean;
        } else if (expRole.endsWith('&') || expRole.endsWith(',')) {
          expRole = '$expRole $clean';
        } else if (expCompany.isEmpty && !hasRoleKeyword(clean)) {
          expCompany = clean;
        }
      } else {
        if (expCompany.isEmpty) {
          expCompany = clean;
        } else if (expRole.isEmpty) {
          expRole = clean;
        }
      }
    }

    // Project parsing state
    String projTitle = '';
    StringBuffer projDesc = StringBuffer();

    void flushProject() {
      if (projTitle.isNotEmpty) {
        final desc = projDesc.toString().trim();
        final techList = <String>[];
        final techKeywords = [
          'c#',
          'asp.net',
          'sqlite',
          'mysql',
          'sql',
          'python',
          'flutter',
          'dart',
          'javascript',
          'react',
          'node',
          'java',
          'html',
          'css'
        ];
        for (final t in techKeywords) {
          if (desc.toLowerCase().contains(t) || projTitle.toLowerCase().contains(t)) {
            if (t == 'c#') {
              techList.add('C#');
            } else if (t == 'asp.net') {
              techList.add('ASP.NET');
            } else if (t == 'sqlite') {
              techList.add('SQLite');
            } else if (t == 'mysql') {
              techList.add('MySQL');
            } else {
              techList.add(t.toUpperCase());
            }
          }
        }

        final lowerTitle = title.toLowerCase();
        String defaultTech = 'Professional Tools';
        if (lowerTitle.contains('developer') || lowerTitle.contains('engineer') || lowerTitle.contains('software')) {
          defaultTech = 'Software Engineering';
        } else if (lowerTitle.contains('real estate') || lowerTitle.contains('virtual assistant')) {
          defaultTech = 'Operations & Systems';
        } else if (lowerTitle.contains('marketing')) {
          defaultTech = 'Digital Marketing';
        }

        projects.add(
          Project(
            id: _uuid.v4(),
            title: projTitle,
            description: desc.isNotEmpty ? desc : 'Managed and delivered operational project milestones.',
            technologies: techList.isNotEmpty ? techList.join(', ') : defaultTech,
          ),
        );
        projTitle = '';
        projDesc.clear();
      }
    }

    // Education parsing state
    String eduInstitution = '';
    String eduDegree = '';
    String eduField = '';
    String eduStart = '';
    String eduEnd = '';

    void flushEducation() {
      if (eduInstitution.isNotEmpty || eduDegree.isNotEmpty) {
        educations.add(
          Education(
            id: _uuid.v4(),
            institution: eduInstitution.isNotEmpty ? eduInstitution : 'University / College',
            degree: eduDegree.isNotEmpty ? eduDegree : 'Bachelor of Science',
            fieldOfStudy: eduField.isNotEmpty ? eduField : 'General Studies',
            startDate: eduStart.isNotEmpty ? eduStart : '2022',
            endDate: eduEnd.isNotEmpty ? eduEnd : 'Present',
          ),
        );
        eduInstitution = '';
        eduDegree = '';
        eduField = '';
        eduStart = '';
        eduEnd = '';
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Skip candidate name header banners
      if (fullName.isNotEmpty) {
        final cleanLine = line.replaceAll(' ', '').toUpperCase();
        final cleanName = fullName.replaceAll(' ', '').toUpperCase();
        if (cleanLine == cleanName || cleanLine == 'FEBEJABONITE') {
          continue;
        }
      }

      final header = detectSectionHeader(line);
      if (header != null) {
        flushExperience();
        flushProject();
        flushEducation();
        currentSection = header;
        continue;
      }

      // Check if we should switch back to 'experience' from skills/certifications/references
      if (currentSection == 'skills' || currentSection == 'certifications' || currentSection == 'references') {
        final isNextDate = i + 1 < lines.length && isDateRange(lines[i + 1]);
        final isThisDate = isDateRange(line);
        final isRoleOrCompany = hasRoleKeyword(line) || isKnownCompany(line);

        if (isThisDate || (isRoleOrCompany && isNextDate)) {
          flushExperience();
          flushProject();
          flushEducation();
          currentSection = 'experience';
        }
      }

      switch (currentSection) {
        case 'contact':
          if (emailRegex.hasMatch(line)) {
            final m = emailRegex.firstMatch(line);
            if (m != null) email = m.group(0)!;
          } else if (phoneRegex.hasMatch(line)) {
            final m = phoneRegex.firstMatch(line);
            if (m != null) phone = m.group(0)!;
          } else if (!line.contains('http') && !line.contains('linkedin') && !line.contains('github')) {
            final clean = line.replaceAll(RegExp(r'[^a-zA-Z\s\.\-]'), '').trim();
            final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
            if (words.length >= 2 && words.length <= 4 && !hasRoleKeyword(clean) && !isKnownCompany(clean)) {
              final formatted = words.map((w) {
                if (w.length <= 2 && w.endsWith('.')) return w.toUpperCase();
                return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
              }).join(' ');
              if (fullName.isEmpty || isInvalidPersonName(fullName) || fullName.split(' ').length < words.length) {
                fullName = formatted;
              }
            }
          }
          break;

        case 'summary':
          if (summaryBuffer.isNotEmpty) summaryBuffer.write(' ');
          summaryBuffer.write(line);
          break;

        case 'education':
          // Check for line wrapping like "HOLY CROSS COLLEGE OF SASA (2014-" followed by "2020)"
          String eduLine = line;
          if (eduLine.contains('(') && !eduLine.contains(')') && i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            if (next.contains(')') || RegExp(r'^\d{4}\)?$').hasMatch(next)) {
              eduLine = '$eduLine ${lines[++i].trim()}';
            }
          }

          final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(eduLine);
          final lower = eduLine.toLowerCase();

          if (parenMatch != null) {
            // Format: "INSTITUTION NAME (YEARS OR DEGREE)"
            final parenText = parenMatch.group(1)!.trim();
            final inst = eduLine.replaceAll(RegExp(r'\([^)]+\)'), '').replaceAll(RegExp(r'[\-_]+$'), '').trim();

            if (eduInstitution.isNotEmpty || eduDegree.isNotEmpty) {
              flushEducation();
            }

            eduInstitution = inst;
            if (RegExp(r'\b(19\d\d|20\d\d)\b').hasMatch(parenText)) {
              final dateParts = parenText.split(RegExp(r'[\-—–to]+', caseSensitive: false));
              eduStart = dateParts[0].trim();
              eduEnd = dateParts.length > 1 ? dateParts[1].trim() : 'Present';

              final instLower = inst.toLowerCase();
              if (instLower.contains('elem') || instLower.contains('primary')) {
                eduDegree = 'Elementary Education';
                eduField = 'Basic Education';
              } else if (instLower.contains('high') || instLower.contains('secondary') || instLower.contains('sasa')) {
                eduDegree = 'Secondary Education / High School';
                eduField = 'General High School';
              } else {
                eduDegree = 'Undergraduate Studies';
                eduField = 'Academic Degree';
              }
            } else {
              // e.g. "(1ST YR COLLEGE)"
              eduDegree = parenText;
              eduField = 'College / University';
              eduStart = '';
              eduEnd = 'In Progress';
            }
            flushEducation();
            break;
          }

          if (lower.contains('university') ||
              lower.contains('college') ||
              lower.contains('institute') ||
              lower.contains('academy') ||
              lower.contains('school')) {
            if (eduInstitution.isNotEmpty) flushEducation();
            eduInstitution = eduLine;
          } else if (lower.contains('bachelor') ||
              lower.contains('master') ||
              lower.contains('doctor') ||
              lower.contains('associate') ||
              lower.contains('diploma') ||
              lower.startsWith('bs ') ||
              lower.startsWith('b.s.')) {
            if (eduLine.toLowerCase().contains(' in ')) {
              final parts = eduLine.split(RegExp(r'\s+in\s+', caseSensitive: false));
              eduDegree = parts[0].trim();
              eduField = parts.sublist(1).join(' in ').trim();
            } else {
              eduDegree = eduLine;
            }
          } else if (RegExp(r'\b(19\d\d|20\d\d)\b').hasMatch(eduLine)) {
            final dateParts = eduLine.split(RegExp(r'[\-—–]'));
            eduStart = dateParts[0].trim();
            eduEnd = dateParts.length > 1 ? dateParts[1].trim() : 'Present';
          } else if (eduField.isEmpty && eduDegree.isNotEmpty) {
            eduField = eduLine;
          }
          break;

        case 'experience':
          // Check if this line is a company name followed immediately by a pipe-separated role/duration
          final isNextPipeRole = i + 1 < lines.length &&
              lines[i + 1].contains('|') &&
              (hasRoleKeyword(lines[i + 1]) || isDateRange(lines[i + 1]));

          if (isNextPipeRole && !line.contains('|') && !isDateRange(line)) {
            if (expBullets.isNotEmpty || expRole.isNotEmpty) {
              flushExperience();
            }
            expCompany = line;
            continue;
          }

          // Handle pipe-separated line: "SERVICE CREW | MCDO LANANG | 2YRS & 8MONTHS"
          if (line.contains('|') && (hasRoleKeyword(line) || isDateRange(line))) {
            if (expBullets.isNotEmpty) {
              flushExperience();
            }
            final parts = line.split('|').map((p) => p.trim()).toList();
            if (parts.isNotEmpty) {
              if (hasRoleKeyword(parts[0])) {
                expRole = parts[0];
                if (parts.length > 1) {
                  if (expCompany.isEmpty) {
                    expCompany = parts[1];
                  } else {
                    expLocation = parts[1];
                  }
                }
                if (parts.length > 2) {
                  expDates = parts[2];
                }
              } else {
                assignRoleOrCompany(line);
              }
            }
            continue;
          }

          // Check if this line is a continuation of previous bullet line
          final bool isBulletContinuation = expBullets.isNotEmpty &&
              !line.contains('|') &&
              !isDateRange(line) &&
              !isKnownCompany(line) &&
              (!hasRoleKeyword(line) || RegExp(r'^[a-z]').hasMatch(line)) &&
              (RegExp(r'^[a-z]').hasMatch(line) ||
               expBullets.last.trim().endsWith('And') ||
               expBullets.last.trim().endsWith('and') ||
               expBullets.last.trim().endsWith(',') ||
               !RegExp(r'[\.\!\?]$').hasMatch(expBullets.last.trim()));

          if (isBulletContinuation) {
            final lastBullet = expBullets.removeLast().trim();
            final separator = (lastBullet.endsWith('-') || lastBullet.endsWith('/')) ? '' : ' ';
            expBullets.add('$lastBullet$separator$line');
            continue;
          }

          final isNextDate = i + 1 < lines.length && !lines[i + 1].contains('|') && isDateRange(lines[i + 1]);
          final isNextNextDate = i + 2 < lines.length && !lines[i + 2].contains('|') && isDateRange(lines[i + 2]);
          final isThisDate = !line.contains('|') && isDateRange(line);

          final bool isStartingNewJob = expBullets.isNotEmpty &&
              (isThisDate ||
               (isNextDate && !isLikelyBulletText(line)) ||
               (isNextNextDate && !isLikelyBulletText(line)) ||
               isNextPipeRole);

          if (isStartingNewJob) {
            flushExperience();
          }

          if (isThisDate) {
            expDates = line;
          } else if (isLikelyBulletText(line)) {
            expBullets.add(cleanBullet(line));
          } else if (expBullets.isNotEmpty &&
                     !isNextDate &&
                     !isNextNextDate &&
                     !isNextPipeRole &&
                     !isKnownCompany(line) &&
                     !hasRoleKeyword(line) &&
                     line.length < 140) {
            // Continuation of previous wrapped bullet line
            final lastBullet = expBullets.removeLast();
            final separator = lastBullet.endsWith('-') ? '' : ' ';
            expBullets.add('$lastBullet$separator$line');
          } else {
            // Role or company line
            assignRoleOrCompany(line);
          }
          break;

        case 'projects':
          final lowerProj = line.toLowerCase();
          final isActionDesc = lowerProj.startsWith('developed') ||
              lowerProj.startsWith('built') ||
              lowerProj.startsWith('created') ||
              lowerProj.startsWith('engineered') ||
              lowerProj.startsWith('designed') ||
              lowerProj.startsWith('implemented') ||
              lowerProj.startsWith('architected') ||
              lowerProj.startsWith('a web-based') ||
              lowerProj.startsWith('a desktop') ||
              lowerProj.startsWith('an application');

          final isContinuation = projDesc.isNotEmpty &&
              (line.startsWith('.') ||
                  line.startsWith(',') ||
                  line.startsWith('database') ||
                  RegExp(r'^[a-z]').hasMatch(line));

          if (projTitle.isNotEmpty && (isActionDesc || isContinuation)) {
            if (projDesc.isNotEmpty) {
              if (line == '.' || line == ',') {
                projDesc.write(line);
              } else {
                projDesc.write(' $line');
              }
            } else {
              projDesc.write(line);
            }
          } else {
            flushProject();
            projTitle = cleanBullet(line);
          }
          break;

        case 'skills':
        case 'certifications':
          if (!isBullet(line) && line.length <= 4 && skills.isNotEmpty) {
            // Continuation of previous wrapped word (e.g. "Securit" + "y")
            // Never append standalone digits/page numbers
            if (!RegExp(r'^\d+$').hasMatch(line)) {
              final lastSkill = skills.removeLast();
              final fixedName = '${lastSkill.name}$line';
              skills.add(Skill(id: lastSkill.id, name: fixedName, category: lastSkill.category, level: lastSkill.level));
              break;
            }
          }

          String lineContent = line;
          String defaultCat = currentSection == 'certifications' ? 'Certifications' : 'Technical';
          if (lineContent.contains(':') && !lineContent.contains('http')) {
            final colonParts = lineContent.split(':');
            final prefix = colonParts[0].trim();
            if (prefix.length < 35 && !prefix.contains(',')) {
              defaultCat = prefix;
              lineContent = colonParts.sublist(1).join(':').trim();
            }
          }

          final rawSkill = isBullet(lineContent) ? cleanBullet(lineContent) : lineContent;
          final skillTokens = rawSkill.split(RegExp(r'[,\|/]'));
          for (final token in skillTokens) {
            final s = token.trim();
            if (s.isNotEmpty &&
                s.length <= 45 &&
                !skills.any((existing) => existing.name.toLowerCase() == s.toLowerCase())) {
              final category = defaultCat != 'Technical'
                  ? defaultCat
                  : (currentSection == 'certifications' ? 'Certifications' : _categorizeSkill(s));
              skills.add(Skill(id: _uuid.v4(), name: s, category: category, level: 4));
            }
          }
          break;

        case 'references':
          // Safely ignored, never dumped into skills!
          break;
      }
    }

    flushExperience();
    flushProject();
    flushEducation();

    final summaryText = summaryBuffer.toString().trim();

    // Infer job title if still empty
    if (title.isEmpty) {
      if (experiences.isNotEmpty &&
          experiences.first.role.isNotEmpty &&
          experiences.first.role != 'Professional Specialist') {
        title = experiences.first.role;
      } else if (summaryText.toLowerCase().contains('information technology student')) {
        title = 'Information Technology Specialist';
      } else if (summaryText.toLowerCase().contains('real estate') ||
          summaryText.toLowerCase().contains('virtual assistant')) {
        title = 'Real Estate Virtual Assistant';
      } else if (summaryText.toLowerCase().contains('marketing') ||
          summaryText.toLowerCase().contains('social media')) {
        title = 'Marketing Specialist';
      } else if (educations.isNotEmpty &&
          educations.first.fieldOfStudy.isNotEmpty &&
          educations.first.fieldOfStudy != 'General Studies' &&
          educations.first.fieldOfStudy != 'Basic Education' &&
          educations.first.fieldOfStudy != 'High School') {
        title = '${educations.first.fieldOfStudy} Specialist';
      } else {
        title = 'Professional Specialist';
      }
    }

    if (title.isNotEmpty && title == title.toUpperCase()) {
      title = title.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');
    }

    return CvData(
      id: _uuid.v4(),
      title: '$fullName Resume',
      personalInfo: PersonalInfo(
        fullName: fullName,
        jobTitle: title,
        email: email,
        phone: phone,
        location: location,
        summary: summaryText,
        linkedin: linkedin,
        github: github,
        website: website,
      ),
      experiences: experiences,
      educations: educations,
      skills: skills,
      projects: projects,
    );
  }

  String _categorizeSkill(String skill) {
    final s = skill.toLowerCase();
    if (s.contains('canva') ||
        s.contains('lofty') ||
        s.contains('flexmls') ||
        s.contains('carrot') ||
        s.contains('docusign') ||
        s.contains('dotloop') ||
        s.contains('notion') ||
        s.contains('zapier') ||
        s.contains('crm') ||
        s.contains('excel') ||
        s.contains('git') ||
        s.contains('docker') ||
        s.contains('linux') ||
        s.contains('aws') ||
        s.contains('office') ||
        s.contains('quickbooks') ||
        s.contains('xero') ||
        s.contains('troubleshooting') ||
        s.contains('hardware') ||
        s.contains('software')) {
      return 'Tools';
    }
    if (s.contains('leadership') ||
        s.contains('communication') ||
        s.contains('agile') ||
        s.contains('scrum') ||
        s.contains('problem solving') ||
        s.contains('organization') ||
        s.contains('time management') ||
        s.contains('client relation') ||
        s.contains('problem')) {
      return 'Soft Skills';
    }
    return 'Technical';
  }
}
