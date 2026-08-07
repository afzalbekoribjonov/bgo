import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/location_service.dart';
import 'seller_home_screen.dart';
import 'seller_panel_api.dart';
import 'seller_panel_models.dart';

/// Do'kon profili — nom/tavsif/telefon/manzil + GPS orqali joylashuv.
/// (Logotip maydoni YO'Q — seller_web'da ham yo'q.)
class SellerProfileScreen extends ConsumerStatefulWidget {
  final SellerProfile profile;
  const SellerProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _description = TextEditingController(text: widget.profile.description ?? '');
  late final _phone = TextEditingController(text: widget.profile.contactPhone);
  late final _address = TextEditingController(text: widget.profile.address ?? '');
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.profile.lat;
    _lng = widget.profile.lng;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final pos = await ref.read(locationServiceProvider).currentLatLng();
      if (pos != null && mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joylashuv aniqlandi')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joylashuvni aniqlab bo\'lmadi')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomni kiriting')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(sellerPanelApiProvider).updateProfile(
            name: _name.text.trim(),
            description: _description.text.trim(),
            contactPhone: _phone.text.trim(),
            address: _address.text.trim(),
            lat: _lat,
            lng: _lng,
          );
      ref.invalidate(sellerProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil yangilandi')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: "Do'kon nomi")),
        const SizedBox(height: 12),
        TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'Tavsif')),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Aloqa telefoni')),
        const SizedBox(height: 12),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'Manzil')),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(_lat != null ? 'Joylashuv yangilandi ✓' : 'Joriy joylashuvni aniqlash'),
              ),
            ),
          ],
        ),
        if (_lat != null && _lng != null) ...[
          const SizedBox(height: 6),
          Text('📍 ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}', style: TextStyle(color: scheme.outline, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Text('Joylashuv kiritilsa — mijozlarga eng yaqin do\'kon sifatida birinchi ko\'rsatiladi.', style: TextStyle(color: scheme.outline, fontSize: 12)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Saqlash'),
          ),
        ),
      ],
    );
  }
}
