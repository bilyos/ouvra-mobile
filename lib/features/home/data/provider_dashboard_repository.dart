import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Chiffres de l'espace prestataire.
class ProviderStats {
  const ProviderStats({
    required this.contacts,
    required this.ratingAvg,
    required this.reviewCount,
  });

  final int contacts;
  final double ratingAvg;
  final int reviewCount;
}

/// Statistiques du prestataire connecté (`GET /me/provider-stats`).
final providerStatsProvider =
    FutureProvider.autoDispose<ProviderStats>((ref) async {
  final res = await ref.watch(dioProvider).get('/me/provider-stats');
  final d = res.data as Map<String, dynamic>;
  return ProviderStats(
    contacts: (d['contacts'] as num?)?.toInt() ?? 0,
    ratingAvg: (d['ratingAvg'] as num?)?.toDouble() ?? 0,
    reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
  );
});

/// Solde du portefeuille, en FCFA (`GET /wallet`).
final walletBalanceProvider = FutureProvider.autoDispose<int>((ref) async {
  final res = await ref.watch(dioProvider).get('/wallet');
  return ((res.data as Map<String, dynamic>)['balance'] as num?)?.toInt() ?? 0;
});
