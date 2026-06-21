import 'package:flutter/material.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/language_button.dart';
import '../auth/auth_controller.dart';
import '../order/my_orders_screen.dart';
import '../parcel/parcel_screen.dart';
import '../partner/partner_screen.dart';
import '../profile/profile_screen.dart';
import '../restaurant/restaurant_list_screen.dart';
import '../taxi/taxi_screen.dart';

/// Bosh ekran — xizmat kartalari. To'liq oqimlar Faza 2+ da. plan/05-customer-app.md
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: t.myOrders,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: t.profileTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const LanguageButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: t.logout,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.welcome, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(t.chooseService, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _ServiceCard(
                    icon: Icons.restaurant,
                    label: t.serviceFood,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RestaurantListScreen(),
                      ),
                    ),
                  ),
                  _ServiceCard(
                    icon: Icons.local_taxi,
                    label: t.serviceTaxi,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TaxiScreen()),
                    ),
                  ),
                  _ServiceCard(
                    icon: Icons.delivery_dining,
                    label: t.serviceDelivery,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParcelScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PartnerBanner(
              title: t.partnerBanner,
              subtitle: t.partnerBannerSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PartnerScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Hamkorlik" bo'limi — bosh ekran pastidagi banner. plan/05-customer-app.md
class _PartnerBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PartnerBanner({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.handshake, color: scheme.onSecondaryContainer, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: scheme.onSecondaryContainer)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ServiceCard({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
