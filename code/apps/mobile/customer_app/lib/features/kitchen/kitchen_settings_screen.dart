import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../restaurant/restaurant_api.dart';
import 'kitchen_api.dart';
import 'kitchen_home_screen.dart';
import 'kitchen_models.dart';

/// Sozlamalar — logotip, ochiq/yopiq, faqat-o'qish profil ma'lumoti.
/// (Web'dagi "chiqish" tugmasi yo'q — bu native panel, mijoz sessiyasining
/// bir qismi, alohida logout kerak emas.)
class KitchenSettingsScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final KitchenRestaurant restaurant;
  const KitchenSettingsScreen({super.key, required this.restaurantId, required this.restaurant});

  @override
  ConsumerState<KitchenSettingsScreen> createState() => _KitchenSettingsScreenState();
}

class _KitchenSettingsScreenState extends ConsumerState<KitchenSettingsScreen> {
  bool _uploading = false;
  bool _togglingOpen = false;

  Future<void> _pickAndUploadLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(kitchenApiProvider).uploadImage(File(picked.path));
      await ref.read(kitchenApiProvider).updateLogo(widget.restaurantId, url);
      ref.invalidate(kitchenRestaurantProvider(widget.restaurantId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logotip yangilandi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Rasm yuklashda xatolik')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _toggleOpen() async {
    setState(() => _togglingOpen = true);
    try {
      await ref.read(kitchenApiProvider).setOpen(widget.restaurantId, !widget.restaurant.isOpen);
      ref.invalidate(kitchenRestaurantProvider(widget.restaurantId));
      // Ochiq/yopiq holati mijoz bosh ekranidagi oshxonalar ro'yxati va
      // "Ovqat" lentasiga (isOpen filtri) ta'sir qiladi — shu ProviderContainer
      // ichida darhol yangilanishi uchun invalidatsiya qilinadi.
      ref.invalidate(restaurantsProvider);
      ref.invalidate(dishesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest,
                  image: r.logoUrl != null && r.logoUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(r.logoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: r.logoUrl == null || r.logoUrl!.isEmpty
                    ? Icon(Icons.storefront_rounded, size: 40, color: scheme.outline)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: scheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploading ? null : _pickAndUploadLogo,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _uploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.storefront_rounded, label: 'Nomi', value: r.name),
                const Divider(height: 24),
                _InfoRow(icon: Icons.place_rounded, label: 'Manzil', value: r.address.isEmpty ? '—' : r.address),
                const Divider(height: 24),
                _InfoRow(icon: Icons.star_rounded, label: 'Reyting', value: r.rating.toStringAsFixed(1)),
                const SizedBox(height: 8),
                Text('O\'zgartirish uchun administratorga murojaat qiling', style: TextStyle(fontSize: 12, color: scheme.outline)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SwitchListTile(
            value: r.isOpen,
            onChanged: _togglingOpen ? null : (_) => _toggleOpen(),
            title: const Text('Oshxona holati', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(r.isOpen ? "Ochiq — buyurtma qabul qilinmoqda" : "Yopiq — buyurtma qabul qilinmaydi"),
            secondary: Icon(r.isOpen ? Icons.storefront_rounded : Icons.storefront_outlined,
                color: r.isOpen ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.outline),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: scheme.outline, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
