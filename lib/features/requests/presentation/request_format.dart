import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/utils/format.dart';
import '../../bookings/presentation/widgets/booking_row.dart';
import '../../home/data/mock_categories.dart';
import '../domain/job_request.dart';

/// « 15 000 FCFA », « À partir de 15 000 FCFA », « Environ 15 000 FCFA ».
String quotePriceText(int price, PriceKind kind) => switch (kind) {
      PriceKind.fixed => formatFcfa(price),
      PriceKind.from => 'À partir de ${formatFcfa(price)}',
      PriceKind.afterVisit => 'Environ ${formatFcfa(price)}',
    };

/// « aujourd'hui à 9 h », « demain à 14 h 30 », « jeudi 24 à 8 h ».
String whenText(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(t.year, t.month, t.day).difference(today).inDays;
  final time = t.minute == 0
      ? '${t.hour} h'
      : '${t.hour} h ${t.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return 'aujourd\'hui à $time';
  if (diff == 1) return 'demain à $time';
  return '${DateFormat('EEEE d', 'fr').format(t)} à $time';
}

/// « à l'instant », « il y a 12 min », « il y a 3 h », « il y a 2 j ».
String agoText(DateTime t) {
  final minutes = DateTime.now().difference(t).inMinutes;
  if (minutes < 1) return 'à l\'instant';
  if (minutes < 60) return 'il y a $minutes min';
  final hours = (minutes / 60).round();
  if (hours < 24) return 'il y a $hours h';
  return 'il y a ${(hours / 24).round()} j';
}

/// « encore 2 h », « encore 3 j » ; `null` une fois l'échéance passée.
String? remainingText(DateTime t) {
  final minutes = t.difference(DateTime.now()).inMinutes;
  if (minutes <= 0) return null;
  if (minutes < 60) return 'encore $minutes min';
  final hours = minutes ~/ 60;
  if (hours < 24) return 'encore $hours h';
  return 'encore ${(hours / 24).round()} j';
}

/// « à 3,5 km ».
String? kmText(double? km) =>
    km == null ? null : 'à ${formatDistance(km < 0.5 ? 0.5 : km)}';

String categoryLabel(String id) =>
    kMockCategories.where((c) => c.id == id).firstOrNull?.label ?? id;

IconData categoryIcon(String id) =>
    kMockCategories.where((c) => c.id == id).firstOrNull?.icon ??
    Icons.handyman_outlined;

/// Libellé et ton d'une demande, vue par son auteur.
(String, StatusTone) requestStatus(JobRequest r) => switch (r.status) {
      RequestStatus.open => r.quoteCount == 0
          ? ('En ligne, en attente de devis', StatusTone.neutral)
          : (
              '${r.quoteCount} devis reçu${r.quoteCount > 1 ? 's' : ''}',
              StatusTone.action
            ),
      RequestStatus.assigned => ('Prestataire choisi', StatusTone.positive),
      RequestStatus.expired => ('Expirée sans choix', StatusTone.neutral),
      RequestStatus.cancelled => ('Retirée', StatusTone.neutral),
    };

/// Libellé et ton d'un devis, vu par le prestataire qui l'a envoyé.
(String, StatusTone) quoteStatus(QuoteStatus s) => switch (s) {
      QuoteStatus.sent => ('En attente du client', StatusTone.neutral),
      QuoteStatus.accepted => ('Accepté', StatusTone.positive),
      QuoteStatus.declined => ('Non retenu', StatusTone.neutral),
      QuoteStatus.withdrawn => ('Retiré', StatusTone.neutral),
      QuoteStatus.expired => ('Expiré', StatusTone.neutral),
    };

/// Petit point de couleur suivi du libellé, comme dans les réservations.
class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 7,
          width: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
