import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../widgets/async_error.dart';
import 'seller_panel_api.dart';
import 'seller_panel_models.dart';

final sellerProductsProvider = FutureProvider<List<SellerProduct>>((ref) {
  return ref.read(sellerPanelApiProvider).products();
});

final sellerCategoriesProvider = FutureProvider.family<List<SellerCategory>, String>((ref, sellerType) {
  return ref.read(sellerPanelApiProvider).categories(sellerType);
});

/// Mahsulot boshqaruvi — to'liq CRUD (qo'shish/tahrirlash/o'chirish/faol-nofaol),
/// rasm yuklash, o'lchamlar. Zaxira (stock) maydoni YO'Q — seller_web'da ham yo'q.
class SellerProductsScreen extends ConsumerStatefulWidget {
  final String sellerType;
  const SellerProductsScreen({super.key, required this.sellerType});

  @override
  ConsumerState<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  void _reload() => ref.invalidate(sellerProductsProvider);

  Future<void> _openForm({SellerProduct? existing}) async {
    final categories = await ref.read(sellerCategoriesProvider(widget.sellerType).future).catchError((_) => <SellerCategory>[]);
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductFormSheet(categories: categories, existing: existing),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(SellerProduct p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mahsulotni o\'chirish'),
        content: Text('"${p.name.uz}" mahsulotini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(sellerPanelApiProvider).deleteProduct(p.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
      );
    }
  }

  Future<void> _toggleActive(SellerProduct p) async {
    try {
      await ref.read(sellerPanelApiProvider).updateProduct(p.id, isActive: !p.isActive);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sellerProductsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Mahsulot'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: AsyncErrorRetry(error: e, onRetry: _reload)),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text('Hozircha mahsulot yo\'q', style: TextStyle(color: scheme.outline, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ProductRow(
                product: products[i],
                onEdit: () => _openForm(existing: products[i]),
                onDelete: () => _confirmDelete(products[i]),
                onToggle: () => _toggleActive(products[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final SellerProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  const _ProductRow({required this.product, required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final img = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: product.isActive ? 1 : 0.4,
                child: img != null
                    ? Image.network(img, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(scheme))
                    : _placeholder(scheme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name.uz, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${product.price} so\'m', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  if (product.sizes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(product.sizes.join(', '), style: TextStyle(color: scheme.outline, fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(value: product.isActive, onChanged: (_) => onToggle()),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_rounded, size: 19), onPressed: onEdit, visualDensity: VisualDensity.compact),
                    IconButton(icon: Icon(Icons.delete_rounded, size: 19, color: scheme.error), onPressed: onDelete, visualDensity: VisualDensity.compact),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
        width: 64,
        height: 64,
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.shopping_bag_rounded, color: scheme.outline),
      );
}

class _ProductFormSheet extends ConsumerStatefulWidget {
  final List<SellerCategory> categories;
  final SellerProduct? existing;
  const _ProductFormSheet({required this.categories, this.existing});

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  late final _uz = TextEditingController(text: widget.existing?.name.uz ?? '');
  late final _ru = TextEditingController(text: widget.existing?.name.ru ?? '');
  late final _cyrl = TextEditingController(text: widget.existing?.name.uzCyrl ?? '');
  late final _price = TextEditingController(text: widget.existing?.price.toString() ?? '');
  late final _sizes = TextEditingController(text: widget.existing?.sizes.join(', ') ?? '');
  String? _categoryId;
  final List<String> _imageUrls = [];
  bool _saving = false;
  bool _uploading = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId;
    if (widget.existing != null) _imageUrls.addAll(widget.existing!.imageUrls);
  }

  @override
  void dispose() {
    _uz.dispose();
    _ru.dispose();
    _cyrl.dispose();
    _price.dispose();
    _sizes.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(sellerPanelApiProvider).uploadImage(File(picked.path));
      if (mounted) setState(() => _imageUrls.add(url));
    } catch (_) {
      if (mounted) setState(() => _err = 'Rasm yuklashda xatolik');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final priceVal = int.tryParse(_price.text.trim());
    if (_uz.text.trim().isEmpty) {
      setState(() => _err = 'Nomni kiriting (kamida o\'zbekcha)');
      return;
    }
    if (priceVal == null || priceVal <= 0) {
      setState(() => _err = 'Narxni to\'g\'ri kiriting');
      return;
    }
    setState(() {
      _saving = true;
      _err = null;
    });
    final name = I18nText(
      uz: _uz.text.trim(),
      ru: _ru.text.trim().isEmpty ? null : _ru.text.trim(),
      uzCyrl: _cyrl.text.trim().isEmpty ? null : _cyrl.text.trim(),
    );
    final sizes = _sizes.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    try {
      final api = ref.read(sellerPanelApiProvider);
      if (widget.existing != null) {
        await api.updateProduct(
          widget.existing!.id,
          categoryId: _categoryId,
          name: name,
          price: priceVal,
          imageUrls: _imageUrls,
          sizes: sizes,
        );
      } else {
        await api.createProduct(categoryId: _categoryId, name: name, price: priceVal, imageUrls: _imageUrls, sizes: sizes);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _err = isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(widget.existing != null ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageUrls.map((url) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrls.remove(url)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  GestureDetector(
                    onTap: _uploading ? null : _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: scheme.surfaceContainerHighest),
                      child: _uploading
                          ? const Center(child: CircularProgressIndicator())
                          : Icon(Icons.add_a_photo_rounded, color: scheme.outline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.categories.isNotEmpty)
              DropdownButtonFormField<String?>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategoriya'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Kategoriyasiz')),
                  ...widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            const SizedBox(height: 10),
            TextField(controller: _uz, decoration: const InputDecoration(labelText: 'Nomi (o\'zbekcha) *')),
            const SizedBox(height: 10),
            TextField(controller: _cyrl, decoration: const InputDecoration(labelText: 'Номи (кирилча)')),
            const SizedBox(height: 10),
            TextField(controller: _ru, decoration: const InputDecoration(labelText: 'Название (русский)')),
            const SizedBox(height: 10),
            TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Narxi (so\'m) *')),
            const SizedBox(height: 10),
            TextField(controller: _sizes, decoration: const InputDecoration(labelText: 'O\'lchamlar (vergul bilan, ixtiyoriy)', hintText: 'masalan: S, M, L')),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!, style: TextStyle(color: scheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_saving || _uploading) ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
