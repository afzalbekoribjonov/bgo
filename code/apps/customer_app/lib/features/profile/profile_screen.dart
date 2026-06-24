import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../auth/auth_controller.dart';
import '../order/my_orders_screen.dart';
import '../partner/partner_screen.dart';
import 'profile_api.dart';
import 'profile_models.dart';

/// Profil — ism tahrirlash + saqlangan manzillar. plan/05-customer-app.md
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    final name = ref.read(authControllerProvider).user?.fullName ?? '';
    _nameCtrl = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final t = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.length < 2) return;
    setState(() => _savingName = true);
    try {
      await ref.read(profileApiProvider).updateName(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.profileSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _addAddress() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddAddressSheet(),
    );
    if (added == true) ref.invalidate(addressesProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    final t = AppLocalizations.of(context)!;
    try {
      await action();
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
      );
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _pickLanguage() async {
    final locale = await showDialog<Locale>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(ctx)!.language),
        children: const [
          _LangOption(Locale('uz'), "O'zbekcha"),
          _LangOption(
            Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
            'Ўзбекча',
          ),
          _LangOption(Locale('ru'), 'Русский'),
        ],
      ),
    );
    if (locale != null) ref.read(localeProvider.notifier).state = locale;
  }

  Future<void> _confirmLogout() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.logout),
        content: Text(t.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).user;
    final scheme = Theme.of(context).colorScheme;
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : t.guestUser;
    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Hisob sarlavhasi ---
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primary,
                    child: Icon(Icons.person, color: scheme.onPrimary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                )),
                        if (user != null)
                          Text(user.phone,
                              style: TextStyle(color: scheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Sozlamalar menyusi ---
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(t.myOrders),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const MyOrdersScreen()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(t.language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickLanguage,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(t.partnerBanner),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const PartnerScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Shaxsiy ma'lumotlar ---
          Text(t.profileName,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: t.profileName,
              hintText: t.profileNameHint,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _savingName ? null : _saveName,
              child: _savingName
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.profileSave),
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.addressesTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addAddress,
                icon: const Icon(Icons.add),
                label: Text(t.addressAdd),
              ),
            ],
          ),
          _buildAddresses(t),
          const SizedBox(height: 24),

          // --- Chiqish (tasdiqlash bilan) ---
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: Icon(Icons.logout, color: scheme.error),
            label: Text(t.logout, style: TextStyle(color: scheme.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddresses(AppLocalizations t) {
    final async = ref.watch(addressesProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(addressesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(t.addressNone,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          );
        }
        return Column(children: items.map((a) => _addressCard(t, a)).toList());
      },
    );
  }

  Widget _addressCard(AppLocalizations t, Address a) {
    return Card(
      child: ListTile(
        leading: Icon(a.isDefault ? Icons.home : Icons.location_on_outlined,
            color: a.isDefault ? Theme.of(context).colorScheme.primary : null),
        title: Text(a.label),
        subtitle: Text(a.text),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'default') {
              _run(() => ref.read(profileApiProvider).setDefault(a.id));
            } else if (v == 'delete') {
              _run(() => ref.read(profileApiProvider).deleteAddress(a.id));
            }
          },
          itemBuilder: (_) => [
            if (!a.isDefault)
              PopupMenuItem(value: 'default', child: Text(t.addressSetDefault)),
            PopupMenuItem(value: 'delete', child: Text(t.addressDelete)),
          ],
        ),
      ),
    );
  }
}

/// Til tanlash varianti (SimpleDialog ichida).
class _LangOption extends StatelessWidget {
  final Locale locale;
  final String label;
  const _LangOption(this.locale, this.label);

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, locale),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}

/// Yangi manzil qo'shish — pastki varaq.
class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet();

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  final _labelCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final label = _labelCtrl.text.trim();
    final text = _textCtrl.text.trim();
    if (label.isEmpty || text.length < 3) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileApiProvider).addAddress(label: label, text: text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.addressAdd, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: t.addressLabelField,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: t.addressTextField,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.profileSave),
          ),
        ],
      ),
    );
  }
}
