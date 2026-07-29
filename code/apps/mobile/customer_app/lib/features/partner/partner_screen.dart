import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_error.dart';
import '../../widgets/brand.dart';
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
          // Hero banner — nima taklif qilinayotgani birdan tushunarli.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brand, AppTheme.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brand.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.handshake_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.partnerBanner,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(t.partnerBannerSubtitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(t.partnerFormTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: t.partnerFullName,
                    hintText: t.partnerFullNameHint,
                    prefixIcon: const Icon(Icons.badge_outlined),
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
                    prefixIcon: const Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                BrandButton(
                  label: t.partnerSubmit,
                  icon: Icons.send_rounded,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(t.partnerMyApplications,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
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
