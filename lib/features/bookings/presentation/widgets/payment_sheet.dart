import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking.dart';

/// Paiement Mobile Money d'une réservation. Renvoie `true` une fois payé.
///
/// Tant que l'opérateur n'est pas branché, le backend accepte que le payeur
/// confirme lui-même le paiement (mode simulé) : on enchaîne les deux appels.
class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  PaymentMethod _method = PaymentMethod.orangeMoney;
  late final _phone =
      TextEditingController(text: ref.read(authControllerProvider)?.phone ?? '');
  bool _paying = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_phone.text.trim().length < 8) {
      setState(() => _error = 'Saisissez le numéro du compte qui paie.');
      return;
    }
    setState(() {
      _paying = true;
      _error = null;
    });
    final repo = ref.read(bookingRepositoryProvider);
    try {
      final payment = await repo.pay(widget.booking.id,
          method: _method, phone: _phone.text.trim());
      await repo.confirmPayment(payment.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _paying = false;
          _error = apiErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final amount = widget.booking.price;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payer la réservation', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.booking.title, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Text(formatFcfa(amount), style: theme.textTheme.displaySmall),
            const SizedBox(height: AppSpacing.lg),
            for (final m in const [PaymentMethod.orangeMoney, PaymentMethod.mtnMomo])
              _MethodRow(
                method: m,
                selected: _method == m,
                onTap: () => setState(() => _method = m),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Numéro ${_method.label}',
              hint: '6 90 00 00 00',
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: p.danger)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: p.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Ouvra garde cette somme. Le prestataire ne la reçoit qu\'à la fin du travail, avec votre code.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Payer ${formatFcfa(amount)}',
              loading: _paying,
              onPressed: _pay,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    // Pastille aux couleurs de l'opérateur, pour le reconnaître d'un coup d'œil.
    final swatch = method == PaymentMethod.orangeMoney
        ? const Color(0xFFFF7900)
        : const Color(0xFFFFCB05);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text(method.label, style: theme.textTheme.bodyLarge)),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? p.primary : p.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
