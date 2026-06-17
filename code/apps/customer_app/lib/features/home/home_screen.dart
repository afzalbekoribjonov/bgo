import 'package:flutter/material.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/language_button.dart';
import '../auth/auth_controller.dart';

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
                  _ServiceCard(icon: Icons.restaurant, label: t.serviceFood),
                  _ServiceCard(icon: Icons.local_taxi, label: t.serviceTaxi),
                  _ServiceCard(icon: Icons.delivery_dining, label: t.serviceDelivery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        // TODO(Faza 2): tegishli xizmat ekraniga o'tish
        onTap: () {},
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
