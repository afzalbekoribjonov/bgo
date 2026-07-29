import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import 'taxi_api.dart';
import 'taxi_models.dart';

/// Taksi suhbat ekrani (haydovchi tomoni). 4s polling bilan yangilanadi.
/// Birinchi xabar oldidan server "Assalomu alaykum, " qo'yadi.
class TaxiChatScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripTitle;
  const TaxiChatScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  ConsumerState<TaxiChatScreen> createState() => _TaxiChatScreenState();
}

class _TaxiChatScreenState extends ConsumerState<TaxiChatScreen> {
  // Bu ilovada "men" — haydovchi; o'ng tomonda ko'rinadi.
  static const String _myRole = 'driver';

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  List<TaxiMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
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

  Future<void> _load({bool initial = false}) async {
    try {
      final msgs = await ref.read(taxiApiProvider).messages(widget.tripId);
      if (!mounted) return;
      final grew = msgs.length != _messages.length;
      setState(() {
        _messages = msgs;
        _loading = false;
        _error = null;
      });
      if (grew) _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        if (initial && _messages.isEmpty) {
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric;
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(taxiApiProvider).sendMessage(widget.tripId, text);
      _controller.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('${t.chatTitle} · ${widget.tripTitle}')),
      body: Column(
        children: [
          Expanded(child: _body(t)),
          _inputBar(t),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _load(initial: true),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.chatEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) => _bubble(t, _messages[i]),
    );
  }

  Widget _bubble(AppLocalizations t, TaxiMessage m) {
    final mine = m.senderRole == _myRole;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                color: mine ? Colors.white : scheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _time(m.createdAt),
              style: TextStyle(
                fontSize: 10.5,
                color: mine
                    ? Colors.white.withValues(alpha: 0.8)
                    : scheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// createdAt -> "HH:mm" (mahalliy vaqt).
  String _time(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _inputBar(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_messages.isEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: scheme.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t.chatGreetingNote,
                        style: TextStyle(fontSize: 12, color: scheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: t.chatInputHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
