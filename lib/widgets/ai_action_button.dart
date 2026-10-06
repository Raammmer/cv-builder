import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ai_agent_viewmodel.dart';
import '../utils/constants.dart';

class AiActionButton extends StatefulWidget {
  final String textToEnhance;
  final String? roleTitle;
  final String? company;
  final Function(String enhancedText) onApply;
  final String label;

  const AiActionButton({
    super.key,
    required this.textToEnhance,
    this.roleTitle,
    this.company,
    required this.onApply,
    this.label = 'AI Polish',
  });

  @override
  State<AiActionButton> createState() => _AiActionButtonState();
}

class _AiActionButtonState extends State<AiActionButton> {
  bool _isLoading = false;

  void _triggerEnhancement(BuildContext context) async {
    if (widget.textToEnhance.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text before requesting AI enhancement.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final agent = context.read<AiAgentViewModel>();

    try {
      final result = await agent.enhanceBullet(
        rawBullet: widget.textToEnhance,
        role: widget.roleTitle,
        company: widget.company,
      );

      if (!mounted || !context.mounted) return;
      setState(() => _isLoading = false);

      // Show bottom sheet with Agent reasoning and 1-click apply
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final replacement = result.toolAction?.data['replacement'] as String? ?? '';
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Agent Enhancement',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Polished for clarity and domain impact',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Original Version:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.textToEnhance, style: const TextStyle(fontSize: 13)),
                ),
                const Text('AI Agent Suggestion:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    replacement.isNotEmpty ? replacement : result.text,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                ),
                if (result.reasoning != null) ...[
                  ExpansionTile(
                    title: const Text('View Agent Reasoning Trace', style: TextStyle(fontSize: 12)),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          result.reasoning!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Keep Original'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Apply to CV'),
                        onPressed: () {
                          widget.onApply(replacement.isNotEmpty ? replacement : result.text);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Applied AI enhancement to your CV!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(Icons.auto_awesome, size: 14),
      label: Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      onPressed: () => _triggerEnhancement(context),
    );
  }
}
