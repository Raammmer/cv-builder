import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/project.dart';
import '../viewmodels/cv_viewmodel.dart';
import '../utils/constants.dart';
import '../widgets/ai_action_button.dart';
import '../widgets/section_card.dart';
import '../widgets/document_upload_modal.dart';
import 'cv_preview_screen.dart';
import 'ai_agent_screen.dart';

class CvEditorScreen extends StatefulWidget {
  const CvEditorScreen({super.key});

  @override
  State<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends State<CvEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  // Personal info controllers
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();

  String? _lastLoadedCvId;
  DateTime? _lastLoadedTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _populateControllers();
  }

  void _populateControllers() {
    final cv = context.read<CvViewModel>().activeCv;
    _lastLoadedCvId = cv.id;
    _lastLoadedTime = cv.lastModified;
    final p = cv.personalInfo;
    _nameCtrl.text = p.fullName;
    _titleCtrl.text = p.jobTitle;
    _emailCtrl.text = p.email;
    _phoneCtrl.text = p.phone;
    _locationCtrl.text = p.location;
    _websiteCtrl.text = p.website;
    _linkedinCtrl.text = p.linkedin;
    _githubCtrl.text = p.github;
    _summaryCtrl.text = p.summary;
    if (mounted) {
      setState(() {});
    }
  }

  void _syncPersonalInfo() {
    final provider = context.read<CvViewModel>();
    final current = provider.activeCv.personalInfo;
    final updated = current.copyWith(
      fullName: _nameCtrl.text.trim(),
      jobTitle: _titleCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      linkedin: _linkedinCtrl.text.trim(),
      github: _githubCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
    );
    provider.updatePersonalInfo(updated);
  }

  void _promptSaveAsNew() {
    _syncPersonalInfo();
    final cvVm = context.read<CvViewModel>();
    final activeCv = cvVm.activeCv;
    final textCtrl = TextEditingController(
      text: activeCv.title.endsWith('(Copy)')
          ? '${activeCv.title} 2'
          : '${activeCv.title} (Copy)',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.copy_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Save as New File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a duplicate copy of this resume under a new title without changing the original.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Resume Title',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Save as New'),
            onPressed: () async {
              final newTitle = textCtrl.text.trim().isNotEmpty
                  ? textCtrl.text.trim()
                  : '${activeCv.title} (Copy)';
              Navigator.pop(ctx);
              await cvVm.saveAsNewCv(newTitle: newTitle);
              if (mounted) {
                _populateControllers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved as new file: "$newTitle"'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvViewModel>();
    final cv = cvProvider.activeCv;

    if (_lastLoadedCvId != cv.id || _lastLoadedTime != cv.lastModified) {
      _lastLoadedCvId = cv.id;
      _lastLoadedTime = cv.lastModified;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _populateControllers();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cv.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Save as New File (Duplicate)',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _promptSaveAsNew,
          ),
          IconButton(
            tooltip: 'Import from PDF / Document',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: () async {
              await DocumentUploadModal.show(context, openEditorOnSuccess: false);
              if (mounted) {
                _populateControllers();
              }
            },
          ),
          IconButton(
            tooltip: 'AI Career Copilot',
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiAgentScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Live Preview & Export',
            icon: const Icon(Icons.remove_red_eye_rounded),
            onPressed: () {
              _syncPersonalInfo();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CvPreviewScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          splashBorderRadius: BorderRadius.circular(12),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Personal'),
            Tab(icon: Icon(Icons.work_rounded, size: 18), text: 'Experience'),
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Education'),
            Tab(icon: Icon(Icons.psychology_rounded, size: 18), text: 'Skills'),
            Tab(icon: Icon(Icons.folder_special_rounded, size: 18), text: 'Projects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalTab(cvProvider),
          _buildExperienceTab(cvProvider),
          _buildEducationTab(cvProvider),
          _buildSkillsTab(cvProvider),
          _buildProjectsTab(cvProvider),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF111827).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Save as New File (Duplicate)',
                icon: const Icon(Icons.copy_rounded, size: 20),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: _promptSaveAsNew,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Progress'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _syncPersonalInfo();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Resume progress saved!')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('Preview Resume'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _syncPersonalInfo();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CvPreviewScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: Personal Info & Summary ---
  Widget _buildPersonalTab(CvViewModel provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          SectionCard(
            icon: Icons.badge_outlined,
            title: 'Contact Information',
            subtitle: 'How recruiters and ATS systems identify and reach you',
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *', hintText: 'e.g. Alex Morgan'),
                  onChanged: (_) => _syncPersonalInfo(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Professional Title *',
                      hintText: 'e.g. Software Engineer'),
                  onChanged: (_) => _syncPersonalInfo(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Email *', hintText: 'alex@example.com'),
                        onChanged: (_) => _syncPersonalInfo(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Phone', hintText: '+1 (555) 012-3456'),
                        onChanged: (_) => _syncPersonalInfo(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g. San Francisco, CA'),
                  onChanged: (_) => _syncPersonalInfo(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _linkedinCtrl,
                        decoration: const InputDecoration(
                            labelText: 'LinkedIn',
                            hintText: 'linkedin.com/in/username'),
                        onChanged: (_) => _syncPersonalInfo(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _githubCtrl,
                        decoration: const InputDecoration(
                            labelText: 'GitHub',
                            hintText: 'github.com/username'),
                        onChanged: (_) => _syncPersonalInfo(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.format_quote_rounded,
            title: 'Professional Summary',
            subtitle:
                'A high-impact executive summary placed at the top of your CV',
            trailing: AiActionButton(
              textToEnhance: _summaryCtrl.text,
              roleTitle: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : null,
              label: 'AI Generate Summary',
              onApply: (enhanced) {
                setState(() {
                  _summaryCtrl.text = enhanced;
                  _syncPersonalInfo();
                });
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _summaryCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Briefly summarize your experience, top technical expertise, and career impact...',
                  ),
                  onChanged: (_) => _syncPersonalInfo(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tip: Use the AI button above to synthesize your skills into an ATS-friendly summary.',
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Work Experience ---
  Widget _buildExperienceTab(CvViewModel provider) {
    final experiences = provider.activeCv.experiences;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          SectionCard(
            icon: Icons.work_history_rounded,
            title: 'Work Experience',
            subtitle: 'Add full-time, internships, or freelance positions',
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Job'),
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              onPressed: () => _showAddExperienceDialog(context, provider),
            ),
            child: experiences.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                          'No work experience added yet. Tap "Add Job" to start.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: experiences
                        .map((exp) =>
                            _buildExperienceItem(context, provider, exp))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(
      BuildContext context, CvViewModel provider, WorkExperience exp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp.role.isNotEmpty ? exp.role : 'Job Role',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                          '${exp.company} • ${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.redAccent),
                  onPressed: () => provider.deleteExperience(exp.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Achievement Bullets:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            ...exp.bullets.asMap().entries.map((entry) {
              final idx = entry.key;
              final bullet = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bullet, style: const TextStyle(fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AiActionButton(
                          textToEnhance: bullet,
                          roleTitle: exp.role,
                          company: exp.company,
                          label: 'AI Polish Bullet',
                          onApply: (enhanced) {
                            provider.updateBullet(exp.id, idx, enhanced);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: Colors.grey),
                          onPressed: () => provider.deleteBullet(exp.id, idx),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Bullet Point',
                  style: TextStyle(fontSize: 12)),
              onPressed: () => _showAddBulletDialog(context, provider, exp.id),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: Education ---
  Widget _buildEducationTab(CvViewModel provider) {
    final educations = provider.activeCv.educations;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SectionCard(
        icon: Icons.school_rounded,
        title: 'Education',
        subtitle: 'Degrees, universities, GPAs and academic honors',
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Degree'),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          onPressed: () => _showAddEducationDialog(context, provider),
        ),
        child: educations.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('No education history added yet.',
                        style: TextStyle(color: Colors.grey))),
              )
            : Column(
                children: educations
                    .map((edu) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${edu.degree} in ${edu.fieldOfStudy}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                              '${edu.institution} (${edu.startDate} - ${edu.endDate})'
                              '${edu.gradeOrGpa.isNotEmpty ? " • GPA: ${edu.gradeOrGpa}" : ""}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            onPressed: () => provider.deleteEducation(edu.id),
                          ),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  // --- TAB 4: Skills ---
  Widget _buildSkillsTab(CvViewModel provider) {
    final skills = provider.activeCv.skills;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SectionCard(
        icon: Icons.psychology_rounded,
        title: 'Skills & Proficiencies',
        subtitle: 'Add technical frameworks, languages, and soft skills',
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Skill'),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          onPressed: () => _showAddSkillDialog(context, provider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((skill) => Chip(
                        label: Text(skill.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => provider.deleteSkill(skill.id),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text('Suggested High-Demand Tech Keywords:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'Flutter',
                'Dart',
                'Docker',
                'AWS',
                'REST API',
                'GraphQL',
                'CI/CD',
                'Git',
                'Agile'
              ]
                  .where((name) => !skills
                      .any((s) => s.name.toLowerCase() == name.toLowerCase()))
                  .map(
                    (suggested) => ActionChip(
                      label: Text('+ $suggested',
                          style: const TextStyle(fontSize: 11)),
                      onPressed: () => provider.addSkill(
                        Skill(
                            id: _uuid.v4(),
                            name: suggested,
                            category: 'Technical'),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 5: Projects & Certifications ---
  Widget _buildProjectsTab(CvViewModel provider) {
    final projects = provider.activeCv.projects;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          SectionCard(
            icon: Icons.code_rounded,
            title: 'Projects',
            subtitle: 'Portfolio projects, open-source work or apps',
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Project'),
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              onPressed: () => _showAddProjectDialog(context, provider),
            ),
            child: projects.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text('No projects added yet.',
                            style: TextStyle(color: Colors.grey))),
                  )
                : Column(
                    children: projects
                        .map((proj) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(proj.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${proj.technologies}\n${proj.description}'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.redAccent),
                                onPressed: () =>
                                    provider.deleteProject(proj.id),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---
  void _showAddExperienceDialog(BuildContext context, CvViewModel provider) {
    final compCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: 'Jan 2024');
    final endCtrl = TextEditingController(text: 'Present');
    bool isCur = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Work Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: roleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Job Title *')),
                const SizedBox(height: 10),
                TextField(
                    controller: compCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Company / Org *')),
                const SizedBox(height: 10),
                TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: startCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Start Date'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: endCtrl,
                            decoration:
                                const InputDecoration(labelText: 'End Date'),
                            enabled: !isCur)),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currently working here',
                      style: TextStyle(fontSize: 13)),
                  value: isCur,
                  onChanged: (v) => setDlgState(() => isCur = v ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (compCtrl.text.isNotEmpty && roleCtrl.text.isNotEmpty) {
                  provider.addExperience(
                    WorkExperience(
                      id: _uuid.v4(),
                      company: compCtrl.text.trim(),
                      role: roleCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      startDate: startCtrl.text.trim(),
                      endDate: isCur ? 'Present' : endCtrl.text.trim(),
                      isCurrent: isCur,
                      bullets: [
                        'Engineered key features utilizing best development practices.'
                      ],
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add Job'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBulletDialog(
      BuildContext context, CvViewModel provider, String expId) {
    final bulletCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Achievement Bullet'),
        content: TextField(
          controller: bulletCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'e.g. Architected customer portal reducing latency by 35%...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (bulletCtrl.text.trim().isNotEmpty) {
                provider.addBullet(expId, bulletCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Bullet'),
          ),
        ],
      ),
    );
  }

  void _showAddEducationDialog(BuildContext context, CvViewModel provider) {
    final instCtrl = TextEditingController();
    final degCtrl = TextEditingController();
    final fieldCtrl = TextEditingController();
    final gpaCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '2020');
    final endCtrl = TextEditingController(text: '2024');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: instCtrl,
                  decoration: const InputDecoration(
                      labelText: 'University / Institution *')),
              const SizedBox(height: 10),
              TextField(
                  controller: degCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Degree (e.g. Bachelor of Science)')),
              const SizedBox(height: 10),
              TextField(
                  controller: fieldCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Field of Study (e.g. Computer Science)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: startCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Start Year'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: endCtrl,
                          decoration:
                              const InputDecoration(labelText: 'End Year'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: gpaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'GPA / Honors (e.g. 3.8/4.0)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (instCtrl.text.isNotEmpty) {
                provider.addEducation(
                  Education(
                    id: _uuid.v4(),
                    institution: instCtrl.text.trim(),
                    degree: degCtrl.text.trim(),
                    fieldOfStudy: fieldCtrl.text.trim(),
                    startDate: startCtrl.text.trim(),
                    endDate: endCtrl.text.trim(),
                    gradeOrGpa: gpaCtrl.text.trim(),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Degree'),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context, CvViewModel provider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(
          controller: nameCtrl,
          decoration:
              const InputDecoration(labelText: 'Skill or Technology Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.addSkill(
                    Skill(id: _uuid.v4(), name: nameCtrl.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context, CvViewModel provider) {
    final titleCtrl = TextEditingController();
    final techCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Project Title *')),
              const SizedBox(height: 10),
              TextField(
                  controller: techCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Technologies Used')),
              const SizedBox(height: 10),
              TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Description / Impact')),
              const SizedBox(height: 10),
              TextField(
                  controller: linkCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Link / Repository URL')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                provider.addProject(
                  Project(
                    id: _uuid.v4(),
                    title: titleCtrl.text.trim(),
                    technologies: techCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    link: linkCtrl.text.trim(),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Project'),
          ),
        ],
      ),
    );
  }
}
