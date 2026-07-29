import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'support_models.dart';

/// Yordam (AI qo'llab-quvvatlash) API'si — gateway orqali, Bearer token.
/// Rol (mijoz/haydovchi) serverda tokendan aniqlanadi — klient hech narsa
/// yubormaydi.
class SupportApi {
  final Dio _dio;
  SupportApi(this._dio);

  Future<List<SupportFaqItem>> faq() async {
    final res = await _dio.get('/support/faq');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => SupportFaqItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SupportConversation>> listConversations() async {
    final res = await _dio.get('/support/conversations');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => SupportConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [topic] — FaqItem.id yoki 'ai' (erkin suhbat).
  Future<(SupportConversation, List<SupportMessage>)> createConversation(
      String topic) async {
    final res =
        await _dio.post('/support/conversations', data: {'topic': topic});
    final data = res.data['data'] as Map<String, dynamic>;
    final conv = SupportConversation.fromJson(
        data['conversation'] as Map<String, dynamic>);
    final msgs = ((data['messages'] as List?) ?? const [])
        .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return (conv, msgs);
  }

  Future<List<SupportMessage>> messages(String id) async {
    final res = await _dio.get('/support/conversations/$id/messages');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Muvaffaqiyatli bo'lsa haydovchi xabari + (agar bo'lsa) AI/SYSTEM javobi
  /// darhol qaytadi — keyingi poll siklini kutish shart emas.
  Future<List<SupportMessage>> sendMessage(String id, String text) async {
    final res = await _dio
        .post('/support/conversations/$id/messages', data: {'text': text});
    final data = res.data['data'] as Map<String, dynamic>;
    final msgs = <SupportMessage>[];
    if (data['userMessage'] != null) {
      msgs.add(
          SupportMessage.fromJson(data['userMessage'] as Map<String, dynamic>));
    }
    if (data['aiMessage'] != null) {
      msgs.add(
          SupportMessage.fromJson(data['aiMessage'] as Map<String, dynamic>));
    }
    return msgs;
  }
}

final supportApiProvider =
    Provider<SupportApi>((ref) => SupportApi(ref.read(dioProvider)));

final supportFaqProvider = FutureProvider<List<SupportFaqItem>>((ref) {
  ref.watch(localeProvider);
  return ref.read(supportApiProvider).faq();
});

final myConversationsProvider =
    FutureProvider<List<SupportConversation>>((ref) {
  return ref.read(supportApiProvider).listConversations();
});
