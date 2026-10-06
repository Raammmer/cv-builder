import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_agent_message.dart';
import '../models/skill.dart';
import '../services/ai_agent_service.dart';
import '../services/storage_service.dart';
import 'cv_viewmodel.dart';

/// ViewModel responsible for AI Agent interactions, reasoning states, and tool executions.
/// Follows MVVM architecture: View -> ViewModel -> Service / Model
class AiAgentViewModel extends ChangeNotifier {
  final AiAgentService _agentService = AiAgentService();
  final StorageService _storageService = StorageService();
  final _uuid = const Uuid();

  final List<AiAgentMessage> _messages = [];
  bool _isProcessing = false;
  String? _apiKey = StorageService.getSystemApiKey();
  bool _isDemoMode = false;

  Map<String, dynamic>? _atsAnalysis;
  bool _isAtsLoading = false;

  // Getters exposed to the View
  AiAgentService get agentService => _agentService;
  List<AiAgentMessage> get messages => _messages;
  bool get isProcessing => _isProcessing;
  String? get apiKey {
    if (_apiKey != null && _apiKey!.trim().isNotEmpty) return _apiKey;
    return StorageService.getSystemApiKey();
  }
  bool get hasApiKey => apiKey != null && apiKey!.trim().length >= 20;
  bool get isDemoMode => _isDemoMode && !hasApiKey;
  Map<String, dynamic>? get atsAnalysis => _atsAnalysis;
  bool get isAtsLoading => _isAtsLoading;

  AiAgentViewModel() {
    _init();
  }

  Future<void> _init() async {
    _apiKey = (await _storageService.getApiKey()) ?? StorageService.getSystemApiKey();
    _isDemoMode = await _storageService.isDemoAiMode();

    if (_messages.isEmpty) {
      _messages.add(
        AiAgentMessage(
          id: _uuid.v4(),
          sender: AgentSender.agent,
          text: 'Hello! I am your **CVBuilder AI Copilot**.\n\n'
              'I can help you build an ATS-optimized resume, enhance weak bullet points using the Google XYZ formula, '
              'and tailor your profile to any job description.\n\n'
              'Try asking: *"Enhance my summary"* or *"Review my resume"*!',
          timestamp: DateTime.now(),
          reasoning: 'MVVM Agent initialization: Welcoming user and presenting agent competencies.',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> setApiKey(String key) async {
    final clean = key.trim();
    await _storageService.saveApiKey(clean);
    _apiKey = await _storageService.getApiKey();
    if (clean.isNotEmpty) {
      _isDemoMode = false;
      await _storageService.setDemoAiMode(false);
    }
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await _storageService.clearApiKey();
    _apiKey = await _storageService.getApiKey();
    _isDemoMode = await _storageService.isDemoAiMode();
    notifyListeners();
  }

  Future<bool> hasCustomApiKey() => _storageService.hasCustomApiKey();

  Future<void> toggleDemoMode(bool value) async {
    _isDemoMode = value;
    await _storageService.setDemoAiMode(value);
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    _apiKey ??= await _storageService.getApiKey();
    _isDemoMode = await _storageService.isDemoAiMode();
  }

  /// Sends a conversational prompt from the View to the AI Agent
  Future<void> sendMessage(String text, CvViewModel cvViewModel) async {
    if (text.trim().isEmpty) return;
    await _ensureLoaded();

    final userMsg = AiAgentMessage(
      id: _uuid.v4(),
      sender: AgentSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isProcessing = true;
    notifyListeners();

    try {
      final agentReply = await _agentService.processChatMessage(
        userMessage: text,
        cv: cvViewModel.activeCv,
        apiKey: _apiKey,
        isDemoMode: _isDemoMode,
      );
      _messages.add(agentReply);
    } catch (e) {
      _messages.add(
        AiAgentMessage(
          id: _uuid.v4(),
          sender: AgentSender.agent,
          text: 'Encountered an issue processing that request: ${e.toString()}',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Direct bullet point enhancement invoked from UI buttons
  Future<AiAgentMessage> enhanceBullet({
    required String rawBullet,
    String? role,
    String? company,
  }) async {
    await _ensureLoaded();
    return await _agentService.enhanceBulletPoint(
      rawBullet: rawBullet,
      roleTitle: role,
      company: company,
      apiKey: _apiKey,
      isDemoMode: _isDemoMode,
    );
  }

  /// Direct summary generation action
  Future<void> generateSummaryAction(CvViewModel cvViewModel) async {
    await _ensureLoaded();
    _isProcessing = true;
    notifyListeners();

    try {
      final msg = await _agentService.generateSummary(
        cv: cvViewModel.activeCv,
        apiKey: _apiKey,
        isDemoMode: _isDemoMode,
      );
      _messages.add(msg);
    } catch (e) {
      _messages.add(
        AiAgentMessage(
          id: _uuid.v4(),
          sender: AgentSender.agent,
          text: 'Failed to generate summary: $e',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// ATS Job match analysis
  Future<void> runAtsAnalysis(String jobDescription, CvViewModel cvViewModel) async {
    if (jobDescription.trim().isEmpty) return;
    await _ensureLoaded();
    _isAtsLoading = true;
    notifyListeners();

    try {
      _atsAnalysis = await _agentService.analyzeAtsMatch(
        cv: cvViewModel.activeCv,
        jobDescription: jobDescription,
        apiKey: _apiKey,
        isDemoMode: _isDemoMode,
      );
    } catch (e) {
      _atsAnalysis = {
        'score': 50,
        'matchedKeywords': <String>[],
        'missingKeywords': <String>['ERROR: Could not parse JD'],
        'recommendations': ['Please check your internet connection or API settings.'],
        'reasoning': 'Error during processing.',
      };
    } finally {
      _isAtsLoading = false;
      notifyListeners();
    }
  }

  /// Executes an Agent Tool Action that mutates the active CV state in CvViewModel
  void applyToolAction(AgentToolAction action, CvViewModel cvViewModel, String messageId) {
    switch (action.actionType) {
      case 'update_summary':
        final summary = action.data['summary'] as String? ?? '';
        if (summary.isNotEmpty) {
          cvViewModel.updateSummary(summary);
        }
        break;

      case 'add_skill':
        final name = action.data['name'] as String? ?? '';
        final category = action.data['category'] as String? ?? 'Technical';
        final level = (action.data['level'] as num?)?.toInt() ?? 4;
        if (name.isNotEmpty) {
          cvViewModel.addSkill(
            Skill(id: _uuid.v4(), name: name, category: category, level: level),
          );
        }
        break;

      case 'replace_bullet':
        final original = action.data['original'] as String? ?? '';
        final replacement = action.data['replacement'] as String? ?? '';
        for (final exp in cvViewModel.activeCv.experiences) {
          final idx = exp.bullets.indexOf(original);
          if (idx >= 0) {
            cvViewModel.updateBullet(exp.id, idx, replacement);
            break;
          }
        }
        break;
    }

    if (messageId.isNotEmpty) {
      final msgIndex = _messages.indexWhere((m) => m.id == messageId);
      if (msgIndex >= 0) {
        _messages[msgIndex].isApplied = true;
      }
    }
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _init();
  }
}
