import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() => runApp(const BeshariqApp());

/// Beshariq mijoz ilovasi — Faza 0 skeleti.
/// 3 til (uz / uz-Cyrl / ru) almashtirish namoyishi.
/// Reja: plan/05-customer-app.md
class BeshariqApp extends StatefulWidget {
  const BeshariqApp({super.key});

  @override
  State<BeshariqApp> createState() => _BeshariqAppState();
}

class _BeshariqAppState extends State<BeshariqApp> {
  // Standart til — O'zbek (lotin)
  Locale _locale = const Locale('uz');

  void _setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E88E5),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(onLocaleChange: _setLocale, currentLocale: _locale),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final void Function(Locale) onLocaleChange;
  final Locale currentLocale;

  const HomeScreen({
    super.key,
    required this.onLocaleChange,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: t.language,
            onSelected: onLocaleChange,
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('uz'), child: Text("O'zbekcha")),
              PopupMenuItem(
                value: Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
                child: Text('Ўзбекча'),
              ),
              PopupMenuItem(value: Locale('ru'), child: Text('Русский')),
            ],
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
        // TODO(Faza 1-2): tegishli xizmat ekraniga o'tish
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
