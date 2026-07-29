import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../auth/auth_controller.dart';
import 'profile_api.dart';
import 'profile_screen.dart';

/// Shaxsiy ma'lumotlar — foydalanuvchi o'z ismini o'zgartiradi.
/// Jonli avatar (yozilgan ismdan bosh harflar), qulflangan telefon qatori,
/// faqat o'zgarish bo'lganda yonadigan gradient saqlash tugmasi.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  bool _touched = false;

  String get _typed => _nameCtrl.text.trim();
  bool get _valid => _typed.length >= 2;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: ref.read(authControllerProvider).user?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_valid) {
      setState(() => _touched = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileApiProvider).updateName(_typed);
      // Auth holatini yangilab, bosh ekran salomi ham yangilansin.
      await ref.read(authControllerProvider.notifier).bootstrap();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.profileSaved)));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).user;
    final scheme = Theme.of(context).colorScheme;

    final initials = ProfileScreen.initialsOf(_typed);
    final saved = (user?.fullName ?? '').trim();
    final changed = _typed != saved;
    final showError = _touched && !_valid;

    return Scaffold(
      appBar: AppBar(title: Text(t.personalInfo)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  // ===== Jonli avatar: gradient halqa + bosh harflar =====
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.brand, AppTheme.brandDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surface,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: CircleAvatar(
                            key: ValueKey(initials),
                            radius: 42,
                            backgroundColor:
                                AppTheme.brand.withValues(alpha: 0.1),
                            child: initials.isNotEmpty
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.brand,
                                      letterSpacing: 0.5,
                                    ),
                                  )
                                : const Icon(Icons.person_rounded,
                                    size: 40, color: AppTheme.brand),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ===== Asosiy ma'lumotlar =====
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 8),
                    child: Text(
                      t.profileMainSection.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() => _touched = true),
                        decoration: InputDecoration(
                          labelText: t.profileName,
                          hintText: t.profileNameHint,
                          prefixIcon: const Icon(Icons.badge_outlined),
                          errorText: showError ? t.profileNameRequired : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== Telefon — qulflangan (login identifikatori) =====
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.phone_rounded,
                                size: 21, color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.profilePhone,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user != null
                                      ? ProfileScreen.prettyPhone(user.phone)
                                      : '—',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.lock_rounded,
                              size: 18, color: scheme.outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Nima uchun o'zgartirib bo'lmasligi haqida izoh.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15, color: scheme.outline),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            t.profilePhoneLocked,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: scheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===== Saqlash — faqat o'zgarish bo'lsa faol =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: BrandButton(
                label: t.profileSave,
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: changed && _valid ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
