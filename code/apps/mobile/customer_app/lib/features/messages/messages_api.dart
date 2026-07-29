import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Admin yuborgan xabar (mijoz faqat o'qiydi, javob yozolmaydi).
class CustomerMessage {
  final String id;
  final String? customerId; // null = hammaga (e'lon)
  final String? title;
  final String body;
  final DateTime createdAt;

  const CustomerMessage({
    required this.id,
    required this.customerId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  /// Shaxsan shu mijozga yuborilganmi (aks holda umumiy e'lon).
  bool get personal => customerId != null;

  factory CustomerMessage.fromJson(Map<String, dynamic> j) => CustomerMessage(
        id: j['id'] as String,
        customerId: j['customerId'] as String?,
        title: j['title'] as String?,
        body: (j['body'] as String?) ?? '',
        createdAt:
            DateTime.tryParse((j['createdAt'] as String?) ?? '')?.toLocal() ??
                DateTime.now(),
      );
}

/// Xabarlar ro'yxati + oxirgi o'qilgan payt ("yangi" belgisi shundan).
class CustomerInbox {
  final List<CustomerMessage> messages; // yangi birinchi (serverdan)
  final DateTime? readAt;
  const CustomerInbox({required this.messages, required this.readAt});
}

class MessagesApi {
  final Dio _dio;
  MessagesApi(this._dio);

  Future<CustomerInbox> list() async {
    final res = await _dio.get('/profile/messages');
    final data = res.data['data'] as Map<String, dynamic>;
    final list = (data['messages'] as List?) ?? const [];
    return CustomerInbox(
      messages: list
          .map((e) => CustomerMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      readAt: DateTime.tryParse((data['readAt'] as String?) ?? '')?.toLocal(),
    );
  }

  Future<int> unreadCount() async {
    final res = await _dio.get('/profile/messages/unread-count');
    return (res.data['data']?['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead() async {
    await _dio.post('/profile/messages/read');
  }
}

final messagesApiProvider =
    Provider<MessagesApi>((ref) => MessagesApi(ref.read(dioProvider)));

/// O'qilmagan xabarlar soni — profil tilidagi badge.
final unreadMessagesProvider = FutureProvider<int>(
  (ref) => ref.read(messagesApiProvider).unreadCount(),
);
