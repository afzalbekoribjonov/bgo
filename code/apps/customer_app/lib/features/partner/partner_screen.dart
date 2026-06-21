import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'partner_api.dart';
import 'partner_models.dart';

/// Hamkorlik ("hamkorlik") ekrani — ariza yuborish + o'z arizalari holati.
/// plan/05-customer-app.md
class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PartnerType _type = PartnerType.restaurant;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(partnerApiProvider).apply(
            fullName: _nameCtrl.text.trim(),
            type: _type,
            note: _noteCtrl.text.trim(),
          );
      ref.invalidate(myApplicationsProvider);
      if (!mounted) return;
      _nameCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.partnerSubmitted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.partnerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.partnerFormTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: t.partnerFullName,
                    hintText: t.partnerFullNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? t.partnerNameRequired : null,
                ),
                const SizedBox(height: 16),
                Text(t.partnerType,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<PartnerType>(
                  segments: [
                    ButtonSegment(
                      value: PartnerType.restaurant,
                      label: Text(t.partnerTypeRestaurant),
                      icon: const Icon(Icons.restaurant),
                    ),
                    ButtonSegment(
                      value: PartnerType.driver,
                      label: Text(t.partnerTypeDriver),
                      icon: const Icon(Icons.two_wheeler),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: t.partnerNote,
                    hintText: t.partnerNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  icon: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(t.partnerSubmit),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(t.partnerMyApplications,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildMyApplications(t),
        ],
      ),
    );
  }

  Widget _buildMyApplications(AppLocalizations t) {
    final async = ref.watch(myApplicationsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myApplicationsProvider),
      ),
      data: (apps) {
        if (apps.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(t.partnerNoApplications,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          );
        }
        return Column(
          children: apps.map((a) => _applicationCard(t, a)).toList(),
        );
      },
    );
  }

  Widget _applicationCard(AppLocalizations t, PartnerApplication a) {
    final typeLabel = a.type == 'DRIVER'
        ? t.partnerTypeDriver
        : t.partnerTypeRestaurant;
    return Card(
      child: ListTile(
        leading: Icon(
            a.type == 'DRIVER' ? Icons.two_wheeler : Icons.restaurant),
        title: Text(a.fullName),
        subtitle: Text(typeLabel),
        trailing: _statusChip(t, a.status),
      ),
    );
  }

  Widget _statusChip(AppLocalizations t, String status) {
    final (label, color) = switch (status) {
      'APPROVED' => (t.partnerStatusApproved, Colors.green),
      'REJECTED' => (t.partnerStatusRejected, Colors.red),
      _ => (t.partnerStatusPending, Colors.orange),
    };
    return Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
