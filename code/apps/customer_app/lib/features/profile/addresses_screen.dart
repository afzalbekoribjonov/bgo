import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'profile_api.dart';
import 'profile_models.dart';

/// Saqlangan manzillar — alohida zamonaviy sahifa.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(addressesProvider);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        ref.invalidate(addressesProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)));
      }
    }

    Future<void> add() async {
      final added = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AddAddressSheet(),
      );
      if (added == true) ref.invalidate(addressesProvider);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.addressesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(t.addressAdd),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(addressesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _empty(context, t);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AddressCard(
              address: items[i],
              onSetDefault: () =>
                  run(() => ref.read(profileApiProvider).setDefault(items[i].id)),
              onDelete: () => run(
                  () => ref.read(profileApiProvider).deleteAddress(items[i].id)),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 64, color: scheme.outline),
          const SizedBox(height: 12),
          Text(t.addressNone, style: TextStyle(color: scheme.outline)),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: address.isDefault
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                address.isDefault ? Icons.home : Icons.location_on_outlined,
                color: address.isDefault ? scheme.primary : scheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t.addressDefaultBadge,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onPrimaryContainer)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(address.text,
                      style: TextStyle(color: scheme.outline, fontSize: 13)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'default') onSetDefault();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (!address.isDefault)
                  PopupMenuItem(
                      value: 'default', child: Text(t.addressSetDefault)),
                PopupMenuItem(value: 'delete', child: Text(t.addressDelete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Yangi manzil qo'shish — pastki varaq.
class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key});

  @override
  ConsumerState<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<AddAddressSheet> {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(t.addressAdd,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: t.addressLabelField,
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: t.addressTextField,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.profileSave),
          ),
        ],
      ),
    );
  }
}
