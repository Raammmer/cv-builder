import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cv_data.dart';
import '../viewmodels/cv_viewmodel.dart';
import '../services/pdf_export_service.dart';
import '../utils/constants.dart';
import '../widgets/templates/modern_template.dart';
import '../widgets/templates/executive_template.dart';
import '../widgets/templates/minimalist_template.dart';
import '../widgets/templates/creative_template.dart';
import '../widgets/templates/classic_template.dart';

class CvPreviewScreen extends StatefulWidget {
  const CvPreviewScreen({super.key});

  @override
  State<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends State<CvPreviewScreen> {
  bool _isGeneratingPdf = false;

  void _downloadPdf(CvData cv) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfExportService.shareOrSavePdf(cv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('PDF ready! Choose "Save to device" or your file manager to save to your phone.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _printPdf(CvData cv) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfExportService.printPdf(cv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open print preview: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _promptSaveAsNew(CvViewModel cvVm, CvData activeCv) {
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
              'Create a new copy of this resume with a new title.',
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
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvViewModel>();
    final cv = cvProvider.activeCv;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Preview & Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Duplicate in App',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _promptSaveAsNew(cvProvider, cv),
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print_outlined),
            onPressed: _isGeneratingPdf ? null : () => _printPdf(cv),
          ),
          IconButton(
            tooltip: 'Download PDF to Phone',
            icon: _isGeneratingPdf
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_rounded, color: AppColors.primary),
            onPressed: _isGeneratingPdf ? null : () => _downloadPdf(cv),
          ),
        ],
      ),
      body: Column(
        children: [
          // Template & Color Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Template Selector
                Row(
                  children: [
                    const Text('Template: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: TemplateInfo.templates.map((tmpl) {
                            final isSelected = cv.selectedTemplate == tmpl.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(tmpl.icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(tmpl.title, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected ? FontWeight.bold : null,
                                ),
                                onSelected: (_) => cvProvider.setTemplate(tmpl.id),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Color Palette
                Row(
                  children: [
                    const Text('Accent: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: AppColors.paletteOptions.map((opt) {
                            final int hex = opt['hex'] as int;
                            final isSelected = cv.accentColorHex == hex;
                            return GestureDetector(
                              onTap: () => cvProvider.setAccentColor(hex),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: opt['color'] as Color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.black87 : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Resume Canvas (A4 Aspect Ratio Sheet)
          Expanded(
            child: Container(
              color: const Color(0xFFF1F5F9),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: ThemeData.light(),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                        ),
                        child: _buildTemplateView(cv),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
              ),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                icon: const Icon(Icons.print_rounded, size: 20),
                label: const Text('Print'),
                onPressed: _isGeneratingPdf ? null : () => _printPdf(cv),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    _isGeneratingPdf ? 'Generating PDF...' : 'Download PDF to Phone',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _isGeneratingPdf ? null : () => _downloadPdf(cv),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateView(CvData cv) {
    switch (cv.selectedTemplate) {
      case 'executive':
        return ExecutiveTemplateView(cv: cv);
      case 'minimalist':
        return MinimalistTemplateView(cv: cv);
      case 'creative':
        return CreativeTemplateView(cv: cv);
      case 'classic':
        return ClassicTemplateView(cv: cv);
      case 'modern':
      default:
        return ModernTemplateView(cv: cv);
    }
  }
}
