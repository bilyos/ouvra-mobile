import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/request_repository.dart';
import '../../domain/job_request.dart';
import '../request_format.dart';
import 'my_requests_screen.dart';

enum _Tab { pending, accepted, other }

/// Les devis envoyés par le prestataire, et ce que les clients en ont fait.
class MyQuotesScreen extends ConsumerStatefulWidget {
  const MyQuotesScreen({super.key});

  @override
  ConsumerState<MyQuotesScreen> createState() => _MyQuotesScreenState();
}

class _MyQuotesScreenState extends ConsumerState<MyQuotesScreen> {
  _Tab _tab = _Tab.pending;

  bool _inTab(Quote q) => switch (_tab) {
        _Tab.pending => q.status == QuoteStatus.sent,
        _Tab.accepted => q.status == QuoteStatus.accepted,
        _Tab.other => q.status != QuoteStatus.sent &&
            q.status != QuoteStatus.accepted,
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myQuotesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes devis')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.sm),
            child: SegmentedChoice<_Tab>(
              values: _Tab.values,
              selected: _tab,
              label: (t) => switch (t) {
                _Tab.pending => 'En attente',
                _Tab.accepted => 'Acceptés',
                _Tab.other => 'Non retenus',
              },
              onChanged: (t) => setState(() => _tab = t),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(myQuotesProvider.future),
              child: async.when(
                loading: () => const LoadingView(),
                error: (e, _) => ListView(children: [
                  ErrorState(
                      message: apiErrorMessage(e),
                      onRetry: () => ref.invalidate(myQuotesProvider)),
                ]),
                data: (all) {
                  final list = all.where(_inTab).toList();
                  if (list.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 60),
                      EmptyState(
                        title: switch (_tab) {
                          _Tab.pending => 'Aucun devis en attente',
                          _Tab.accepted => 'Aucun devis accepté pour l\'instant',
                          _Tab.other => 'Rien ici',
                        },
                        message: _tab == _Tab.pending
                            ? 'Chiffrez les demandes publiées près de chez vous : un prix clair et une date proche font la différence.'
                            : null,
                        actionLabel:
                            _tab == _Tab.pending ? 'Voir les demandes' : null,
                        onAction: _tab == _Tab.pending
                            ? () => context.pushReplacement(AppRoutes.requestFeed)
                            : null,
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                        indent: AppSpacing.gutter + 56 + AppSpacing.md),
                    itemBuilder: (_, i) => _QuoteRow(
                      quote: list[i],
                      onTap: () => list[i].status == QuoteStatus.accepted
                          ? context.go(AppRoutes.bookings)
                          : context.push(AppRoutes.request(list[i].requestId)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quote, required this.onTap});

  final Quote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = quote;
    final r = q.request;
    final (label, tone) = quoteStatus(q.status);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
        child: Row(
          children: [
            if (r != null)
              RequestThumb(request: r)
            else
              const SizedBox(width: 56, height: 56),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r?.title ?? 'Demande',
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    [
                      quotePriceText(q.price, q.priceKind),
                      if (r != null) r.place,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  StatusLabel(label: label, tone: tone),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: context.palette.subtle),
          ],
        ),
      ),
    );
  }
}
