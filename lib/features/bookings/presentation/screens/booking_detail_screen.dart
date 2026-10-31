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
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/app_user.dart';
import '../../../chat/data/chat_repository.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking.dart';
import '../widgets/booking_row.dart';
import '../widgets/completion_code.dart';
import '../widgets/payment_sheet.dart';

/// Détail d'une réservation et de son argent. Les actions proposées dépendent
/// du rôle (client ou prestataire) et de l'étape.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;

  BookingRepository get _repo => ref.read(bookingRepositoryProvider);

  void _refresh() {
    ref.invalidate(bookingDetailProvider(widget.bookingId));
    ref.invalidate(myBookingsProvider);
    ref.invalidate(receivedBookingsProvider);
  }

  /// Lance une action, affiche l'erreur de l'API s'il y en a une, recharge.
  Future<void> _run(Future<Object?> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
      if (mounted && done != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, String action,
      {bool destructive = false}) async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: destructive ? p.danger : p.primary),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<String?> _askText({
    required String title,
    required String label,
    required String action,
    String? hint,
    bool numeric = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TextSheet(
        title: title,
        label: label,
        action: action,
        hint: hint,
        numeric: numeric,
      ),
    );
  }

  // ── Actions client ──

  Future<void> _pay(Booking b) async {
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentSheet(booking: b),
    );
    if (paid == true) {
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Paiement reçu. L\'argent est bloqué chez Ouvra.')));
      }
    }
  }

  Future<void> _confirmDone(Booking b) async {
    if (!await _confirm(
        'Le travail est terminé ?',
        '${formatFcfa(b.price)} seront versés tout de suite au prestataire. Vous ne pourrez plus signaler de problème.',
        'Oui, verser')) {
      return;
    }
    await _run(() => _repo.confirmCompletion(b.id),
        done: 'Merci. Le prestataire a été payé.');
  }

  Future<void> _dispute(Booking b) async {
    final reason = await _askText(
      title: 'Signaler un problème',
      label: 'Que s\'est-il passé ?',
      hint: 'Le travail n\'est pas fini, la fuite continue…',
      action: 'Envoyer le signalement',
    );
    if (reason == null || reason.trim().isEmpty) return;
    await _run(() => _repo.dispute(b.id, reason.trim()),
        done: 'Signalement envoyé. L\'argent reste bloqué.');
  }

  Future<void> _cancel(Booking b) async {
    if (!await _confirm(
        'Annuler la réservation ?',
        b.escrow == EscrowStatus.held
            ? 'Vous serez remboursé sur votre compte Mobile Money.'
            : 'Le prestataire sera prévenu.',
        'Annuler la réservation',
        destructive: true)) {
      return;
    }
    await _run(() => _repo.cancel(b.id), done: 'Réservation annulée.');
  }

  Future<void> _message(Booking b) async {
    final id = b.providerId;
    if (id == null) return;
    try {
      final conv = await ref.read(chatRepositoryProvider).start(id);
      if (mounted) {
        context.push(AppRoutes.chat(conv.id), extra: {
          'name': b.providerName,
          'avatarUrl': b.providerAvatarUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  // ── Actions prestataire ──

  Future<void> _complete(Booking b) async {
    final code = await _askText(
      title: 'Terminer avec le code',
      label: 'Code du client',
      hint: '4 chiffres',
      action: 'Valider et être payé',
      numeric: true,
    );
    if (code == null || code.trim().isEmpty) return;
    await _run(() => _repo.completeWithCode(b.id, code.trim()),
        done: 'Travail terminé. ${formatFcfa(b.price)} arrivent sur votre solde.');
  }

  Future<void> _markDone(Booking b) async {
    if (!await _confirm(
        'Déclarer terminé sans code ?',
        'Le client a 48 heures pour signaler un problème. Sans signalement, vous êtes payé automatiquement.',
        'Déclarer terminé')) {
      return;
    }
    await _run(() => _repo.markDone(b.id),
        done: 'C\'est noté. Versement sous 48 heures.');
  }

  Future<void> _reject(Booking b) async {
    if (!await _confirm('Refuser cette demande ?',
        'Le client sera prévenu et pourra réserver quelqu\'un d\'autre.', 'Refuser',
        destructive: true)) {
      return;
    }
    await _run(() => _repo.setStatus(b.id, 'REJECTED'), done: 'Demande refusée.');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingDetailProvider(widget.bookingId));
    final asProvider = ref.watch(
        authControllerProvider.select((u) => u?.role == UserRole.provider));

    return Scaffold(
      appBar: AppBar(title: const Text('Réservation')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(
          message: apiErrorMessage(e),
          onRetry: () =>
              ref.invalidate(bookingDetailProvider(widget.bookingId)),
        ),
        data: (b) => RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(bookingDetailProvider(widget.bookingId).future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _Summary(booking: b, asProvider: asProvider),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: AppSpacing.screen,
                child: asProvider
                    ? _ProviderMoney(
                        booking: b,
                        busy: _busy,
                        onAccept: () => _run(
                            () => _repo.setStatus(b.id, 'ACCEPTED'),
                            done: 'Demande acceptée. Le client va payer.'),
                        onReject: () => _reject(b),
                        onTheWay: () => _run(() => _repo.onTheWay(b.id),
                            done: 'Le client sait que vous arrivez.'),
                        onStart: () => _run(
                            () => _repo.setStatus(b.id, 'IN_PROGRESS'),
                            done: 'Travail commencé.'),
                        onComplete: () => _complete(b),
                        onMarkDone: () => _markDone(b),
                      )
                    : _ClientMoney(
                        booking: b,
                        busy: _busy,
                        onPay: () => _pay(b),
                        onConfirmDone: () => _confirmDone(b),
                        onDispute: () => _dispute(b),
                      ),
              ),
              _Details(booking: b, asProvider: asProvider),
              _Timeline(booking: b),
              if (!asProvider && b.providerId != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: AppSpacing.screen,
                  child: AppButton(
                    label: 'Écrire au prestataire',
                    icon: Icons.chat_bubble_outline_rounded,
                    variant: AppButtonVariant.tonal,
                    onPressed: () => _message(b),
                  ),
                ),
              ],
              if (!asProvider && _clientCanCancel(b)) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: AppSpacing.screen,
                  child: TextButton(
                    onPressed: _busy ? null : () => _cancel(b),
                    style: TextButton.styleFrom(
                        foregroundColor: context.palette.danger),
                    child: const Text('Annuler la réservation'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _clientCanCancel(Booking b) =>
      b.status == BookingStatus.pending ||
      (b.status == BookingStatus.accepted && b.escrow != EscrowStatus.disputed);
}

// ─── Résumé ─────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  const _Summary({required this.booking, required this.asProvider});
  final Booking booking;
  final bool asProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = booking;
    final (label, tone) = bookingStatus(b, asProvider: asProvider);
    final who = asProvider ? b.clientName : (b.providerName ?? 'Prestataire');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: statusColor(context, tone))),
          const SizedBox(height: AppSpacing.xs),
          Text(b.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppAvatar(
                  name: who,
                  url: asProvider ? null : b.providerAvatarUrl,
                  size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(who, style: theme.textTheme.titleSmall),
                    if (!asProvider && b.providerProfession != null)
                      Text(b.providerProfession!,
                          style: theme.textTheme.bodySmall),
                    if (asProvider)
                      Text('Client', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bloc argent : client ───────────────────────────────────────────────

class _MoneyBlock extends StatelessWidget {
  const _MoneyBlock({
    required this.caption,
    required this.amount,
    required this.body,
    this.tone = _MoneyTone.neutral,
    this.extra = const [],
  });

  final String caption;
  final int amount;
  final String body;
  final _MoneyTone tone;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      _MoneyTone.held => (p.primarySoft, p.primary),
      _MoneyTone.alert => (p.dangerSoft, p.danger),
      _MoneyTone.neutral => (p.paper, p.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (tone == _MoneyTone.held) ...[
                Icon(Icons.lock_rounded, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(caption,
                  style: theme.textTheme.labelMedium?.copyWith(color: fg)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(formatFcfa(amount), style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: theme.textTheme.bodyMedium),
          ...extra,
        ],
      ),
    );
  }
}

enum _MoneyTone { neutral, held, alert }

class _ClientMoney extends StatelessWidget {
  const _ClientMoney({
    required this.booking,
    required this.busy,
    required this.onPay,
    required this.onConfirmDone,
    required this.onDispute,
  });

  final Booking booking;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onConfirmDone;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = booking;
    const gap = SizedBox(height: AppSpacing.lg);

    switch (b.escrow) {
      case EscrowStatus.disputed:
        return _MoneyBlock(
          caption: 'Problème signalé',
          amount: b.price,
          tone: _MoneyTone.alert,
          body:
              'L\'équipe Ouvra examine votre signalement. L\'argent reste bloqué tant qu\'aucune décision n\'est prise.',
        );
      case EscrowStatus.released:
        return _MoneyBlock(
          caption: 'Versé au prestataire',
          amount: b.price,
          body: b.completedAt == null
              ? 'Le travail est terminé et payé.'
              : 'Travail terminé et payé le ${formatShortDate(b.completedAt!).toLowerCase()}.',
        );
      case EscrowStatus.refunded:
        return _MoneyBlock(
          caption: 'Remboursé',
          amount: b.price,
          body: 'La somme a été rendue sur votre compte Mobile Money.',
        );
      case EscrowStatus.held:
        final declared = b.releaseAt != null;
        return _MoneyBlock(
          caption: 'Bloqué chez Ouvra',
          amount: b.price,
          tone: _MoneyTone.held,
          body: declared
              ? 'Le prestataire a déclaré le travail terminé. Il sera payé ${formatLongDateTime(b.releaseAt!).toLowerCase()}, sauf si vous signalez un problème.'
              : 'Le prestataire est payé quand vous lui donnez ce code, une fois le travail fini. Ne le donnez pas avant.',
          extra: [
            if (!declared && b.completionCode != null) ...[
              gap,
              Center(child: CompletionCodePlate(code: b.completionCode!)),
            ],
            gap,
            AppButton(
              label: 'Le travail est terminé',
              variant: AppButtonVariant.secondary,
              loading: busy,
              onPressed: onConfirmDone,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Signaler un problème',
              variant: AppButtonVariant.plain,
              onPressed: busy ? null : onDispute,
            ),
          ],
        );
      case EscrowStatus.none:
        if (b.status == BookingStatus.accepted) {
          return _MoneyBlock(
            caption: 'À payer pour confirmer',
            amount: b.price,
            body:
                'Le prestataire a accepté. Payez par Mobile Money : Ouvra garde l\'argent et ne le verse qu\'une fois le travail fait.',
            extra: [
              gap,
              AppButton(
                label: 'Payer ${formatFcfa(b.price)}',
                loading: busy,
                onPressed: onPay,
              ),
            ],
          );
        }
        if (b.status == BookingStatus.pending) {
          return _MoneyBlock(
            caption: 'Rien à payer pour l\'instant',
            amount: b.price,
            body:
                'Vous paierez une fois que le prestataire aura accepté. Vous recevrez une notification.',
          );
        }
        return Text(
          b.cancelReason == null || b.cancelReason!.isEmpty
              ? 'Aucun paiement n\'a été fait pour cette réservation.'
              : 'Motif : ${b.cancelReason}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: context.palette.mutedForeground),
        );
    }
  }
}

// ─── Bloc argent : prestataire ──────────────────────────────────────────

class _ProviderMoney extends StatelessWidget {
  const _ProviderMoney({
    required this.booking,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onTheWay,
    required this.onStart,
    required this.onComplete,
    required this.onMarkDone,
  });

  final Booking booking;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTheWay;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    const gap = SizedBox(height: AppSpacing.lg);
    const small = SizedBox(height: AppSpacing.sm);

    if (b.escrow == EscrowStatus.disputed) {
      return _MoneyBlock(
        caption: 'Problème signalé par le client',
        amount: b.price,
        tone: _MoneyTone.alert,
        body: b.disputeReason == null
            ? 'L\'équipe Ouvra examine la situation et vous contactera.'
            : '« ${b.disputeReason} ». L\'équipe Ouvra examine la situation et vous contactera.',
      );
    }
    if (b.escrow == EscrowStatus.released) {
      return _MoneyBlock(
        caption: 'Versé sur votre solde',
        amount: b.price,
        body: 'Travail terminé et payé.',
      );
    }
    switch (b.status) {
      case BookingStatus.pending:
        return _MoneyBlock(
          caption: 'Nouvelle demande',
          amount: b.price,
          body:
              'Si vous acceptez, le client paie et l\'argent est bloqué chez Ouvra jusqu\'à la fin du travail.',
          extra: [
            gap,
            AppButton(label: 'Accepter', loading: busy, onPressed: onAccept),
            small,
            AppButton(
              label: 'Refuser',
              variant: AppButtonVariant.plain,
              onPressed: busy ? null : onReject,
            ),
          ],
        );
      case BookingStatus.accepted || BookingStatus.inProgress:
        if (b.escrow == EscrowStatus.none) {
          return _MoneyBlock(
            caption: 'En attente du paiement',
            amount: b.price,
            body:
                'Le client a été prévenu. Attendez que le paiement soit bloqué avant de vous déplacer.',
          );
        }
        final declared = b.releaseAt != null;
        return _MoneyBlock(
          caption: 'Payé, bloqué chez Ouvra',
          amount: b.price,
          tone: _MoneyTone.held,
          body: declared
              ? 'Versement automatique ${formatLongDateTime(b.releaseAt!).toLowerCase()}, sauf signalement du client.'
              : 'À la fin, demandez son code au client et saisissez-le : vous êtes payé tout de suite.',
          extra: declared
              ? const []
              : [
                  gap,
                  AppButton(
                    label: 'Saisir le code du client',
                    loading: busy,
                    onPressed: onComplete,
                  ),
                  small,
                  if (b.status == BookingStatus.accepted &&
                      b.onTheWayAt == null) ...[
                    AppButton(
                      label: 'Je suis en route',
                      variant: AppButtonVariant.secondary,
                      onPressed: busy ? null : onTheWay,
                    ),
                    small,
                  ],
                  if (b.status == BookingStatus.accepted) ...[
                    AppButton(
                      label: 'Commencer le travail',
                      variant: AppButtonVariant.tonal,
                      onPressed: busy ? null : onStart,
                    ),
                    small,
                  ],
                  AppButton(
                    label: 'Le client n\'a pas son code',
                    variant: AppButtonVariant.plain,
                    onPressed: busy ? null : onMarkDone,
                  ),
                ],
        );
      case BookingStatus.completed ||
            BookingStatus.rejected ||
            BookingStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}

// ─── Détails et suivi ───────────────────────────────────────────────────

class _Details extends StatelessWidget {
  const _Details({required this.booking, required this.asProvider});
  final Booking booking;
  final bool asProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final b = booking;
    final rows = <(IconData, String, String)>[
      if (b.scheduledAt != null)
        (Icons.event_outlined, 'Quand', formatLongDateTime(b.scheduledAt!)),
      if (b.address.isNotEmpty) (Icons.place_outlined, 'Où', b.address),
      (Icons.payments_outlined, 'Prix convenu', formatFcfa(b.price)),
      if (b.description.isNotEmpty)
        (Icons.notes_rounded, 'Précisions', b.description),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Détails', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final (icon, label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: p.mutedForeground),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(value, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Suivi : les étapes franchies, dans l'ordre.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final b = booking;
    final paid = b.escrow != EscrowStatus.none;
    final finished = b.status == BookingStatus.completed ||
        b.escrow == EscrowStatus.released;
    final steps = <(String, DateTime?, bool)>[
      ('Demande envoyée', b.createdAt, true),
      ('Acceptée', b.acceptedAt,
          b.acceptedAt != null || b.status != BookingStatus.pending && !_stopped(b)),
      ('Payée, argent bloqué', null, paid),
      ('Prestataire en route', b.onTheWayAt, b.onTheWayAt != null),
      ('Terminée', b.completedAt, finished),
    ];
    if (_stopped(b)) {
      steps
        ..removeRange(1, steps.length)
        ..add((
          b.status == BookingStatus.rejected ? 'Refusée' : 'Annulée',
          null,
          true
        ));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suivi', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: steps[i].$3 ? p.primary : p.background,
                            border: Border.all(
                                color: steps[i].$3 ? p.primary : p.border,
                                width: 1.5),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: steps[i + 1].$3 ? p.primary : p.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(steps[i].$1,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: steps[i].$3 ? p.ink : p.subtle)),
                          ),
                          if (steps[i].$2 != null)
                            Text(formatListTime(steps[i].$2!),
                                style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _stopped(Booking b) =>
      b.status == BookingStatus.rejected || b.status == BookingStatus.cancelled;
}

// ─── Feuille de saisie ──────────────────────────────────────────────────

class _TextSheet extends StatefulWidget {
  const _TextSheet({
    required this.title,
    required this.label,
    required this.action,
    this.hint,
    this.numeric = false,
  });

  final String title;
  final String label;
  final String action;
  final String? hint;
  final bool numeric;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: widget.label,
            hint: widget.hint,
            controller: _c,
            autofocus: true,
            maxLines: widget.numeric ? 1 : 4,
            keyboardType:
                widget.numeric ? TextInputType.number : TextInputType.multiline,
            inputFormatters:
                widget.numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.action,
            onPressed: () => Navigator.pop(context, _c.text),
          ),
        ],
      ),
    );
  }
}
