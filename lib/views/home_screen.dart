import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cv_viewmodel.dart';
import '../utils/constants.dart';
import '../widgets/score_badge.dart';
import '../widgets/app_logo.dart';
import '../widgets/document_upload_modal.dart';
import 'cv_editor_screen.dart';
import 'cv_preview_screen.dart';
import 'ai_agent_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cvViewModel = context.watch<CvViewModel>();
    final activeCv = cvViewModel.activeCv;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(size: 32, borderRadius: 8),
            SizedBox(width: 10),
            Text(
              'CVBuilder',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Upload / Review Document',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: () => DocumentUploadModal.show(context),
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
            tooltip: 'Settings & API Key',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: cvViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Active Resume Card
                  _buildActiveResumeCard(context, cvViewModel, activeCv, isDark),
                  const SizedBox(height: 16),

                  // Upload & Arrange Document Card
                  _buildUploadDocumentBanner(context),
                  const SizedBox(height: 16),

                  // Quick AI Actions Banner
                  _buildAiBanner(context),
                  const SizedBox(height: 24),

                  // Saved Resumes Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Resumes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Import from PDF',
                            icon: const Icon(Icons.upload_file_outlined, size: 20),
                            onPressed: () => DocumentUploadModal.show(context),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Resume'),
                            onPressed: () {
                              _showCreateDialog(context, cvViewModel);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (cvViewModel.savedCvs.isEmpty)
                    _buildEmptyState(context, cvViewModel)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cvViewModel.savedCvs.length,
                      itemBuilder: (context, index) {
                        final cv = cvViewModel.savedCvs[index];
                        final isSelected = cv.id == activeCv.id;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            onTap: () {
                              cvViewModel.setActiveCv(cv);
                            },
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Color(cv.accentColorHex).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.article_rounded,
                                color: Color(cv.accentColorHex),
                                size: 22,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cv.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${cv.personalInfo.fullName.isNotEmpty ? cv.personalInfo.fullName : "No Name"} • Score: ${cv.completenessScore}%',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  tooltip: 'Edit Resume',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  onPressed: () {
                                    cvViewModel.setActiveCv(cv);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CvEditorScreen()),
                                    );
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  tooltip: 'More Actions',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  onSelected: (action) {
                                    switch (action) {
                                      case 'preview':
                                        cvViewModel.setActiveCv(cv);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CvPreviewScreen()),
                                        );
                                        break;
                                      case 'duplicate':
                                        _promptDuplicateCv(context, cvViewModel, cv);
                                        break;
                                      case 'delete':
                                        _confirmDelete(context, cvViewModel, cv.id);
                                        break;
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'preview',
                                      child: Row(
                                        children: [
                                          Icon(Icons.remove_red_eye_outlined, size: 18),
                                          SizedBox(width: 10),
                                          Text('Preview / PDF', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'duplicate',
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy_rounded, size: 18),
                                          SizedBox(width: 10),
                                          Text('Save as New File', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    if (cvViewModel.savedCvs.length > 1) ...[
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                            SizedBox(width: 10),
                                            Text(
                                              'Delete Resume',
                                              style: TextStyle(fontSize: 13, color: Colors.redAccent),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('Preview / PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1.5,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CvPreviewScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Edit Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CvEditorScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveResumeCard(
      BuildContext context, CvViewModel viewModel, dynamic activeCv, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Active Profile badge on left, ScoreBadge & optional profile options on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ACTIVE PROFILE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScoreBadge(
                    score: activeCv.completenessScore,
                    label: 'Strength',
                    size: 40,
                  ),
                  if (viewModel.savedCvs.length > 1) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Profile Options',
                      onSelected: (action) {
                        if (action == 'delete') {
                          _confirmDelete(context, viewModel, activeCv.id);
                        } else if (action == 'duplicate') {
                          _promptDuplicateCv(context, viewModel, activeCv);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Duplicate Profile', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Delete Profile', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Resume Title (Full width spread)
          Text(
            activeCv.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Candidate Name & Full Professional Headline (Full width spread across the card)
          if (activeCv.personalInfo.fullName.isNotEmpty || activeCv.personalInfo.jobTitle.isNotEmpty) ...[
            Text(
              activeCv.personalInfo.fullName.isNotEmpty
                  ? activeCv.personalInfo.fullName
                  : 'Unnamed Profile',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (activeCv.personalInfo.jobTitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                activeCv.personalInfo.jobTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ] else ...[
            Text(
              'Personal details not filled yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Details'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CvEditorScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Save as New File (Duplicate)',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () => _promptDuplicateCv(context, viewModel, activeCv),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('AI Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiAgentScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadDocumentBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F766E).withValues(alpha: 0.18),
            const Color(0xFF0284C7).withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.upload_file_rounded, color: Color(0xFF14B8A6), size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload & Arrange Resume',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'Upload PDF or paste text to auto-structure details.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => DocumentUploadModal.show(context),
            child: const Text('Import CV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Career Copilot',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Refine bullets, evaluate job match & boost ATS score.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF312E81),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiAgentScreen()),
            ),
            child: const Text('Open Copilot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CvViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.post_add_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No Resumes Saved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Start by loading a pre-filled sample or creating your own.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('Load Sample Tech Resume'),
              onPressed: () {
                viewModel.loadSampleResume();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CvEditorScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Blank Resume'),
              onPressed: () {
                viewModel.createNewCv(title: 'My Resume');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CvEditorScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, CvViewModel viewModel) {
    final textCtrl = TextEditingController(text: 'My Resume');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New Resume'),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Resume Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Create & Open Resume'),
            onPressed: () {
              final title = textCtrl.text.trim().isNotEmpty ? textCtrl.text.trim() : 'My Resume';
              viewModel.createNewCv(title: title);
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CvEditorScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _promptDuplicateCv(BuildContext context, CvViewModel viewModel, dynamic cv) {
    final textCtrl = TextEditingController(
      text: cv.title.endsWith('(Copy)') ? '${cv.title} 2' : '${cv.title} (Copy)',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.copy_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Duplicate Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a new resume copy from "${cv.title}".', style: const TextStyle(fontSize: 13)),
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
            label: const Text('Create Copy'),
            onPressed: () async {
              final title = textCtrl.text.trim().isNotEmpty
                  ? textCtrl.text.trim()
                  : '${cv.title} (Copy)';
              Navigator.pop(ctx);
              await viewModel.duplicateCv(cv.id, newTitle: title);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created new file: "$title"'),
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

  void _confirmDelete(BuildContext context, CvViewModel viewModel, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume?'),
        content: const Text('Are you sure you want to delete this resume? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              viewModel.deleteCv(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
