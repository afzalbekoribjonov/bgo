import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/alert_sound.dart';
import '../../widgets/language_button.dart';
import '../auth/auth_api.dart';
import '../auth/driver_profile.dart';
import '../delivery/delivery_api.dart';

/// Profil + sozlamalar markazi (avatar bosilganda ochiladi). plan/06-driver-app.md
class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(driverProfileProvider);
    final online = ref.watch(onlineProvider);
    final activeCount =
        ref.watch(earningsProvider).valueOrNull?.total.activeCount ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          _profileHeader(context, scheme, profileAsync.valueOrNull, online),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.person_rounded,
            color: const Color(0xFF1E88E5),
            title: 'Ma‘lumotlarim',
            subtitle: 'F.I.SH, yosh, telefon',
            page: const _InfoPage(),
          ),
          _tile(
            context,
            icon: Icons.directions_car_rounded,
            color: const Color(0xFF8E24AA),
            title: 'Mening mashinam',
            subtitle: 'Avtomobil va guvohnoma',
            page: const _CarPage(),
          ),
          _tile(
            context,
            icon: Icons.payments_rounded,
            color: const Color(0xFF2E7D32),
            title: 'Tariflar va daromad',
            subtitle: 'Bugungi va umumiy daromad',
            page: const _TariffsPage(),
          ),
          _tile(
            context,
            icon: Icons.volume_up_rounded,
            color: const Color(0xFFEF6C00),
            title: 'Ovoz va til',
            subtitle: 'Signal ovozi, ilova tili',
            page: const _SoundLangPage(),
          ),
          _tile(
            context,
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF00897B),
            title: 'Yo‘riqnoma',
            subtitle: 'Ilovadan qanday foydalanish',
            page: const _GuidePage(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _exit(context, online, activeCount),
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('Ilovadan chiqish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          if (online || activeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                online
                    ? 'Avval «Ishni yakunlash»ni bosing — liniyada turib ilovani yopib bo‘lmaydi.'
                    : 'Faol buyurtmangiz bor — yakunlamaguncha ilova yopilmaydi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _exit(BuildContext context, bool online, int activeCount) {
    if (online || activeCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(online
              ? 'Liniyadasiz — avval ishni yakunlang.'
              : 'Faol buyurtmangiz bor.'),
        ),
      );
      return;
    }
    SystemNavigator.pop();
  }

  Widget _profileHeader(BuildContext context, ColorScheme scheme,
      DriverProfile? p, bool online) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, const Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            child: Text(
              p?.initial ?? '?',
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    online ? '🟢 Liniyada' : '⚪ Oflayn',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
    );
  }
}

// ---------------- Ma'lumotlarim ----------------

class _InfoPage extends ConsumerWidget {
  const _InfoPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(driverProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Ma‘lumotlarim')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('👤', 'F.I.SH', p?.fullName ?? '—'),
          _row('🎂', 'Yoshi', p?.age != null ? '${p!.age}' : '—'),
          _row('📞', 'Telefon', p?.phone ?? '—'),
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
    final p = ref.watch(driverProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Mening mashinam')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('🚗', 'Avtomobil', p?.carName ?? '—'),
          _row('📅', 'Yili', p?.carYear != null ? '${p!.carYear}' : '—'),
          _row('🔢', 'Davlat raqami', p?.plateNumber ?? '—'),
          _row('🪪', 'Guvohnoma', p?.licenseInfo ?? '—'),
        ],
      ),
    );
  }
}

// ---------------- Tariflar va daromad ----------------

class _TariffsPage extends ConsumerWidget {
  const _TariffsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(earningsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tariflar va daromad')),
      body: e.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Ma‘lumot yuklanmadi')),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _earnCard(context, 'Bugungi daromad',
                '${groupThousands(d.total.todayEarning)} so‘m', const Color(0xFF2E7D32)),
            const SizedBox(height: 12),
            _earnCard(context, 'Umumiy daromad',
                '${groupThousands(d.total.earning)} so‘m', const Color(0xFF1E88E5)),
            const SizedBox(height: 20),
            const Text('Vertikallar bo‘yicha',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _row('🍽️', 'Ovqat', '${groupThousands(d.food.earning)} so‘m'),
            _row('🚕', 'Taksi', '${groupThousands(d.taxi.earning)} so‘m'),
            _row('📦', 'Dostavka', '${groupThousands(d.parcel.earning)} so‘m'),
            const SizedBox(height: 16),
            Text(
              'To‘lov turi: faqat naqd (MVP). Komissiya tarifi administrator tomonidan belgilanadi.',
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _earnCard(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: color)),
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
    final soundOn = ref.watch(soundEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ovoz va til')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_rounded),
            title: const Text('Buyurtma signali ovozi'),
            subtitle: const Text('Yangi buyurtma kelganda ovoz chiqishi'),
            value: soundOn,
            onChanged: (v) =>
                ref.read(soundEnabledProvider.notifier).state = v,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Ilova tili'),
            subtitle: const Text('O‘zbek (lotin/kirill), Rus'),
            trailing: const LanguageButton(),
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
    final steps = <(String, String)>[
      ('🟢', 'Liniyaga chiqish — pastdagi tugmani o‘ngga suring. Navigator belgisi tillo rangga o‘tadi.'),
      ('🔔', 'Buyurtma kelganda ovoz va tebranish bo‘ladi.'),
      ('🗺️', 'Xaritada o‘zingizning joylashuvingiz doim markazda turadi.'),
      ('🔴', 'Ishni tugatish — tugmani suring (faol buyurtma bo‘lmasa).'),
      ('🚪', 'Ilovadan chiqish faqat oflayn va faol buyurtmasiz holatda mumkin.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Yo‘riqnoma')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$1, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s.$2, style: const TextStyle(fontSize: 15))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Umumiy qator (label/value)
Widget _row(String emoji, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}
