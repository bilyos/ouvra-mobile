import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/booking.dart';

/// Ton d'un statut : détermine sa couleur.
enum StatusTone { neutral, action, positive, alert }

/// Libellé du statut, du point de vue de celui qui regarde.
(String, StatusTone) bookingStatus(Booking b, {required bool asProvider}) {
  if (b.escrow == EscrowStatus.disputed) {
    return ('Problème signalé', StatusTone.alert);
  }
  switch (b.status) {
    case BookingStatus.pending:
      return asProvider
          ? ('Nouvelle demande', StatusTone.action)
          : ('En attente de réponse', StatusTone.neutral);
    case BookingStatus.accepted:
      if (b.escrow == EscrowStatus.none) {
        return asProvider
            ? ('En attente du paiement', StatusTone.neutral)
            : ('Acceptée, à payer', StatusTone.action);
      }
      if (b.onTheWayAt != null) {
        return asProvider
            ? ('En route', StatusTone.positive)
            : ('Le prestataire est en route', StatusTone.positive);
      }
      return asProvider
          ? ('Payée, à réaliser', StatusTone.action)
          : ('Payée, intervention prévue', StatusTone.positive);
    case BookingStatus.inProgress:
      if (b.releaseAt != null) {
        return asProvider
            ? ('Terminé, versement prévu', StatusTone.positive)
            : ('Travail déclaré terminé', StatusTone.action);
      }
      return ('En cours', StatusTone.positive);
    case BookingStatus.completed:
      return ('Terminée', StatusTone.neutral);
    case BookingStatus.rejected:
      return ('Refusée', StatusTone.neutral);
    case BookingStatus.cancelled:
      return ('Annulée', StatusTone.neutral);
  }
}

Color statusColor(BuildContext context, StatusTone tone) {
  final p = context.palette;
  return switch (tone) {
    StatusTone.neutral => p.mutedForeground,
    StatusTone.action => p.warning,
    StatusTone.positive => p.success,
    StatusTone.alert => p.danger,
  };
}

/// Ligne de réservation : avec qui, quoi, quand, où en est-on.
class BookingRow extends StatelessWidget {
  const BookingRow({
    super.key,
    required this.booking,
    required this.asProvider,
    required this.onTap,
  });

  final Booking booking;
  final bool asProvider;
  final VoidCallback onTap;

  static const Widget divider =
      Divider(indent: AppSpacing.gutter + 44 + AppSpacing.md);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = booking;
    final who = asProvider ? b.clientName : (b.providerName ?? 'Prestataire');
    final (label, tone) = bookingStatus(b, asProvider: asProvider);
    final when = b.scheduledAt;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              name: who,
              url: asProvider ? null : b.providerAvatarUrl,
              size: 44,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(b.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(formatFcfa(b.price),
                          style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when == null ? who : '$who, ${formatShortDate(when).toLowerCase()}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                          color: statusColor(context, tone),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(label,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: statusColor(context, tone)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
