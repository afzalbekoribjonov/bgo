import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_error.dart';
import 'taxi_models.dart';

/// Safar/dostavka suhbat ekrani (mijoz tomoni). 3s polling.
/// Professional: sana ajratgichlar, quyruqli pufaklar, oflayn banner,
/// birinchi yuklanish xatosida RETRY, aqlli avto-scroll (pastda bo'lsagina).
/// Birinchi xabar oldidan server "Assalomu alaykum, " qo'yadi.
class TaxiChatScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripTitle;
  final String? phone; // haydovchi raqami (qo'ng'iroq tugmasi)
  final String vertical; // 'taxi' | 'parcel'
  const TaxiChatScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
    this.phone,
    this.vertical = 'taxi',
  });

  @override
  ConsumerState<TaxiChatScreen> createState() => _TaxiChatScreenState();
}

class _TaxiChatScreenState extends ConsumerState<TaxiChatScreen> {
  // Bu ilovada "men" — mijoz; o'ng tomonda ko'rinadi.
  static const String _myRole = 'customer';

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  List<TaxiMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  Object? _initialError;
  int _failStreak = 0;

  String get _msgBase => '/${widget.vertical}/${widget.tripId}/messages';

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

  bool get _nearBottom {
    if (!_scroll.hasClients) return true;
    return _scroll.position.maxScrollExtent - _scroll.position.pixels < 140;
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final res = await ref.read(dioProvider).get(_msgBase);
      final list = (res.data['data'] as List?) ?? const [];
      final msgs = list
          .map((e) => TaxiMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      final wasNearBottom = _nearBottom;
      final grew = msgs.length > _messages.length;
      setState(() {
        _messages = msgs;
        _loading = false;
        _initialError = null;
        _failStreak = 0;
      });
      if (grew && (wasNearBottom || initial)) _scrollToBottom(jump: initial);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failStreak++;
        if (initial && _messages.isEmpty) _initialError = e;
      });
    }
  }

  void _scrollToBottom({bool jump = false}) {
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(dioProvider).post(_msgBase, data: {'text': text});
      _controller.clear();
      await _load();
      _scrollToBottom();
    } catch (e) {
      // Matn inputda qoladi — qayta yuborish oson.
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkError(e)
                ? t.errorNetwork
                : (httpStatus(e) == 400
                    ? 'Bu suhbatga hozir yozib bo\'lmaydi'
                    : t.errorGeneric)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
  }

  DateTime? _at(TaxiMessage m) => DateTime.tryParse(m.createdAt)?.toLocal();

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Bugun';
    if (day == today.subtract(const Duration(days: 1))) return 'Kecha';
    return '${d.day.toString().padLeft(2, "0")}.${d.month.toString().padLeft(2, "0")}.${d.year}';
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return true;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
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
                color: AppTheme.brand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_motorsports_rounded,
                  size: 20, color: AppTheme.brand),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.tripTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(_offline ? 'aloqa kutilmoqda…' : t.chatTitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: _offline
                              ? const Color(0xFFEF6C00)
                              : scheme.outline)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if ((widget.phone ?? '').isNotEmpty)
            IconButton(
              tooltip: 'Qo‘ng‘iroq',
              icon: const Icon(Icons.call_rounded),
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: widget.phone)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_offline && _initialError == null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFEF6C00).withValues(alpha: 0.12),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFEF6C00)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Internet aloqasi yo\'q — qayta ulanmoqda…',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB85C00)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _body(t, scheme)),
          _inputBar(t, scheme),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations t, ColorScheme scheme) {
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 34,
                    color: AppTheme.brand.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 12),
              Text(t.chatEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: scheme.outline, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        final at = _at(m);
        final prevAt = i > 0 ? _at(_messages[i - 1]) : null;
        final showDay = at != null && !_sameDay(prevAt, at);
        return Column(
          children: [
            if (showDay) _daySeparator(at, scheme),
            _bubble(m, scheme,
                showAvatar: m.senderRole != _myRole &&
                    (i == _messages.length - 1 ||
                        _messages[i + 1].senderRole != m.senderRole)),
          ],
        );
      },
    );
  }

  Widget _daySeparator(DateTime d, ColorScheme scheme) {
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
            child: Text(_dayLabel(d),
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

  Widget _bubble(TaxiMessage m, ColorScheme scheme,
      {required bool showAvatar}) {
    final mine = m.senderRole == _myRole;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 6),
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
      decoration: BoxDecoration(
        color: mine ? AppTheme.brand : scheme.surface,
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
            child: Text(_time(m.createdAt),
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
                color: AppTheme.brand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_motorsports_rounded,
                  size: 14, color: AppTheme.brand),
            )
          else
            const SizedBox(width: 32),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _inputBar(AppLocalizations t, ColorScheme scheme) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_messages.isEmpty && !_loading && _initialError == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: scheme.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t.chatGreetingNote,
                        style:
                            TextStyle(fontSize: 12, color: scheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
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
                      fillColor: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
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
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.brand, AppTheme.brandDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.brand.withValues(alpha: 0.35),
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
          ],
        ),
      ),
    );
  }
}
