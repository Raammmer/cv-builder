enum AgentSender { user, agent, system }

class AgentToolAction {
  final String actionType; // 'update_summary', 'replace_bullet', 'add_skill', 'tailor_cv'
  final String description;
  final Map<String, dynamic> data;

  AgentToolAction({
    required this.actionType,
    required this.description,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'description': description,
        'data': data,
      };

  factory AgentToolAction.fromJson(Map<String, dynamic> json) => AgentToolAction(
        actionType: json['actionType'] as String? ?? '',
        description: json['description'] as String? ?? '',
        data: json['data'] as Map<String, dynamic>? ?? {},
      );
}

class AiAgentMessage {
  final String id;
  final AgentSender sender;
  final String text;
  final DateTime timestamp;
  final String? reasoning;
  final AgentToolAction? toolAction;
  bool isApplied;

  AiAgentMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.reasoning,
    this.toolAction,
    this.isApplied = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'reasoning': reasoning,
        'toolAction': toolAction?.toJson(),
        'isApplied': isApplied,
      };

  factory AiAgentMessage.fromJson(Map<String, dynamic> json) => AiAgentMessage(
        id: json['id'] as String? ?? '',
        sender: AgentSender.values.firstWhere(
          (e) => e.name == json['sender'],
          orElse: () => AgentSender.agent,
        ),
        text: json['text'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        reasoning: json['reasoning'] as String?,
        toolAction: json['toolAction'] != null
            ? AgentToolAction.fromJson(json['toolAction'] as Map<String, dynamic>)
            : null,
        isApplied: json['isApplied'] as bool? ?? false,
      );
}
