import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/alert_sound.dart';
import '../../core/online_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/language_button.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/driver_profile.dart';
import '../delivery/delivery_api.dart';
import '../support/support_home_screen.dart';

/// Profil + sozlamalar markazi (avatar bosilganda ochiladi). plan/06-driver-app.md
class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(driverProfileProvider);
    final online = ref.watch(onlineProvider);
    final activeCount =
        ref.watch(earningsProvider).valueOrNull?.total.activeCount ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _profileHeader(context, scheme, profileAsync.valueOrNull, online, t),
          const SizedBox(height: 18),
          _sectionLabel(context, t.profileAccountSection),
          _menuCard(context, [
            _tile(
              context,
              gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
              icon: Icons.badge_rounded,
              title: t.profileMyInfo,
              subtitle: t.profileMyInfoSub,
              page: const _InfoPage(),
            ),
            _rowDivider(context),
            _tile(
              context,
              gradient: const [Color(0xFFBA68C8), Color(0xFF8E24AA)],
              icon: Icons.directions_car_rounded,
              title: t.profileMyCar,
              subtitle: t.profileMyCarSub,
              page: const _CarPage(),
            ),
            _rowDivider(context),
            _tile(
              context,
              gradient: const [Color(0xFFEC407A), Color(0xFFC2185B)],
              icon: Icons.support_agent_rounded,
              title: t.supportTitle,
              subtitle: t.supportProfileSub,
              page: const SupportHomeScreen(),
            ),
          ]),
          const SizedBox(height: 18),
          _sectionLabel(context, t.profileSettingsSection),
          _menuCard(context, [
            _tile(
              context,
              gradient: const [Color(0xFFFFB74D), Color(0xFFEF6C00)],
              icon: Icons.volume_up_rounded,
              title: t.profileSoundLang,
              subtitle: t.profileSoundLangSub,
              page: const _SoundLangPage(),
            ),
            _rowDivider(context),
            _tile(
              context,
              gradient: const [Color(0xFF4DB6AC), Color(0xFF00897B)],
              icon: Icons.menu_book_rounded,
              title: t.profileGuide,
              subtitle: t.profileGuideSub,
              page: const _GuidePage(),
            ),
          ]),
          const SizedBox(height: 22),
          // Ilovadan chiqish — neytral (sessiya saqlanadi).
          Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _exit(context, online, activeCount, t),
              child: SizedBox(
                height: 54,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.exit_to_app_rounded,
                          size: 20, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 9),
                      Text(t.profileExitApp,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // HISOBDAN chiqish — qizil (sessiya tozalanadi, kod bilan qayta kiriladi).
          Material(
            color: scheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _logout(context, ref, online, activeCount, t),
              child: SizedBox(
                height: 54,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 20, color: scheme.error),
                      const SizedBox(width: 9),
                      Text(t.profileLogout,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.error)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (online || activeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                online ? t.profileExitHintOnline : t.profileExitHintActive,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
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

  Widget _menuCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _rowDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.5),
    );
  }

  /// Hisobdan chiqish — liniyada/faol buyurtmada taqiqlanadi; tasdiqdan
  /// so'ng sessiya tozalanib login ekraniga qaytadi (kod bilan qayta kirish).
  Future<void> _logout(BuildContext context, WidgetRef ref, bool online,
      int activeCount, AppLocalizations t) async {
    if (online || activeCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(online
              ? t.profileCannotExitOnline
              : t.profileCannotExitActive),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.profileLogout),
        content: Text(t.profileLogoutDialogContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.profileYesExit),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Fon GPS servisini to'xtatib, holatni tozalaymiz.
    OnlineService.stop();
    ref.read(onlineProvider.notifier).state = false;
    ref.read(alertSoundProvider).stop();
    await ref.read(authControllerProvider.notifier).logout();
    // AuthGate holat o'zgarishini ko'rib login ekraniga o'tadi; ochiq
    // sahifalarni yopib qo'yamiz.
    if (context.mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _exit(BuildContext context, bool online, int activeCount,
      AppLocalizations t) {
    if (online || activeCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(online
              ? t.profileCannotExitOnline
              : t.profileCannotExitActive),
        ),
      );
      return;
    }
    SystemNavigator.pop();
  }

  Widget _profileHeader(BuildContext context, ColorScheme scheme,
      DriverProfile? p, bool online, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, const Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.75), width: 2.4),
            ),
            child: Center(
              child: Text(
                p?.initial ?? '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.fullName ?? '...',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  p?.phone ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: online ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: online ? 0.5 : 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: online ? const Color(0xFF69F0AE) : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            online ? t.profileOnlineBadge : t.profileOfflineBadge,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if ((p?.rating ?? 0) > 0) _ratingBadge(p!.rating),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Haydovchi umumiy reytingi — profil sarlavhasida, onlayn belgisi yonida.
  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD54F)),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required List<Color> gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
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
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
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

// ---------------- Ma'lumotlarim ----------------

class _InfoPage extends ConsumerWidget {
  const _InfoPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final p = ref.watch(driverProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(t.profileMyInfo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, t.profilePersonalInfo),
          _infoCard(context, [
            _infoRow(context, Icons.person_outline_rounded, t.profileFullName,
                p?.fullName ?? '—'),
            _infoRow(context, Icons.cake_outlined, t.profileAge,
                p?.age != null ? t.profileAgeValue(p!.age.toString()) : '—'),
            _infoRow(context, Icons.phone_outlined, t.profilePhone,
                p?.phone ?? '—',
                last: true),
          ]),
          const SizedBox(height: 14),
          _hintNote(context, t.profileInfoHint),
        ],
      ),
    );
  }
}

// ---------------- Mening mashinam ----------------

class _CarPage extends ConsumerWidget {
  const _CarPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final p = ref.watch(driverProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(t.profileMyCar)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avtomobil pasporti — bitta jiddiy karta
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF263238), Color(0xFF37474F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded,
                      color: Color(0xFFD4AF37), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p?.carName ?? '—',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p?.carYear != null
                            ? t.profileCarYear(p!.carYear.toString())
                            : '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                // Davlat raqami — plastina ko'rinishida
                if ((p?.plateNumber ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                          color: const Color(0xFF1A237E), width: 1.6),
                    ),
                    child: Text(
                      p!.plateNumber!.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                          color: Color(0xFF1A237E)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, t.profileDocuments),
          _infoCard(context, [
            _infoRow(context, Icons.badge_outlined,
                t.profileLicense, p?.licenseInfo ?? '—',
                last: true),
          ]),
        ],
      ),
    );
  }
}

// ---------------- Ovoz va til ----------------

class _SoundLangPage extends ConsumerWidget {
  const _SoundLangPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final soundOn = ref.watch(soundEnabledProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.profileSoundLang)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, t.profileNotifications),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.notifications_active_outlined,
                    size: 21, color: scheme.onSurfaceVariant),
              ),
              title: Text(t.profileOrderSound,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              subtitle: Text(t.profileOrderSoundSub,
                  style:
                      TextStyle(fontSize: 12, color: scheme.outline)),
              value: soundOn,
              onChanged: (v) =>
                  ref.read(soundEnabledProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, t.profileLanguageSection),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.language_rounded,
                      size: 21, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(t.profileAppLanguage,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const LanguageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Yo'riqnoma ----------------

class _GuidePage extends StatelessWidget {
  const _GuidePage();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final steps = <(IconData, String, String)>[
      (
        Icons.swipe_right_alt_rounded,
        t.homeGoOnline,
        t.guideStep1Body,
      ),
      (
        Icons.notifications_active_outlined,
        t.homeNewOrder,
        t.guideStep2Body,
      ),
      (
        Icons.list_alt_rounded,
        t.poolTitle,
        t.guideStep3Body,
      ),
      (
        Icons.swipe_left_alt_rounded,
        t.homeFinishWork,
        t.guideStep4Body,
      ),
      (
        Icons.logout_rounded,
        t.profileExitApp,
        t.guideStep5Body,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t.profileGuide)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final (icon, title, body) = steps[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      size: 20, color: const Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.outline)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(body,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Umumiy (sub-sahifalar) yordamchilari ----------------

/// Kichik bo'lim sarlavhasi — korporativ, katta harfli.
Widget _sectionTitle(BuildContext context, String text) {
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

/// Ma'lumot kartasi — qatorlar bitta oq kartada, ajratgichlar bilan.
Widget _infoCard(BuildContext context, List<Widget> rows) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: rows),
  );
}

/// Bitta ma'lumot qatori — neytral ikonka + YORLIQ + qiymat (jiddiy uslub).
Widget _infoRow(
    BuildContext context, IconData icon, String label, String value,
    {bool last = false}) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.onSurfaceVariant, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                          color: scheme.outline,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
      if (!last)
        Divider(
            height: 1,
            indent: 66,
            color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ],
  );
}

/// Pastki izoh (administratorga murojaat va h.k.).
Widget _hintNote(BuildContext context, String text) {
  final scheme = Theme.of(context).colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline_rounded, size: 15, color: scheme.outline),
      const SizedBox(width: 7),
      Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 12, height: 1.35, color: scheme.outline)),
      ),
    ],
  );
}
