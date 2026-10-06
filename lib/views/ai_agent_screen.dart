import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_agent_message.dart';
import '../viewmodels/ai_agent_viewmodel.dart';
import '../viewmodels/cv_viewmodel.dart';
import '../utils/constants.dart';
import '../widgets/score_badge.dart';
import 'settings_screen.dart';

class AiAgentScreen extends StatefulWidget {
  const AiAgentScreen({super.key});

  @override
  State<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends State<AiAgentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatCtrl = TextEditingController();
  final _jdCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatCtrl.dispose();
    _jdCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    final cvProvider = context.read<CvViewModel>();
    context.read<AiAgentViewModel>().sendMessage(text, cvProvider);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = context.watch<AiAgentViewModel>();
    final cvProvider = context.watch<CvViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'AI Career Copilot',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: agentProvider.isDemoMode
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: agentProvider.isDemoMode
                          ? Colors.amber.shade700
                          : Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    agentProvider.isDemoMode ? 'Offline' : 'Gemini AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: agentProvider.isDemoMode
                          ? Colors.amber.shade900
                          : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Agent Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Career Copilot Chat'),
            Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'ATS Job Matcher'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(agentProvider, cvProvider),
          _buildAtsTab(agentProvider, cvProvider),
        ],
      ),
    );
  }

  // --- TAB 1: Conversational Career Copilot ---
  Widget _buildChatTab(AiAgentViewModel agent, CvViewModel cv) {
    return Column(
      children: [
        // Suggested Quick Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Theme.of(context).cardColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _promptChip('✨ Enhance my summary', () {
                  _chatCtrl.text = 'Enhance my summary';
                  _sendMessage();
                }),
                _promptChip('📊 Review my resume', () {
                  _chatCtrl.text = 'Review my resume';
                  _sendMessage();
                }),
                _promptChip('💡 Recommend skills & roles', () {
                  _chatCtrl.text = 'Recommend skills, projects, and target roles for my profile';
                  _sendMessage();
                }),
                _promptChip('🎯 Action verbs advice', () {
                  _chatCtrl.text = 'Suggest strong, natural action verbs for my experience bullets';
                  _sendMessage();
                }),
              ],
            ),
          ),
        ),

        // Message List
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: agent.messages.length + (agent.isProcessing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == agent.messages.length) {
                return _buildThinkingBubble();
              }
              final msg = agent.messages[index];
              return _buildMessageItem(msg, agent, cv);
            },
          ),
        ),

        // Quick Suggestion Chips
        Container(
          height: 38,
          margin: const EdgeInsets.only(bottom: 6),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildSuggestionChip('💡 Suggest Improvements', 'Suggest improvements for my resume', agent, cv),
              const SizedBox(width: 8),
              _buildSuggestionChip('✨ Enhance Summary', 'Enhance my summary', agent, cv),
              const SizedBox(width: 8),
              _buildSuggestionChip('📊 Audit Resume Score', 'Review my resume', agent, cv),
              const SizedBox(width: 8),
              _buildSuggestionChip('🎯 Target Job Roles', 'What target jobs match my skills and background?', agent, cv),
              const SizedBox(width: 8),
              _buildSuggestionChip('🛠️ Project Ideas', 'Suggest portfolio project ideas for me', agent, cv),
            ],
          ),
        ),

        // Chat Input Box
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask the agent to rewrite, suggest, review, or add details...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: agent.isProcessing ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String label, String prompt, AiAgentViewModel agent, CvViewModel cv) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: Theme.of(context).cardColor,
      side: const BorderSide(color: Color(0xFFCBD5E1)),
      onPressed: agent.isProcessing
          ? null
          : () {
              agent.sendMessage(prompt, cv);
              _scrollToBottom();
            },
    );
  }

  Widget _buildMessageItem(AiAgentMessage msg, AiAgentViewModel agent, CvViewModel cv) {
    final isUser = msg.sender == AgentSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: isUser ? Colors.white : null,
                        ),
                      ),
                      if (msg.reasoning != null) ...[
                        const SizedBox(height: 8),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Icon(Icons.psychology_rounded, size: 14, color: isUser ? Colors.white70 : AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Agent Reasoning Trace',
                                  style: TextStyle(fontSize: 11, color: isUser ? Colors.white70 : AppColors.primary),
                                ),
                              ],
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  msg.reasoning!,
                                  style: TextStyle(fontSize: 11, color: isUser ? Colors.white70 : Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Structured Tool Action Card (e.g. "Apply to CV" button)
          if (msg.toolAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 8),
              child: Card(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tool: ${msg.toolAction!.description}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: msg.isApplied ? Colors.green : AppColors.primary,
                        ),
                        onPressed: msg.isApplied
                            ? null
                            : () {
                                agent.applyToolAction(msg.toolAction!, cv, msg.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Updated your resume successfully!')),
                                );
                              },
                        child: Text(msg.isApplied ? 'Applied ✓' : 'Apply to CV', style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Agent reasoning...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _promptChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
        onPressed: onTap,
      ),
    );
  }

  // --- TAB 2: ATS Match & Job Tailor ---
  Widget _buildAtsTab(AiAgentViewModel agent, CvViewModel cv) {
    final ats = agent.atsAnalysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paste Job Description (JD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'The AI Agent will scan the requirements, calculate an ATS match score, and detect missing technical skills.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _jdCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Paste the job posting requirements here (e.g. "Looking for a Flutter developer with Docker, REST API, CI/CD experience...")...',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: agent.isAtsLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.analytics_outlined),
              label: Text(agent.isAtsLoading ? 'Scanning Job Posting...' : 'Analyze ATS Compatibility'),
              onPressed: agent.isAtsLoading
                  ? null
                  : () {
                      agent.runAtsAnalysis(_jdCtrl.text, cv);
                    },
            ),
          ),
          const SizedBox(height: 24),

          // ATS Results Display
          if (ats != null) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ScoreBadge(score: ats['score'] as int, label: 'ATS Match Score'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ((ats['score'] as int) >= 75 ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (ats['score'] as int) >= 75 ? 'Strong Match' : 'Moderate Match',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (ats['score'] as int) >= 75 ? Colors.green.shade800 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Matched Keywords
                    const Text('Matched Keywords in your CV:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (ats['matchedKeywords'] as List<dynamic>)
                          .map((kw) => Chip(
                                label: Text(kw.toString(), style: const TextStyle(fontSize: 11, color: Colors.green)),
                                backgroundColor: Colors.green.withValues(alpha: 0.1),
                                avatar: const Icon(Icons.check, size: 14, color: Colors.green),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // Missing Keywords
                    const Text('Missing Keywords (Recommended to add):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (ats['missingKeywords'] as List<dynamic>)
                          .map((kw) => ActionChip(
                                label: Text('+ $kw', style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                                onPressed: () {
                                  context.read<AiAgentViewModel>().applyToolAction(
                                    AgentToolAction(
                                      actionType: 'add_skill',
                                      description: 'Add skill $kw',
                                      data: {'name': kw.toString(), 'category': 'Technical'},
                                    ),
                                    cv,
                                    '',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added $kw to your skills!')),
                                  );
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // Recommendations
                    const Text('Agent Actionable Recommendations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...(ats['recommendations'] as List<dynamic>).map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('👉 ', style: TextStyle(fontSize: 12)),
                            Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 12, height: 1.4))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
