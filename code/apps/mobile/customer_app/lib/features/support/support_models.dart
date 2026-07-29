// Yordam (AI qo'llab-quvvatlash) modellari — services/support javobiga mos.

class SupportFaqItem {
  final String id;
  final String label;

  const SupportFaqItem({required this.id, required this.label});

  factory SupportFaqItem.fromJson(Map<String, dynamic> json) => SupportFaqItem(
        id: json['id'] as String,
        label: (json['label'] as String?) ?? '',
      );
}

/// topic == 'ai' — erkin AI suhbati; aks holda FAQ savoli id'si.
class SupportConversation {
  final String id;
  final String topic;
  final String? topicLabel;
  final String status; // OPEN | ESCALATED | RESOLVED
  final String createdAt;
  final String updatedAt;

  const SupportConversation({
    required this.id,
    required this.topic,
    this.topicLabel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAiChat => topic == 'ai';
  bool get isEscalated => status == 'ESCALATED';

  factory SupportConversation.fromJson(Map<String, dynamic> json) => SupportConversation(
        id: json['id'] as String,
        topic: (json['topic'] as String?) ?? 'ai',
        topicLabel: json['topicLabel'] as String?,
        status: (json['status'] as String?) ?? 'OPEN',
        createdAt: (json['createdAt'] as String?) ?? '',
        updatedAt: (json['updatedAt'] as String?) ?? '',
      );
}

/// senderRole: USER | BOT | AI | ADMIN | SYSTEM.
class SupportMessage {
  final String id;
  final String senderRole;
  final String text;
  final String createdAt;

  const SupportMessage({
    required this.id,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id'] as String,
        senderRole: (json['senderRole'] as String?) ?? 'USER',
        text: (json['text'] as String?) ?? '',
        createdAt: (json['createdAt'] as String?) ?? '',
      );
}
