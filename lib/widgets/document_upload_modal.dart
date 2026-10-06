import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cv_data.dart';
import '../services/document_parser_service.dart';
import '../viewmodels/cv_viewmodel.dart';
import '../viewmodels/ai_agent_viewmodel.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../views/cv_editor_screen.dart';
import 'app_logo.dart';
import 'score_badge.dart';

class DocumentUploadModal extends StatefulWidget {
  final bool openEditorOnSuccess;

  const DocumentUploadModal({
    super.key,
    this.openEditorOnSuccess = true,
  });

  static Future<void> show(BuildContext context, {bool openEditorOnSuccess = true}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentUploadModal(openEditorOnSuccess: openEditorOnSuccess),
    );
  }

  @override
  State<DocumentUploadModal> createState() => _DocumentUploadModalState();
}

class _DocumentUploadModalState extends State<DocumentUploadModal> with SingleTickerProviderStateMixin {
  final DocumentParserService _parserService = DocumentParserService();
  final TextEditingController _pasteController = TextEditingController();

  late TabController _tabController;
  bool _isProcessing = false;
  String _processingStep = '';
  CvData? _parsedCv;
  String? _sourceFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _handleFileUpload() async {
    setState(() {
      _isProcessing = true;
      _processingStep = 'Opening document picker...';
    });

    try {
      final docResult = await _parserService.pickAndExtractDocument();
      if (docResult == null) {
        setState(() => _isProcessing = false);
        return;
      }

      _processExtractedDocument(docResult);
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cleanMsg), duration: const Duration(seconds: 4)),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handlePastedText() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste resume text first')),
      );
      return;
    }

    _processRawText(text, 'Pasted Document');
  }

  Future<void> _processRawText(String text, String sourceName) async {
    setState(() {
      _isProcessing = true;
      _sourceFileName = sourceName;
      _processingStep = 'Extracting resume details and milestones...';
    });

    final aiVm = Provider.of<AiAgentViewModel>(context, listen: false);
    final activeKey = aiVm.apiKey ?? StorageService.getSystemApiKey();
    final bool useAi = activeKey != null && activeKey.trim().length >= 20;

    try {
      final parsed = await aiVm.agentService.parseAndArrangeDocument(
        rawText: text,
        fileName: sourceName,
        apiKey: activeKey,
        isDemoMode: !useAi,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _parsedCv = parsed;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing document: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processExtractedDocument(DocumentParseResult docResult) async {
    final aiVm = Provider.of<AiAgentViewModel>(context, listen: false);
    final activeKey = aiVm.apiKey ?? StorageService.getSystemApiKey();
    final bool hasValidKey = activeKey != null && activeKey.trim().length >= 20;

    // 1. If selectable text was found, parse it
    if (docResult.rawText.trim().isNotEmpty) {
      _processRawText(docResult.rawText, docResult.fileName);
      return;
    }

    // 2. If no text was found (flattened image PDF) and Gemini Vision is available, run Vision OCR
    if (hasValidKey && docResult.rawBytes != null) {
      setState(() {
        _isProcessing = true;
        _sourceFileName = docResult.fileName;
        _processingStep = 'Running Multimodal AI Vision OCR on scanned document...';
      });

      try {
        final parsed = await aiVm.agentService.parseDocumentWithVision(
          bytes: docResult.rawBytes!,
          apiKey: activeKey,
          mimeType: docResult.extension == 'pdf' ? 'application/pdf' : 'image/png',
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
            _parsedCv = parsed;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showFlattenedPdfDialog(docResult.fileName);
        }
      }
      return;
    }

    // 3. Offline / No API Key: show helpful guidance and 1-tap switch to paste tab
    if (mounted) {
      setState(() => _isProcessing = false);
      _showFlattenedPdfDialog(docResult.fileName);
    }
  }

  void _showFlattenedPdfDialog(String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Flattened Image PDF', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$fileName" is an image-only PDF (commonly caused by Canva\'s "Flatten PDF" option) and contains no selectable text.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'How to import:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text('• Switch to "Paste Text" tab to paste your resume text directly.', style: TextStyle(fontSize: 12)),
            const Text('• In Canva, re-download as "PDF Standard" with "Flatten PDF" unchecked.', style: TextStyle(fontSize: 12)),
            const Text('• Select a document with text (e.g. DOCX or text-enabled PDF).', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.paste_rounded, size: 16),
            label: const Text('Switch to Paste Text'),
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  void _applyToActive(BuildContext context, CvViewModel cvVm) async {
    if (_parsedCv == null) return;
    final parsed = _parsedCv!;
    await cvVm.importCvFromDocument(parsed, saveAsNew: false);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume populated and updated successfully!')),
    );
    if (widget.openEditorOnSuccess) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CvEditorScreen()),
      );
    }
  }

  void _saveAsNew(BuildContext context, CvViewModel cvVm) async {
    if (_parsedCv == null) return;
    final parsed = _parsedCv!;
    await cvVm.importCvFromDocument(parsed, saveAsNew: true);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved as new resume profile!')),
    );
    if (widget.openEditorOnSuccess) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CvEditorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cvVm = Provider.of<CvViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const AppLogo(size: 32, borderRadius: 8),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload & Arrange Resume',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'AI parses PDF or text and optimizes structure',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              if (_isProcessing) ...[
                _buildProcessingState(isDark),
              ] else if (_parsedCv != null) ...[
                _buildPreviewState(context, cvVm, isDark),
              ] else ...[
                _buildInputState(isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputState(bool isDark) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file_outlined), text: 'Upload Document'),
            Tab(icon: Icon(Icons.paste_outlined), text: 'Paste Text'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Upload Document
              InkWell(
                onTap: _handleFileUpload,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tap to Select PDF or Document',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Supports PDF, DOCX, TXT, Markdown, JSON',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        children: ['PDF', 'TXT', 'DOCX', 'MD']
                            .map(
                              (ext) => Chip(
                                label: Text(ext, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab 2: Paste Raw Text
              Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pasteController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Paste your raw resume text, bullet points, or LinkedIn summary here...',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Analyze & Arrange with AI'),
                      onPressed: _handlePastedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            _processingStep,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'The AI agent is categorizing milestones, extracting skills, and quantifying achievements.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState(BuildContext context, CvViewModel cvVm, bool isDark) {
    final cv = _parsedCv!;
    final p = cv.personalInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Successfully Arranged from ${_sourceFileName ?? "Document"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                    ),
                    const Text(
                      'Sections organized and ready to review',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Preview Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          Text(
                            p.fullName.isNotEmpty ? p.fullName : 'Candidate Profile',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            p.jobTitle.isNotEmpty ? p.jobTitle : 'Professional Specialist',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ScoreBadge(score: cv.completenessScore, size: 48),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (p.email.isNotEmpty)
                      _previewChip(Icons.email_outlined, p.email),
                    if (p.phone.isNotEmpty)
                      _previewChip(Icons.phone_outlined, p.phone),
                    if (p.location.isNotEmpty)
                      _previewChip(Icons.location_on_outlined, p.location),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Experience', '${cv.experiences.length} roles'),
                    _metricCol('Education', '${cv.educations.length} records'),
                    _metricCol('Skills', '${cv.skills.length} skills'),
                    _metricCol('Projects', '${cv.projects.length} projects'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => _saveAsNew(context, cvVm),
                child: Text(widget.openEditorOnSuccess ? 'Save New & Open' : 'Save as New Resume'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.edit_document, size: 18),
                label: Text(widget.openEditorOnSuccess ? 'Apply & Open in Editor' : 'Apply to Active Resume'),
                onPressed: () => _applyToActive(context, cvVm),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _previewChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _metricCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
