import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/choice_pill.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../data/request_repository.dart';
import '../../domain/job_request.dart';
import '../request_format.dart';

/// Même règle que le serveur : pas de numéro, d'e-mail ni de WhatsApp dans un
/// devis. Les coordonnées s'échangent une fois la réservation payée, pour que
/// le paiement reste protégé.
final _phone = RegExp(
    r'(?<!\d)(?:(?:\+|00)\s*)?(?:237[\s.\-]*)?[62](?:[\s.\-]?\d){8}(?!\d)');
final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
final _words = RegExp(
    r'whats\s*app|wh?ats?ap+|wtsp|wa\.me|appel+e[\s-]*moi|call\s*me|mon\s*num[ée]ro|my\s*number',
    caseSensitive: false);

bool containsContact(String text) {
  // « 6 9O 12… » : un O au milieu de chiffres compte comme un zéro
  final t = text.replaceAllMapped(
      RegExp(r'(?<=\d[\s.\-]?)[oO](?=[\s.\-]?\d)'), (_) => '0');
  return _phone.hasMatch(t) || _email.hasMatch(t) || _words.hasMatch(t);
}

const _hours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

/// Ouvre le formulaire de devis ; renvoie le devis envoyé.
Future<Quote?> showQuoteForm(BuildContext context, JobRequest request) =>
    showModalBottomSheet<Quote>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _QuoteForm(request: request),
    );

class _QuoteForm extends ConsumerStatefulWidget {
  const _QuoteForm({required this.request});
  final JobRequest request;

  @override
  ConsumerState<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends ConsumerState<_QuoteForm> {
  final _price = TextEditingController();
  final _message = TextEditingController();
  PriceKind _kind = PriceKind.fixed;
  late int _day = widget.request.timing == RequestTiming.now ? 0 : 1;
  int? _hour;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.request.timing == RequestTiming.now) {
      final next = DateTime.now().hour + 1;
      _hour = _hours.contains(next) ? next : null;
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _message.dispose();
    super.dispose();
  }

  DateTime _dayAt(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  bool _hourPast(int h) =>
      _day == 0 && h <= DateTime.now().hour;

  String _dayLabel(int offset) => switch (offset) {
        0 => 'Aujourd\'hui',
        1 => 'Demain',
        _ => formatShortDate(_dayAt(offset)),
      };

  Future<void> _send() async {
    final price = int.tryParse(_price.text.trim());
    if (price == null || price < 500) {
      return setState(() => _error = 'Indiquez un prix d\'au moins 500 FCFA.');
    }
    if (_hour == null || _hourPast(_hour!)) {
      return setState(
          () => _error = 'Choisissez quand vous pouvez passer.');
    }
    if (containsContact(_message.text)) {
      return setState(() => _error =
          'Retirez le numéro ou le contact du message : ils s\'échangent une fois la réservation payée.');
    }
    final day = _dayAt(_day);
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      final message = _message.text.trim();
      final quote = await ref.read(requestRepositoryProvider).sendQuote(
            widget.request.id,
            price: price,
            priceKind: _kind,
            message: message.isEmpty ? null : message,
            availableAt: DateTime(day.year, day.month, day.day, _hour!),
          );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, quote);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = apiErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final r = widget.request;
    final contact = containsContact(_message.text);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre devis', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              r.budgetMax == null
                  ? 'Pour « ${r.title} ». Le client compare jusqu\'à ${r.maxQuotes} prix.'
                  : 'Pour « ${r.title} ». Budget annoncé : ${formatFcfa(r.budgetMax!)} au plus.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Prix (FCFA)',
              hint: '15000',
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedChoice<PriceKind>(
              values: PriceKind.values,
              selected: _kind,
              label: (k) => k.label,
              onChanged: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(_kind.hint, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            Text('Quand pouvez-vous passer ?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var d = 0; d < 4; d++)
                  ChoicePill(
                    label: _dayLabel(d),
                    selected: _day == d,
                    onTap: () => setState(() {
                      _day = d;
                      if (_hour != null && _hourPast(_hour!)) _hour = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final h in _hours)
                  if (!_hourPast(h))
                    ChoicePill(
                      label: '$h h',
                      selected: _hour == h,
                      onTap: () => setState(() => _hour = h),
                    ),
              ],
            ),
            if (_day == 0 && _hours.every(_hourPast))
              Text('Trop tard pour aujourd\'hui : choisissez un autre jour.',
                  style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Message (facultatif)',
              hint: 'Ce que vous allez faire, les pièces comprises…',
              controller: _message,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            if (contact)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Pas de numéro ni de WhatsApp ici : le client vous contactera via Ouvra, et votre paiement reste garanti.',
                  style: theme.textTheme.bodySmall?.copyWith(color: p.warning),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(_error!,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: p.danger)),
              ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _price.text.isEmpty
                  ? 'Envoyer le devis'
                  : 'Envoyer : ${quotePriceText(int.tryParse(_price.text) ?? 0, _kind)}',
              loading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
