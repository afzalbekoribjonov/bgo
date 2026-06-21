import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../auth/auth_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
