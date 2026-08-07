import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../widgets/async_error.dart';
import 'kitchen_api.dart';
import 'kitchen_models.dart';

final kitchenCategoriesProvider =
    FutureProvider.family<List<KitchenCategory>, String>((ref, restaurantId) {
  return ref.read(kitchenApiProvider).categories(restaurantId);
});

final kitchenMenuItemsProvider =
    FutureProvider.family<List<KitchenMenuItem>, String>((ref, restaurantId) {
  return ref.read(kitchenApiProvider).menuItems(restaurantId);
});

/// Menyu boshqaruvi — kategoriya + taom to'liq CRUD (qo'shish/tahrirlash/
/// o'chirish/mavjudlik belgisi), rasm yuklash.
class KitchenMenuScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const KitchenMenuScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<KitchenMenuScreen> createState() => _KitchenMenuScreenState();
}

class _KitchenMenuScreenState extends ConsumerState<KitchenMenuScreen> {
  String? _selectedCategoryId;

  void _reload() {
    ref.invalidate(kitchenCategoriesProvider(widget.restaurantId));
    ref.invalidate(kitchenMenuItemsProvider(widget.restaurantId));
  }

  Future<void> _openCategoryForm({KitchenCategory? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFormSheet(restaurantId: widget.restaurantId, existing: existing),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDeleteCategory(KitchenCategory c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyani o\'chirish'),
        content: Text('"${c.name.uz}" kategoriyasini o\'chirmoqchimisiz?'),
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
      await ref.read(kitchenApiProvider).deleteCategory(widget.restaurantId, c.id);
      if (_selectedCategoryId == c.id) setState(() => _selectedCategoryId = null);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
      );
    }
  }

  Future<void> _openItemForm(List<KitchenCategory> categories, {KitchenMenuItem? existing}) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval kategoriya qo\'shing')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MenuItemFormSheet(
        restaurantId: widget.restaurantId,
        categories: categories,
        initialCategoryId: _selectedCategoryId,
        existing: existing,
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDeleteItem(KitchenMenuItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Taomni o\'chirish'),
        content: Text('"${item.name.uz}" taomini o\'chirmoqchimisiz?'),
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
      await ref.read(kitchenApiProvider).deleteMenuItem(widget.restaurantId, item.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
      );
    }
  }

  Future<void> _toggleAvailability(KitchenMenuItem item) async {
    try {
      await ref.read(kitchenApiProvider).setAvailability(widget.restaurantId, item.id, !item.isAvailable);
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
    final catsAsync = ref.watch(kitchenCategoriesProvider(widget.restaurantId));
    final itemsAsync = ref.watch(kitchenMenuItemsProvider(widget.restaurantId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: catsAsync.maybeWhen(
        data: (cats) => FloatingActionButton.extended(
          onPressed: () => _openItemForm(cats),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Taom'),
        ),
        orElse: () => null,
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: AsyncErrorRetry(error: e, onRetry: _reload)),
        data: (categories) {
          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    _CategoryChip(
                      label: 'Hammasi',
                      selected: _selectedCategoryId == null,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onLongPress: () => _showCategoryMenu(c),
                          child: _CategoryChip(
                            label: c.name.uz,
                            selected: _selectedCategoryId == c.id,
                            onTap: () => setState(() => _selectedCategoryId = c.id),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Kategoriya'),
                        onPressed: () => _openCategoryForm(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: AsyncErrorRetry(error: e, onRetry: _reload)),
                  data: (items) {
                    final filtered = _selectedCategoryId == null
                        ? items
                        : items.where((i) => i.categoryId == _selectedCategoryId).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu_rounded, size: 56, color: scheme.outline),
                            const SizedBox(height: 12),
                            Text('Bu bo\'limda taom yo\'q', style: TextStyle(color: scheme.outline, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ItemRow(
                        item: filtered[i],
                        onEdit: () => _openItemForm(categories, existing: filtered[i]),
                        onDelete: () => _confirmDeleteItem(filtered[i]),
                        onToggle: () => _toggleAvailability(filtered[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCategoryMenu(KitchenCategory c) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Tahrirlash'), onTap: () => Navigator.pop(ctx, 'edit')),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: Theme.of(ctx).colorScheme.error),
              title: Text("O'chirish", style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit') await _openCategoryForm(existing: c);
    if (action == 'delete') await _confirmDeleteCategory(c);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(color: selected ? scheme.primary : scheme.onSurface, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final KitchenMenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  const _ItemRow({required this.item, required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                opacity: item.isAvailable ? 1 : 0.4,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(item.imageUrl!, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(scheme))
                    : _placeholder(scheme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name.uz, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${item.price} so\'m', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(value: item.isAvailable, onChanged: (_) => onToggle()),
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
        child: Icon(Icons.restaurant_rounded, color: scheme.outline),
      );
}

/// ---- Kategoriya qo'shish/tahrirlash formasi ----
class _CategoryFormSheet extends ConsumerStatefulWidget {
  final String restaurantId;
  final KitchenCategory? existing;
  const _CategoryFormSheet({required this.restaurantId, this.existing});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final _uz = TextEditingController(text: widget.existing?.name.uz ?? '');
  late final _ru = TextEditingController(text: widget.existing?.name.ru ?? '');
  late final _cyrl = TextEditingController(text: widget.existing?.name.uzCyrl ?? '');
  bool _saving = false;
  String? _err;

  @override
  void dispose() {
    _uz.dispose();
    _ru.dispose();
    _cyrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_uz.text.trim().isEmpty) {
      setState(() => _err = 'Nomni kiriting (kamida o\'zbekcha)');
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
    try {
      final api = ref.read(kitchenApiProvider);
      if (widget.existing != null) {
        await api.updateCategory(widget.restaurantId, widget.existing!.id, name: name);
      } else {
        await api.createCategory(widget.restaurantId, name);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(widget.existing != null ? 'Kategoriyani tahrirlash' : 'Yangi kategoriya', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: _uz, decoration: const InputDecoration(labelText: 'Nomi (o\'zbekcha) *')),
          const SizedBox(height: 10),
          TextField(controller: _cyrl, decoration: const InputDecoration(labelText: 'Номи (кирилча)')),
          const SizedBox(height: 10),
          TextField(controller: _ru, decoration: const InputDecoration(labelText: 'Название (русский)')),
          if (_err != null) ...[
            const SizedBox(height: 10),
            Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Saqlash'),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---- Taom qo'shish/tahrirlash formasi ----
class _MenuItemFormSheet extends ConsumerStatefulWidget {
  final String restaurantId;
  final List<KitchenCategory> categories;
  final String? initialCategoryId;
  final KitchenMenuItem? existing;
  const _MenuItemFormSheet({
    required this.restaurantId,
    required this.categories,
    this.initialCategoryId,
    this.existing,
  });

  @override
  ConsumerState<_MenuItemFormSheet> createState() => _MenuItemFormSheetState();
}

class _MenuItemFormSheetState extends ConsumerState<_MenuItemFormSheet> {
  late final _uz = TextEditingController(text: widget.existing?.name.uz ?? '');
  late final _ru = TextEditingController(text: widget.existing?.name.ru ?? '');
  late final _cyrl = TextEditingController(text: widget.existing?.name.uzCyrl ?? '');
  late final _price = TextEditingController(text: widget.existing?.price.toString() ?? '');
  late String _categoryId = widget.existing?.categoryId ?? widget.initialCategoryId ?? widget.categories.first.id;
  String? _imageUrl;
  File? _pickedFile;
  bool _saving = false;
  bool _uploading = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.existing?.imageUrl;
  }

  @override
  void dispose() {
    _uz.dispose();
    _ru.dispose();
    _cyrl.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _pickedFile = File(picked.path);
      _uploading = true;
    });
    try {
      final url = await ref.read(kitchenApiProvider).uploadImage(_pickedFile!);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
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
    try {
      final api = ref.read(kitchenApiProvider);
      if (widget.existing != null) {
        await api.updateMenuItem(widget.restaurantId, widget.existing!.id,
            categoryId: _categoryId, name: name, price: priceVal, imageUrl: _imageUrl);
      } else {
        await api.createMenuItem(widget.restaurantId, categoryId: _categoryId, name: name, price: priceVal, imageUrl: _imageUrl);
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
            Text(widget.existing != null ? 'Taomni tahrirlash' : 'Yangi taom', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: scheme.surfaceContainerHighest),
                  child: _uploading
                      ? const Center(child: CircularProgressIndicator())
                      : (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_imageUrl!, fit: BoxFit.cover))
                          : Icon(Icons.add_a_photo_rounded, color: scheme.outline),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategoriya'),
              items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.uz))).toList(),
              onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
            ),
            const SizedBox(height: 10),
            TextField(controller: _uz, decoration: const InputDecoration(labelText: 'Nomi (o\'zbekcha) *')),
            const SizedBox(height: 10),
            TextField(controller: _cyrl, decoration: const InputDecoration(labelText: 'Номи (кирилча)')),
            const SizedBox(height: 10),
            TextField(controller: _ru, decoration: const InputDecoration(labelText: 'Название (русский)')),
            const SizedBox(height: 10),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Narxi (so\'m) *'),
            ),
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
