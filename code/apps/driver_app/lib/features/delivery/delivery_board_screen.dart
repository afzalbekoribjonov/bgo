import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../../widgets/language_button.dart';
import '../auth/auth_controller.dart';
import 'delivery_api.dart';
import 'delivery_models.dart';

/// Haydovchi bosh ekrani — onlayn holat + yetkazib berish doskasi.
class DeliveryBoardScreen extends ConsumerStatefulWidget {
  const DeliveryBoardScreen({super.key});

  @override
  ConsumerState<DeliveryBoardScreen> createState() => _DeliveryBoardScreenState();
}

class _DeliveryBoardScreenState extends ConsumerState<DeliveryBoardScreen> {
  String? _busy;

  Future<void> _run(String orderId, Future<void> Function() action) async {
    setState(() => _busy = orderId);
    try {
      await action();
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(myDeliveriesProvider);
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final online = ref.watch(onlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName),
        actions: [
          Center(child: Text(online ? t.online : t.offline)),
          Switch(
            value: online,
            onChanged: (v) => ref.read(onlineProvider.notifier).state = v,
          ),
          const LanguageButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: t.logout,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(availableOrdersProvider);
          ref.invalidate(myDeliveriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SectionTitle(t.myDeliveriesTitle),
            _buildMyDeliveries(t),
            const SizedBox(height: 16),
            _SectionTitle(t.availableTitle),
            if (online)
              _buildAvailable(t)
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t.offlineHint,
                    style: TextStyle(color: Theme.of(context).colorScheme.outline)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyDeliveries(AppLocalizations t) {
    final async = ref.watch(myDeliveriesProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myDeliveriesProvider),
      ),
      data: (orders) {
        final active = orders
            .where((o) => o.status == 'ASSIGNED' || o.status == 'PICKED_UP')
            .toList();
        if (active.isEmpty) {
          return _emptyHint(t.noDeliveries);
        }
        return Column(children: active.map((o) => _activeCard(t, o)).toList());
      },
    );
  }

  Widget _buildAvailable(AppLocalizations t) {
    final async = ref.watch(availableOrdersProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(availableOrdersProvider),
      ),
      data: (orders) {
        if (orders.isEmpty) return _emptyHint(t.noAvailable);
        return Column(children: orders.map((o) => _availableCard(t, o)).toList());
      },
    );
  }

  Widget _availableCard(AppLocalizations t, DeliveryOrder o) {
    final busy = _busy == o.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(t, o),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => _run(o.id, () => ref.read(deliveryApiProvider).accept(o.id)),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: busy ? const _Spinner() : Text(t.accept),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeCard(AppLocalizations t, DeliveryOrder o) {
    final busy = _busy == o.id;
    final isAssigned = o.status == 'ASSIGNED';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.orderNo(o.publicNo.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isAssigned ? t.statusAssigned : t.statusPickedUp,
                  style: TextStyle(
                    color: isAssigned ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${t.deliverTo}: ${o.addressText}'),
            Text(t.priceSom(groupThousands(o.total))),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => _run(
                        o.id,
                        () => isAssigned
                            ? ref.read(deliveryApiProvider).pickup(o.id)
                            : ref.read(deliveryApiProvider).delivered(o.id),
                      ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: isAssigned ? null : Colors.green,
              ),
              child: busy
                  ? const _Spinner()
                  : Text(isAssigned ? t.markPicked : t.markDelivered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader(AppLocalizations t, DeliveryOrder o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.orderNo(o.publicNo.toString()),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${t.deliverTo}: ${o.addressText}'),
        Text(t.priceSom(groupThousands(o.total))),
      ],
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
