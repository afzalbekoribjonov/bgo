import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Admin yuborgan xabar (haydovchi faqat o'qiydi, javob yozolmaydi).
class DriverMessage {
  final String id;
  final String? driverUserId; // null = hammaga (e'lon)
  final String? title;
  final String body;
  final DateTime createdAt;

  const DriverMessage({
    required this.id,
    required this.driverUserId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  /// Shaxsan shu haydovchiga yuborilganmi (aks holda umumiy e'lon).
  bool get personal => driverUserId != null;

  factory DriverMessage.fromJson(Map<String, dynamic> j) => DriverMessage(
        id: j['id'] as String,
        driverUserId: j['driverUserId'] as String?,
        title: j['title'] as String?,
        body: (j['body'] as String?) ?? '',
        createdAt:
            DateTime.tryParse((j['createdAt'] as String?) ?? '')?.toLocal() ??
                DateTime.now(),
      );
}

/// Xabarlar ro'yxati + oxirgi o'qilgan payt ("yangi" belgisi shundan).
class DriverInbox {
  final List<DriverMessage> messages; // yangi birinchi (serverdan)
  final DateTime? readAt;
  const DriverInbox({required this.messages, required this.readAt});
}

class MessagesApi {
  final Dio _dio;
  MessagesApi(this._dio);

  Future<DriverInbox> list() async {
    final res = await _dio.get('/auth/driver/messages');
    final data = res.data['data'] as Map<String, dynamic>;
    final list = (data['messages'] as List?) ?? const [];
    return DriverInbox(
      messages: list
          .map((e) => DriverMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      readAt: DateTime.tryParse((data['readAt'] as String?) ?? '')?.toLocal(),
    );
  }

  Future<int> unreadCount() async {
    final res = await _dio.get('/auth/driver/messages/unread-count');
    return (res.data['data']?['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead() async {
    await _dio.post('/auth/driver/messages/read');
  }
}

final messagesApiProvider =
    Provider<MessagesApi>((ref) => MessagesApi(ref.read(dioProvider)));

/// O'qilmagan xabarlar soni — qo'ng'iroqcha badge (bosh ekran taymeri
/// invalidate qilib turadi).
final unreadMessagesProvider = FutureProvider<int>(
  (ref) => ref.read(messagesApiProvider).unreadCount(),
);
