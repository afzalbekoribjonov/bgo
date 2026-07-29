import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_error.dart';
import '../../widgets/brand.dart';
import 'support_api.dart';
import 'support_models.dart';

/// Yordam suhbat ekrani — ikki holat bir ekranda:
/// [conversationId] null bo'lsa FAQ_MENU (tayyor savollar + "Savolim bor"),
/// FAQ tanlansa yoki "Savolim bor" bosilsa CHAT holatiga o'tadi (navigatsiyasiz).
/// Mavjud suhbat tarixdan ochilsa to'g'ridan-to'g'ri CHAT holatida boshlanadi.
class SupportChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? initialTitle;
  const SupportChatScreen({super.key, this.conversationId, this.initialTitle});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  static const String _myRole = 'USER';

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;

  String? _conversationId;
  String _title = '';
  String _status = 'OPEN';
  List<SupportMessage> _messages = const [];

  bool _loadingChat = false;
  bool _sending = false;
  bool _creating = false;
  Object? _initialError;

  bool get _inFaqMenu => _conversationId == null;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _title = widget.initialTitle ?? '';
    if (_conversationId != null) {
      _loadingChat = true;
      _load(initial: true);
      _startPolling();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _load();
    });
  }

  bool get _nearBottom {
    if (!_scroll.hasClients) return true;
    return _scroll.position.maxScrollExtent - _scroll.position.pixels < 140;
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _load({bool initial = false}) async {
    if (_conversationId == null) return;
    try {
      final api = ref.read(supportApiProvider);
      final msgs = await api.messages(_conversationId!);
      final convs = await api.listConversations();
      String status = _status;
      for (final c in convs) {
        if (c.id == _conversationId) {
          status = c.status;
          break;
        }
      }
      if (!mounted) return;
      final wasNearBottom = _nearBottom;
      final grew = msgs.length > _messages.length;
      setState(() {
        _messages = msgs;
        _status = status;
        _loadingChat = false;
        _initialError = null;
      });
      if (grew && (wasNearBottom || initial)) _scrollToBottom(jump: initial);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingChat = false;
        if (initial && _messages.isEmpty) _initialError = e;
      });
    }
  }

  Future<void> _startConversation(String topic, String title) async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final (conv, msgs) =
          await ref.read(supportApiProvider).createConversation(topic);
      ref.invalidate(myConversationsProvider);
      if (!mounted) return;
      setState(() {
        _conversationId = conv.id;
        _title = title;
        _status = conv.status;
        _messages = msgs;
      });
      _startPolling();
      _scrollToBottom(jump: true);
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _conversationId == null) return;
    setState(() => _sending = true);
    try {
      final api = ref.read(supportApiProvider);
      final newMsgs = await api.sendMessage(_conversationId!, text);
      _controller.clear();
      if (!mounted) return;
      setState(() => _messages = [..._messages, ...newMsgs]);
      _scrollToBottom();
      await _load();
      ref.invalidate(myConversationsProvider);
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
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

  DateTime? _at(SupportMessage m) => DateTime.tryParse(m.createdAt)?.toLocal();

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
    return _inFaqMenu ? _buildFaqMenu(context) : _buildChat(context);
  }

  /* ============================ FAQ_MENU ============================ */

  Widget _buildFaqMenu(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final faqAsync = ref.watch(supportFaqProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.supportTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.supportMenuHeadline,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(t.supportMenuSub,
                    style: TextStyle(fontSize: 13, color: scheme.outline)),
              ],
            ),
          ),
          Expanded(
            child: faqAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AsyncErrorRetry(
                error: e,
                onRetry: () => ref.invalidate(supportFaqProvider),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text(t.supportHistoryEmptySub,
                          style: TextStyle(color: scheme.outline)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _faqCard(items[i], scheme),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: BrandButton(
            label: t.supportAskQuestion,
            icon: Icons.smart_toy_rounded,
            loading: _creating,
            onPressed: _creating
                ? null
                : () => _startConversation('ai', t.supportAiTopic),
          ),
        ),
      ),
    );
  }

  Widget _faqCard(SupportFaqItem item, ColorScheme scheme) {
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _creating ? null : () => _startConversation(item.id, item.label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.quiz_rounded,
                    size: 18, color: AppTheme.brand),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(item.label,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  /* ============================== CHAT =============================== */

  Widget _buildChat(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final escalated = _status == 'ESCALATED';

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
              child: const Icon(Icons.support_agent_rounded,
                  size: 20, color: AppTheme.brand),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title.isNotEmpty ? _title : t.supportTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    escalated ? t.supportSenderAdmin : t.supportSenderAi,
                    style: TextStyle(fontSize: 11, color: scheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (escalated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFFEF6C00).withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      size: 16, color: Color(0xFFB85C00)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.supportEscalatedBanner,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB85C00)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _chatBody(t, scheme)),
          _inputBar(t, scheme),
        ],
      ),
    );
  }

  Widget _chatBody(AppLocalizations t, ColorScheme scheme) {
    if (_loadingChat && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initialError != null && _messages.isEmpty) {
      return AsyncErrorRetry(
        error: _initialError!,
        onRetry: () {
          setState(() {
            _loadingChat = true;
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
                    size: 34, color: AppTheme.brand.withValues(alpha: 0.7)),
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
            _bubble(t, m, scheme),
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
              child:
                  Divider(color: scheme.outlineVariant.withValues(alpha: 0.6))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              child:
                  Divider(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _bubble(AppLocalizations t, SupportMessage m, ColorScheme scheme) {
    if (m.senderRole == 'SYSTEM') {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF6C00).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(m.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB85C00))),
        ),
      );
    }

    final mine = m.senderRole == _myRole;
    final roleLabel = m.senderRole == 'ADMIN'
        ? t.supportSenderAdmin
        : (m.senderRole == 'AI' ? t.supportSenderAi : null);
    final icon = m.senderRole == 'ADMIN'
        ? Icons.support_agent_rounded
        : Icons.smart_toy_rounded;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 6),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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
          if (roleLabel != null && !mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(roleLabel,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: (mine ? Colors.white : AppTheme.brand)
                          .withValues(alpha: 0.85))),
            ),
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
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 6, bottom: 4),
            decoration: BoxDecoration(
              color: AppTheme.brand.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: AppTheme.brand),
          ),
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
                  hintText: t.supportInputHint,
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
      ),
    );
  }
}
