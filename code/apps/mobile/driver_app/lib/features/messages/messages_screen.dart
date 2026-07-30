import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/driver_colors.dart';
import '../../widgets/async_error.dart';
import 'messages_api.dart';

const _gold = DriverColors.gold;

/// Xabarlar — admin yuborgan e'lonlar/xabarlar (faqat o'qish, chat ko'rinishida).
/// Ochilganda hammasi o'qilgan deb belgilanadi (badge tozalanadi).
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  DriverInbox? _inbox;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final inbox = await ref.read(messagesApiProvider).list();
      if (!mounted) return;
      setState(() {
        _inbox = inbox;
        _loading = false;
        _error = false;
      });
      // Ochildi — o'qilgan deb belgilash (badge yo'qoladi). readAt esa eski
      // qiymatida qoladi, shu tufayli "Yangi" chiplar shu kirishda ko'rinadi.
      await ref.read(messagesApiProvider).markRead();
      if (!mounted) return;
      ref.invalidate(unreadMessagesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _inbox == null;
      });
      if (!isNetworkError(e)) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(t.msgTitle),
        actions: [
          IconButton(
            tooltip: t.msgRefresh,
            onPressed: () {
              setState(() => _loading = _inbox == null);
              _load();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? _errorState()
              : (_inbox == null || _inbox!.messages.isEmpty)
                  ? _emptyState(scheme, t)
                  : _list(scheme, t),
    );
  }

  Widget _errorState() {
    return AsyncErrorRetry(
      error: DioException.connectionError(
          requestOptions: RequestOptions(), reason: 'offline'),
      onRetry: () {
        setState(() => _loading = true);
        _load();
      },
    );
  }

  Widget _emptyState(ColorScheme scheme, AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded,
                size: 42, color: scheme.outline),
          ),
          const SizedBox(height: 16),
          Text(t.msgEmptyTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.msgEmptySubtitle,
              style: TextStyle(fontSize: 13, color: scheme.outline)),
        ],
      ),
    );
  }

  Widget _list(ColorScheme scheme, AppLocalizations t) {
    // Serverdan yangi birinchi keladi — chatda eski tepada bo'lsin.
    final msgs = _inbox!.messages.reversed.toList();
    final readAt = _inbox!.readAt;

    final items = <Widget>[];
    DateTime? lastDay;
    for (final m in msgs) {
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (lastDay == null || day != lastDay) {
        items.add(_daySeparator(day, scheme, t));
        lastDay = day;
      }
      final isNew = readAt == null || m.createdAt.isAfter(readAt);
      items.add(_bubble(m, isNew, scheme, t));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: items,
      ),
    );
  }

  Widget _daySeparator(DateTime day, ColorScheme scheme, AppLocalizations t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    final label = diff == 0
        ? t.dayToday
        : diff == 1
            ? t.dayYesterday
            : '${day.day.toString().padLeft(2, '0')}.'
                '${day.month.toString().padLeft(2, '0')}.${day.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.6))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant)),
          ),
          Expanded(
              child: Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _bubble(
      DriverMessage m, bool isNew, ColorScheme scheme, AppLocalizations t) {
    final personal = m.personal;
    final accent = personal ? _gold : const Color(0xFF546E7A);
    final time =
        '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuboruvchi belgisi: e'lon (karnay) yoki shaxsiy (yulduzcha).
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, Color.lerp(accent, Colors.black, 0.25)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(
              personal ? Icons.star_rounded : Icons.campaign_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // Xabar pufagi
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: personal
                    ? Border.all(color: _gold.withValues(alpha: 0.55), width: 1.2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Yorliq qatori: E'lon / Sizga + Yangi
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          personal ? t.msgToYou : t.msgAnnouncement,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: accent),
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(t.msgNewBadge,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD32F2F))),
                        ),
                      ],
                    ],
                  ),
                  if ((m.title ?? '').isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(m.title!,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w800)),
                  ],
                  const SizedBox(height: 5),
                  Text(m.body,
                      style: const TextStyle(fontSize: 14, height: 1.38)),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(time,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: scheme.outline,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
