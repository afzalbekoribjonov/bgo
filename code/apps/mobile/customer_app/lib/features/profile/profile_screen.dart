import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../auth/auth_controller.dart';
import '../messages/messages_api.dart';
import '../messages/messages_screen.dart';
import '../order/my_orders_screen.dart';
import '../partner/partner_screen.dart';
import '../support/support_home_screen.dart';
import 'addresses_screen.dart';
import '../../core/app_webview_screen.dart';
import 'profile_api.dart';
import 'profile_edit_screen.dart';

/// Profil + sozlamalar markazi — premium hub: gradient sarlavha kartasi,
/// bo'lim yorliqlari, gradient ikonkali qatorlar va yumshoq logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Ism bosh harflari (avatar uchun): "Aziz Karimov" → "AK".
  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final a = parts.first.substring(0, 1);
    final b = parts.length > 1 ? parts[1].substring(0, 1) : '';
    return (a + b).toUpperCase();
  }

  /// +998901234567 → +998 90 123 45 67 (o'qish oson bo'lishi uchun).
  static String prettyPhone(String p) {
    final d = p.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('998')) {
      return '+998 ${d.substring(3, 5)} ${d.substring(5, 8)} '
          '${d.substring(8, 10)} ${d.substring(10)}';
    }
    return p;
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final current = ref.read(localeProvider);
    final locale = await showModalBottomSheet<Locale>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const SheetHandle(),
            const SizedBox(height: 16),
            Text(t.language,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _LangTile(
              locale: const Locale('uz'),
              code: 'UZ',
              label: "O'zbekcha",
              current: current,
            ),
            _LangTile(
              locale:
                  const Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
              code: 'ЎЗ',
              label: 'Ўзбекча',
              current: current,
            ),
            _LangTile(
              locale: const Locale('ru'),
              code: 'RU',
              label: 'Русский',
              current: current,
            ),
            const SizedBox(height: 14),
          ],
        ),
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

  /// Joriy til nomi (til qatorining o'ng ko'rsatkichi).
  String _langName(Locale l) {
    if (l.languageCode == 'ru') return 'Русский';
    if (l.scriptCode == 'Cyrl') return 'Ўзбекча';
    return "O'zbekcha";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).user;
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    // "Mening oshxonam" — faqat foydalanuvchi oshxona egasi bo'lsa ko'rinadi.
    final myKitchen = ref.watch(myKitchenProvider).valueOrNull;
    final unreadMessages = ref.watch(unreadMessagesProvider).valueOrNull ?? 0;
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : t.guestUser;
    final initials = initialsOf(name);

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ===== Gradient sarlavha kartasi =====
          _HeroCard(
            name: name,
            phone: user != null ? prettyPhone(user.phone) : null,
            initials: initials,
            editLabel: t.profileEditAction,
            onEdit: () => _open(context, const ProfileEditScreen()),
          ),
          const SizedBox(height: 22),

          // ===== Hisob bo'limi =====
          _SectionLabel(t.accountTitle),
          Card(
            child: Column(
              children: [
                _MenuRow(
                  gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  icon: Icons.badge_rounded,
                  title: t.personalInfo,
                  subtitle: t.profilePersonalSub,
                  onTap: () => _open(context, const ProfileEditScreen()),
                ),
                const _RowDivider(),
                _MenuRow(
                  gradient: const [Color(0xFFFFB74D), Color(0xFFEF6C00)],
                  icon: Icons.location_on_rounded,
                  title: t.addressesTitle,
                  subtitle: t.profileAddressesSub,
                  onTap: () => _open(context, const AddressesScreen()),
                ),
                const _RowDivider(),
                _MenuRow(
                  gradient: const [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  icon: Icons.receipt_long_rounded,
                  title: t.myOrders,
                  subtitle: t.profileOrdersSub,
                  onTap: () => _open(context, const MyOrdersScreen()),
                ),
                const _RowDivider(),
                _MenuRow(
                  gradient: const [Color(0xFFEC407A), Color(0xFFC2185B)],
                  icon: Icons.support_agent_rounded,
                  title: t.supportTitle,
                  subtitle: t.supportProfileSub,
                  onTap: () => _open(context, const SupportHomeScreen()),
                ),
                const _RowDivider(),
                _MenuRow(
                  gradient: const [Color(0xFF546E7A), Color(0xFF37474F)],
                  icon: Icons.notifications_rounded,
                  title: t.msgTitle,
                  subtitle: t.msgProfileSub,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MessagesScreen()),
                    );
                    ref.invalidate(unreadMessagesProvider);
                  },
                  trailing: unreadMessages > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unreadMessages > 99 ? '99+' : '$unreadMessages',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          // ===== Mening oshxonam (faqat egalar) =====
          if (myKitchen != null && myKitchen.owns) ...[
            const SizedBox(height: 12),
            _KitchenCard(
              name: myKitchen.name,
              subtitle: t.profileKitchenSub,
              onTap: () => _open(
                context,
                AppWebViewScreen(
                  baseUrl: ApiConfig.panelBaseUrl,
                  token: myKitchen.accessToken!,
                  title: myKitchen.name ?? 'Mening oshxonam',
                  loadingLabel: 'Oshxona paneli yuklanmoqda…',
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // ===== Sozlamalar bo'limi =====
          _SectionLabel(t.settingsTitle),
          Card(
            child: Column(
              children: [
                _MenuRow(
                  gradient: const [Color(0xFF9575CD), Color(0xFF5E35B1)],
                  icon: Icons.language_rounded,
                  title: t.language,
                  subtitle: t.profileLanguageSub,
                  onTap: () => _pickLanguage(context, ref),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _langName(locale),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const _RowDivider(),
                _MenuRow(
                  gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
                  icon: Icons.handshake_rounded,
                  title: t.partnerBanner,
                  subtitle: t.partnerBannerSubtitle,
                  onTap: () => _open(context, const PartnerScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ===== Chiqish (yumshoq qizil) =====
          Material(
            color: scheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _confirmLogout(context, ref),
              child: SizedBox(
                height: 54,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout_rounded, size: 20, color: scheme.error),
                      const SizedBox(width: 9),
                      Text(
                        t.logout,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),

          // ===== Ilova imzosi =====
          const Center(child: BrandLogo(size: 15)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 11.5, color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================ Vidjetlar ============================ */

/// Gradient sarlavha: avatar (bosh harflar) + ism + telefon + tahrirlash.
class _HeroCard extends StatelessWidget {
  final String name;
  final String? phone;
  final String initials;
  final String editLabel;
  final VoidCallback onEdit;

  const _HeroCard({
    required this.name,
    required this.phone,
    required this.initials,
    required this.editLabel,
    required this.onEdit,
  });

  Widget _bubble(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brand, AppTheme.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Bezak pufakchalari — jonli, brendli fon.
            Positioned(right: -34, top: -44, child: _bubble(150, 0.08)),
            Positioned(right: 52, bottom: -56, child: _bubble(120, 0.06)),
            Positioned(left: -28, bottom: -36, child: _bubble(96, 0.05)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar — oq halqali, bosh harflar bilan.
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.75),
                              width: 2.4),
                        ),
                        child: Center(
                          child: initials.isNotEmpty
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                )
                              : const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (phone != null) ...[
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_rounded,
                                        size: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.9)),
                                    const SizedBox(width: 5),
                                    Text(
                                      phone!,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tahrirlash — muzli (frosted) keng tugma.
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  size: 17, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                editLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kichik bo'lim yorlig'i (HISOB, SOZLAMALAR).
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// Premium menyu qatori: gradient ikonka kvadrati + sarlavha + izoh + chevron.
class _MenuRow extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuRow({
    required this.gradient,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.last.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 17, color: scheme.outline),
                ),
          ],
        ),
      ),
    );
  }
}

/// Qatorlar orasidagi ingichka ajratgich (ikonkadan keyin boshlanadi).
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.5),
    );
  }
}

/// "Mening oshxonam" — to'q sariq gradientli maxsus karta (faqat egalar).
class _KitchenCard extends StatelessWidget {
  final String? name;
  final String subtitle;
  final VoidCallback onTap;

  const _KitchenCard({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF6C00).withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? 'Mening oshxonam',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Til tanlash qatori (pastki varaqda) — joriy til belgilangan.
class _LangTile extends StatelessWidget {
  final Locale locale;
  final String code;
  final String label;
  final Locale current;

  const _LangTile({
    required this.locale,
    required this.code,
    required this.label,
    required this.current,
  });

  bool get _selected =>
      current.languageCode == locale.languageCode &&
      current.scriptCode == locale.scriptCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.pop(context, locale),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selected
                    ? AppTheme.brand.withValues(alpha: 0.12)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _selected ? AppTheme.brand : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Icon(
              _selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: _selected ? AppTheme.brand : scheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
