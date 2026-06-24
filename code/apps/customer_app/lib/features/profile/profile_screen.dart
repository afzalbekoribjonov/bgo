import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../order/my_orders_screen.dart';
import '../partner/partner_screen.dart';
import 'addresses_screen.dart';
import 'profile_edit_screen.dart';

/// Profil + sozlamalar markazi — bo'limlarga ajratilgan toza hub.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
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

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.logout),
        content: Text(t.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
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
  Widget build(BuildContext context, WidgetRef ref) {
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
          // --- Hisob sarlavhasi (bosilsa tahrirlash) ---
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(context, const ProfileEditScreen()),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.primary.withValues(alpha: 0.82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
                      child: Icon(Icons.person, color: scheme.onPrimary, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          if (user != null) ...[
                            const SizedBox(height: 2),
                            Text(user.phone,
                                style: TextStyle(
                                    color: scheme.onPrimary
                                        .withValues(alpha: 0.85))),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined,
                        color: scheme.onPrimary.withValues(alpha: 0.9), size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Bo'limlar ---
          Card(
            child: Column(
              children: [
                _tile(context, Icons.badge_outlined, t.personalInfo,
                    () => _open(context, const ProfileEditScreen())),
                const Divider(height: 1, indent: 56),
                _tile(context, Icons.location_on_outlined, t.addressesTitle,
                    () => _open(context, const AddressesScreen())),
                const Divider(height: 1, indent: 56),
                _tile(context, Icons.receipt_long_outlined, t.myOrders,
                    () => _open(context, const MyOrdersScreen())),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _tile(context, Icons.language, t.language,
                    () => _pickLanguage(context, ref)),
                const Divider(height: 1, indent: 56),
                _tile(context, Icons.handshake_outlined, t.partnerBanner,
                    () => _open(context, const PartnerScreen())),
              ],
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: Icon(Icons.logout, color: scheme.error),
            label: Text(t.logout, style: TextStyle(color: scheme.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
