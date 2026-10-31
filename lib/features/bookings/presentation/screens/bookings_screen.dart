import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/booking_repository.dart';
import '../widgets/booking_row.dart';

enum _Tab { open, past }

/// Onglet Réservations : celles passées par le client, ou reçues par le
/// prestataire selon le rôle actif.
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  _Tab _tab = _Tab.open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asProvider = ref.watch(
        authControllerProvider.select((u) => u?.role == UserRole.provider));
    final source = asProvider ? receivedBookingsProvider : myBookingsProvider;
    final async = ref.watch(source);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
              child: Semantics(
                header: true,
                child: Text('Réservations', style: theme.textTheme.displaySmall),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
              child: SegmentedChoice<_Tab>(
                values: _Tab.values,
                selected: _tab,
                label: (t) => t == _Tab.open ? 'En cours' : 'Historique',
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.refresh(source.future),
                child: async.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ListView(children: [
                    ErrorState(
                        message: apiErrorMessage(e),
                        onRetry: () => ref.invalidate(source)),
                  ]),
                  data: (all) {
                    final list = all
                        .where((b) => _tab == _Tab.open ? b.isOpen : !b.isOpen)
                        .toList();
                    if (list.isEmpty) {
                      return ListView(children: [
                        const SizedBox(height: 60),
                        _tab == _Tab.open
                            ? EmptyState(
                                title: 'Aucune réservation en cours',
                                message: asProvider
                                    ? 'Quand un client vous réserve, sa demande arrive ici et vous êtes prévenu.'
                                    : 'Trouvez un prestataire et réservez-le : vous suivrez tout ici, du paiement à la fin du travail.',
                                actionLabel:
                                    asProvider ? null : 'Trouver un prestataire',
                                onAction: asProvider
                                    ? null
                                    : () => context.go(AppRoutes.search),
                              )
                            : const EmptyState(
                                title: 'Pas encore d\'historique',
                                message:
                                    'Les réservations terminées ou annulées s\'afficheront ici.',
                              ),
                      ]);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => BookingRow.divider,
                      itemBuilder: (_, i) => BookingRow(
                        booking: list[i],
                        asProvider: asProvider,
                        onTap: () => context.push(AppRoutes.booking(list[i].id)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
