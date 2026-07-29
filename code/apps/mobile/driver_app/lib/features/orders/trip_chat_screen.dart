import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';

const _green = Color(0xFF2E7D32);

/// Haydovchi ↔ mijoz/oshxona suhbati (haydovchi tomoni). 3s polling.
/// Professional: sana ajratgichlar, quyruqli pufaklar, oflayn banner,
/// birinchi yuklanish xatosida RETRY, aqlli avto-scroll (pastda bo'lsagina).
class TripChatScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String title;
  final String? phone; // suhbatdosh raqami (qo'ng'iroq tugmasi)
  final String vertical; // 'taxi' | 'parcel' | 'food'
  const TripChatScreen(
      {super.key,
      required this.tripId,
      this.title = 'Mijoz',
      this.phone,
      this.vertical = 'taxi'});

  @override
  ConsumerState<TripChatScreen> createState() => _TripChatScreenState();
}

class _ChatMsg {
  final String role; // 'driver' | 'customer' | 'kitchen'
  final String text;
  final DateTime? at;
  _ChatMsg(this.role, this.text, this.at);
}

class _TripChatScreenState extends ConsumerState<TripChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  List<_ChatMsg> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  Object? _initialError; // birinchi yuklanish xatosi (RETRY ekrani)
  int _failStreak = 0; // ketma-ket poll xatolari (oflayn banner)

  /// Suhbat endpointi — ovqat kuryer marshrutida (/courier/orders).
  String get _msgBase => widget.vertical == 'food'
      ? '/courier/orders/${widget.tripId}/messages'
      : '/${widget.vertical}/${widget.tripId}/messages';

  Dio get _dio => ref.read(dioProvider);

  bool get _offline => _failStreak >= 2;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Foydalanuvchi ro'yxat oxiriga yaqinmi — faqat shunda avto-scroll
  /// qilamiz (eski xabarlarni o'qiyotganini buzmaslik uchun).
  bool get _nearBottom {
    if (!_scroll.hasClients) return true;
    return _scroll.position.maxScrollExtent - _scroll.position.pixels < 140;
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final res = await _dio.get(_msgBase);
      final list = (res.data['data'] as List?) ?? const [];
      if (!mounted) return;
      final wasNearBottom = _nearBottom;
      final grew = list.length > _messages.length;
      setState(() {
        _messages = list
            .map((e) => _ChatMsg(
                  (e['senderRole'] as String?) ?? 'customer',
                  (e['text'] as String?) ?? '',
                  DateTime.tryParse((e['createdAt'] as String?) ?? '')
                      ?.toLocal(),
                ))
            .toList();
        _loading = false;
        _initialError = null;
        _failStreak = 0;
      });
      if (grew && (wasNearBottom || initial)) _scrollToEnd(jump: initial);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failStreak++;
        if (initial && _messages.isEmpty) _initialError = e;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _dio.post(_msgBase, data: {'text': text});
      if (!mounted) return;
      _controller.clear();
      await _load();
      if (!mounted) return;
      _scrollToEnd();
    } catch (e) {
      // Matn inputda qoladi — foydalanuvchi qayta yuborishi mumkin.
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        final ended = httpStatus(e) == 400;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isNetworkError(e)
              ? t.tripChatNetworkError
              : (ended ? t.tripChatEnded : t.tripChatSendFailed)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  String _time(DateTime? d) => d == null
      ? ''
      : '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';

  /// Sana yorlig'i: Bugun / Kecha / dd.MM.yyyy.
  String _dayLabel(DateTime d, AppLocalizations t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return t.dayToday;
    if (day == today.subtract(const Duration(days: 1))) return t.dayYesterday;
    return '${d.day.toString().padLeft(2, "0")}.${d.month.toString().padLeft(2, "0")}.${d.year}';
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return true;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  IconData get _otherIcon => widget.vertical == 'food'
      ? Icons.storefront_rounded
      : Icons.person_rounded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_otherIcon, size: 20, color: _green),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(_offline ? t.tripChatConnecting : t.tripChatLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              _offline ? const Color(0xFFEF6C00) : scheme.outline)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if ((widget.phone ?? '').isNotEmpty)
            IconButton(
              tooltip: t.tripChatCallTooltip,
              icon: const Icon(Icons.call_rounded),
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: widget.phone)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Oflayn banner — polling ketma-ket yiqilganda (avto qayta ulanadi).
          if (_offline && _initialError == null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFEF6C00).withValues(alpha: 0.12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFEF6C00)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.tripChatOffline,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB85C00)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _body(scheme, t)),
          _inputBar(scheme, t),
        ],
      ),
    );
  }

  Widget _body(ColorScheme scheme, AppLocalizations t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initialError != null && _messages.isEmpty) {
      return AsyncErrorRetry(
        error: _initialError!,
        onRetry: () {
          setState(() {
            _loading = true;
            _initialError = null;
          });
          _load(initial: true);
        },
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  size: 34, color: _green.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            Text(t.tripChatEmptyTitle,
                style: TextStyle(
                    color: scheme.outline, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(t.tripChatEmptySubtitle,
                style: TextStyle(color: scheme.outline, fontSize: 12.5)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        final prev = i > 0 ? _messages[i - 1] : null;
        final showDay = m.at != null && !_sameDay(prev?.at, m.at);
        return Column(
          children: [
            if (showDay) _daySeparator(m.at!, scheme, t),
            _bubble(m, scheme,
                // Ketma-ket bir tomondan kelganda avatar faqat oxirgisida.
                showAvatar: m.role != 'driver' &&
                    (i == _messages.length - 1 ||
                        _messages[i + 1].role != m.role)),
          ],
        );
      },
    );
  }

  Widget _daySeparator(DateTime d, ColorScheme scheme, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.6))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_dayLabel(d, t),
                style: TextStyle(
                    fontSize: 11,
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

  Widget _bubble(_ChatMsg m, ColorScheme scheme, {required bool showAvatar}) {
    final mine = m.role == 'driver';
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 6),
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
      decoration: BoxDecoration(
        color: mine ? _green : scheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 5),
          bottomRight: Radius.circular(mine ? 5 : 16),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.text,
              style: TextStyle(
                  color: mine ? Colors.white : scheme.onSurface,
                  fontSize: 15,
                  height: 1.3)),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(_time(m.at),
                style: TextStyle(
                    color: (mine ? Colors.white : scheme.onSurface)
                        .withValues(alpha: 0.55),
                    fontSize: 10.5)),
          ),
        ],
      ),
    );
    if (mine) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 6, bottom: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_otherIcon, size: 14, color: _green),
            )
          else
            const SizedBox(width: 32),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _inputBar(ColorScheme scheme, AppLocalizations t) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: t.chatInputHint,
                  filled: true,
                  fillColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Gradient yuborish tugmasi
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_green, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _green.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _sending ? null : _send,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            size: 22, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
