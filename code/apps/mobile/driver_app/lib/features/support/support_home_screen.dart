import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'support_api.dart';
import 'support_chat_screen.dart';
import 'support_models.dart';

const Color _supportBrand = Color(0xFF2E7D32);

/// Yordam bo'limi bosh ekrani — o'tgan murojaatlar tarixi + yangi murojaat.
class SupportHomeScreen extends ConsumerWidget {
  const SupportHomeScreen({super.key});

  void _openNew(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SupportChatScreen()));
  }

  void _openExisting(
      BuildContext context, AppLocalizations t, SupportConversation c) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SupportChatScreen(
        conversationId: c.id,
        initialTitle: c.isAiChat ? t.supportAiTopic : (c.topicLabel ?? ''),
      ),
    ));
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final time =
        '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
    if (day == today) return time;
    if (day == today.subtract(const Duration(days: 1))) return 'Kecha, $time';
    return '${d.day.toString().padLeft(2, "0")}.${d.month.toString().padLeft(2, "0")}.${d.year} $time';
  }

  (String, Color) _statusChip(AppLocalizations t, String status) {
    switch (status) {
      case 'ESCALATED':
        return (t.supportStatusEscalated, const Color(0xFFEF6C00));
      case 'RESOLVED':
        return (t.supportStatusResolved, const Color(0xFF2E7D32));
      default:
        return (t.supportStatusOpen, _supportBrand);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(myConversationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.supportTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myConversationsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AsyncErrorRetry(
            error: e,
            scrollable: true,
            onRetry: () => ref.invalidate(myConversationsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return LayoutBuilder(
                builder: (_, c) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: c.maxHeight,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: _supportBrand.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.support_agent_rounded,
                                  size: 40,
                                  color: _supportBrand.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 16),
                            Text(t.supportHistoryEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(t.supportHistoryEmptySub,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, color: scheme.outline)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = items[i];
                final (statusLabel, statusColor) = _statusChip(t, c.status);
                return Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openExisting(context, t, c),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _supportBrand.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              c.isAiChat
                                  ? Icons.smart_toy_rounded
                                  : Icons.quiz_rounded,
                              size: 20,
                              color: _supportBrand,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.isAiChat
                                      ? t.supportAiTopic
                                      : (c.topicLabel ?? ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDate(c.updatedAt),
                                  style: TextStyle(
                                      fontSize: 12, color: scheme.outline),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SupportPrimaryButton(
            label: t.supportNewRequest,
            icon: Icons.add_comment_rounded,
            onPressed: () => _openNew(context),
          ),
        ),
      ),
    );
  }
}
