import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../providers/data/provider_repository.dart';
import '../../../providers/domain/service_provider.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking.dart';

/// Demande de réservation à un prestataire : quoi, quand, où, pour combien.
/// Le paiement vient après, une fois la demande acceptée.
class BookingFormScreen extends ConsumerWidget {
  const BookingFormScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(providerDetailProvider(providerId));
    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(providerDetailProvider(providerId)),
        ),
        data: (provider) => _Form(provider: provider),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.provider});
  final ServiceProvider provider;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.provider.profession);
  final _details = TextEditingController();
  final _address = TextEditingController();
  late final _price =
      TextEditingController(text: '${widget.provider.startingPrice}');
  DateTime? _when;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_title, _details, _address, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFreeDate() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: _when ?? now.add(const Duration(days: 1)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() => _when =
        DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_when == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un jour et une heure.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final booking = await ref.read(bookingRepositoryProvider).create(
            providerId: widget.provider.id,
            title: _title.text.trim(),
            description: _details.text.trim(),
            scheduledAt: _when!,
            address: _address.text.trim(),
            price: int.parse(_price.text.trim()),
            categoryId: widget.provider.categoryId.isEmpty
                ? null
                : widget.provider.categoryId,
          );
      ref.invalidate(myBookingsProvider);
      if (mounted) context.pushReplacement(AppRoutes.booking(booking.id));
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final provider = widget.provider;
    final slots = ref.watch(providerSlotsProvider(provider.id));

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
              children: [
                Row(
                  children: [
                    AppAvatar(
                        name: provider.name, url: provider.avatarUrl, size: 44),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(provider.name, style: theme.textTheme.titleMedium),
                          Text(provider.profession,
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Travail à faire',
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Dites en quelques mots ce qu\'il faut faire.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Précisions (facultatif)',
                  hint: 'Fuite sous l\'évier de la cuisine, depuis hier…',
                  controller: _details,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Quand', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                slots.when(
                  loading: () => const LoadingView(padding: AppSpacing.md),
                  error: (_, __) => _FreeDateField(
                      value: _when, onTap: _pickFreeDate),
                  data: (info) => info.hasSchedule && info.days.isNotEmpty
                      ? _SlotPicker(
                          info: info,
                          selected: _when,
                          onSelect: (d) => setState(() => _when = d),
                        )
                      : _FreeDateField(value: _when, onTap: _pickFreeDate),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Où et combien', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Adresse',
                  hint: 'Quartier, rue, repère',
                  controller: _address,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Indiquez où le prestataire doit venir.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Prix proposé (FCFA)',
                  helper:
                      'À partir de ${formatFcfa(provider.startingPrice)} chez ce prestataire. Vous en discutez s\'il le faut.',
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Indiquez un montant.';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: p.paper,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 20, color: p.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Rien à payer maintenant. Une fois la demande acceptée, vous payez par Mobile Money : Ouvra garde l\'argent jusqu\'à la fin du travail.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.border, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                  AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
              child: AppButton(
                label: 'Envoyer la demande',
                loading: _sending,
                onPressed: _submit,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Date libre quand le prestataire n'a pas publié de planning.
class _FreeDateField extends StatelessWidget {
  const _FreeDateField({required this.value, required this.onTap});
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Material(
      color: p.muted,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: AppSpacing.control,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.event_outlined, size: 20, color: p.mutedForeground),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value == null ? 'Choisir le jour et l\'heure' : formatLongDateTime(value!),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: value == null ? p.subtle : p.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Créneaux du planning : jours en ligne, heures en grille.
class _SlotPicker extends StatefulWidget {
  const _SlotPicker({
    required this.info,
    required this.selected,
    required this.onSelect,
  });

  final SlotsInfo info;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<_SlotPicker> {
  late int _day = widget.info.days.indexWhere((d) => d.slots.any((s) => s.free))
      .clamp(0, widget.info.days.length - 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final days = widget.info.days;
    final slots = days[_day].slots;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final d = days[i].date;
              final sel = i == _day;
              final full = !days[i].slots.any((s) => s.free);
              return Material(
                color: sel ? p.primary : p.muted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: () => setState(() => _day = i),
                  child: SizedBox(
                    width: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(formatShortDate(d).split(' ').first,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: sel ? p.onPrimary : p.mutedForeground)),
                        Text('${d.day}',
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: sel
                                    ? p.onPrimary
                                    : full
                                        ? p.subtle
                                        : p.ink)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!slots.any((s) => s.free))
          Text('Complet ce jour-là. Essayez un autre jour.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: p.mutedForeground))
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in slots.where((s) => s.free))
                _SlotChip(
                  time: s.start,
                  selected: widget.selected == s.start,
                  onTap: () => widget.onSelect(s.start),
                ),
            ],
          ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });
  final DateTime time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final label =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Material(
      color: selected ? p.primary : p.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(color: selected ? p.primary : p.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: 76,
          height: 40,
          alignment: Alignment.center,
          child: Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 15, color: selected ? p.onPrimary : p.ink)),
        ),
      ),
    );
  }
}
