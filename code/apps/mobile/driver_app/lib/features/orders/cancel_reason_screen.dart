import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class CancelReasonResult {
  final String reason;
  final String? note;
  const CancelReasonResult(this.reason, this.note);
}

class _ReasonOption {
  final String code;
  final String label;
  final IconData icon;
  const _ReasonOption(this.code, this.label, this.icon);
}

const _codesAndIcons = [
  ('VEHICLE_PROBLEM', Icons.car_repair_rounded),
  ('TOO_FAR', Icons.social_distance_rounded),
  ('CANNOT_REACH_CUSTOMER', Icons.phone_disabled_rounded),
  ('CUSTOMER_NOT_AT_ADDRESS', Icons.location_off_rounded),
  ('OTHER', Icons.more_horiz_rounded),
];

List<_ReasonOption> _reasonOptions(AppLocalizations t) {
  final labels = <String, String>{
    'VEHICLE_PROBLEM': t.cancelReasonVehicle,
    'TOO_FAR': t.cancelReasonTooFar,
    'CANNOT_REACH_CUSTOMER': t.cancelReasonCannotReach,
    'CUSTOMER_NOT_AT_ADDRESS': t.cancelReasonNotAtAddress,
    'OTHER': t.cancelReasonOther,
  };
  return [
    for (final (code, icon) in _codesAndIcons)
      _ReasonOption(code, labels[code]!, icon),
  ];
}

/// Bekor qilish sababini tanlash sahifasi — majburiy, tanlovli.
/// Natija: [CancelReasonResult] yoki null (foydalanuvchi orqaga qaytdi).
class CancelReasonScreen extends StatefulWidget {
  final bool isFood;
  const CancelReasonScreen({super.key, this.isFood = false});

  @override
  State<CancelReasonScreen> createState() => _CancelReasonScreenState();
}

class _CancelReasonScreenState extends State<CancelReasonScreen> {
  String? _selected;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selected != null && (_selected != 'OTHER' || _noteCtrl.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final reasons = _reasonOptions(t);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFood ? t.cancelReasonTitleDecline : t.cancelReasonTitleCancel),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                t.cancelReasonHint,
                style: TextStyle(color: scheme.outline, fontSize: 13.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reasons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = reasons[i];
                  final selected = _selected == r.code;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selected = r.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primaryContainer.withValues(alpha: 0.55)
                            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? scheme.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(r.icon, color: selected ? scheme.primary : scheme.outline, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              r.label,
                              style: TextStyle(
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          Icon(
                            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            color: selected ? scheme.primary : scheme.outlineVariant,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _selected == 'OTHER'
                  ? Padding(
                      key: const ValueKey('note'),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: TextField(
                        controller: _noteCtrl,
                        maxLength: 300,
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: t.cancelReasonNoteLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                  onPressed: _canSubmit
                      ? () => Navigator.pop(
                            context,
                            CancelReasonResult(
                              _selected!,
                              _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                            ),
                          )
                      : null,
                  child: Text(widget.isFood ? t.cancelReasonSubmitDecline : t.cancel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
