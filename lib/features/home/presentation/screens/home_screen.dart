import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/app_user.dart';
import '../../../bookings/data/booking_repository.dart';
import '../../../requests/data/request_repository.dart';
import '../../../requests/presentation/screens/my_requests_screen.dart';
import '../../../bookings/presentation/widgets/booking_row.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../providers/application/providers_controller.dart';
import '../../../providers/data/provider_repository.dart';
import '../../../providers/domain/service_provider.dart';
import '../../../providers/presentation/widgets/provider_card.dart';
import '../../data/mock_categories.dart';
import '../../data/provider_dashboard_repository.dart';
import '../widgets/category_card.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/popular_service_card.dart';

/// Accueil : celui du client, ou l'espace prestataire selon le rôle actif.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((u) => u?.role));
    return role == UserRole.provider
        ? const _ProviderHome()
        : const _ClientHome();
  }
}

// ─── En-tête commun ─────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final unread = ref.watch(notificationUnreadCountProvider).valueOrNull ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.md, AppSpacing.sm, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: p.mutedForeground)),
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.displaySmall),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: unread > 0
                ? 'Notifications, $unread non lues'
                : 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              smallSize: 8,
              backgroundColor: p.danger,
              child: const Icon(Icons.notifications_none_rounded, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

String _firstName(AppUser? u) {
  final n = u?.fullName.trim() ?? '';
  return n.isEmpty ? '' : n.split(' ').first;
}

// ─── Client ─────────────────────────────────────────────────────────────

class _ClientHome extends ConsumerWidget {
  const _ClientHome();

  static const _shown = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final nearbyAsync = ref.watch(providerSearchProvider(
        (category: selectedCategory, query: null, sort: 'proximity')));
    final popularAsync = ref.watch(providerSearchProvider(
        (category: null, query: null, sort: 'rating')));
    final openBookings = ref
            .watch(myBookingsProvider)
            .valueOrNull
            ?.where((b) => b.isOpen)
            .toList() ??
        const [];
    final openRequests = ref
            .watch(myRequestsProvider)
            .valueOrNull
            ?.where((r) => r.isOpen)
            .toList() ??
        const [];

    final name = _firstName(user);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(providerSearchProvider);
            ref.invalidate(myBookingsProvider);
            ref.invalidate(myRequestsProvider);
            ref.invalidate(notificationUnreadCountProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  subtitle: user?.city?.isNotEmpty == true ? user!.city : null,
                  title: name.isEmpty ? 'Bonjour' : 'Bonjour $name',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                      AppSpacing.lg, AppSpacing.gutter, 0),
                  child: HomeSearchBar(
                      onTap: () => context.go(AppRoutes.search)),
                ),
              ),
              const SliverToBoxAdapter(child: _RequestPrompt()),
              if (openRequests.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Mes demandes',
                    actionLabel: 'Tout voir',
                    onAction: () => context.push(AppRoutes.myRequests),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.xl, AppSpacing.sm, 0),
                  ),
                ),
                for (final r in openRequests.take(2))
                  SliverToBoxAdapter(
                    child: RequestRow(
                      request: r,
                      onTap: () => context.push(AppRoutes.request(r.id)),
                    ),
                  ),
              ],
              if (openBookings.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'En cours',
                    actionLabel: openBookings.length > 1 ? 'Tout voir' : null,
                    onAction: () => context.go(AppRoutes.bookings),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.xl, AppSpacing.sm, 0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: BookingRow(
                    booking: openBookings.first,
                    asProvider: false,
                    onTap: () => context
                        .push(AppRoutes.booking(openBookings.first.id)),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Métiers',
                  actionLabel: 'Tout voir',
                  onAction: () => context.push(AppRoutes.allCategories),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter, AppSpacing.xl, AppSpacing.sm, 0),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter - 6),
                    itemCount: _shown,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, i) {
                      final c = kMockCategories[i];
                      return CategoryCard(
                        category: c,
                        selected: selectedCategory == c.id,
                        onTap: () => ref
                            .read(selectedCategoryProvider.notifier)
                            .toggle(c.id),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Les mieux notés',
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter, AppSpacing.lg, AppSpacing.sm, 0),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 236,
                  child: popularAsync.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorState(
                      message: apiErrorMessage(e),
                      compact: true,
                      onRetry: () => ref.invalidate(providerSearchProvider),
                    ),
                    data: (popular) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
                      itemCount: popular.length.clamp(0, 10),
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, i) => PopularServiceCard(
                        provider: popular[i],
                        onTap: () => context
                            .push(AppRoutes.providerDetail(popular[i].id)),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: selectedCategory == null
                      ? 'Près de chez vous'
                      : _categoryLabel(selectedCategory),
                  actionLabel: 'Voir la carte',
                  onAction: () => context.push(AppRoutes.map),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter, AppSpacing.lg, AppSpacing.sm, 0),
                ),
              ),
              nearbyAsync.when(
                loading: () => const SliverToBoxAdapter(child: LoadingView()),
                error: (e, _) => SliverToBoxAdapter(
                  child: ErrorState(
                    message: apiErrorMessage(e),
                    compact: true,
                    onRetry: () => ref.invalidate(providerSearchProvider),
                  ),
                ),
                data: (providers) => _NearbyList(
                  providers: providers,
                  filtered: selectedCategory != null,
                  onClear: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .toggle(selectedCategory!),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String id) {
    for (final c in kMockCategories) {
      if (c.id == id) return c.label;
    }
    return 'Résultats';
  }
}

/// Entrée du fil de demandes : le client décrit son problème et reçoit des devis.
/// C'est l'action principale de l'accueil, d'où le jaune.
class _RequestPrompt extends StatelessWidget {
  const _RequestPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
        decoration: BoxDecoration(
          color: p.primarySoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Un problème à régler ?', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Prenez une photo ou décrivez-le en vocal. Les pros du quartier vous envoient leur prix.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: p.mutedForeground),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Publier une demande',
              icon: Icons.photo_camera_outlined,
              onPressed: () => context.push(AppRoutes.newRequest),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyList extends StatelessWidget {
  const _NearbyList({
    required this.providers,
    required this.filtered,
    required this.onClear,
  });

  final List<ServiceProvider> providers;
  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          compact: true,
          title: 'Personne pour ce métier ici',
          message:
              'Publiez une demande : les prestataires des environs seront prévenus.',
          actionLabel: filtered ? 'Voir tous les métiers' : null,
          onAction: filtered ? onClear : null,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      sliver: SliverList.separated(
        itemCount: providers.length,
        separatorBuilder: (_, __) => ProviderCard.divider,
        itemBuilder: (context, i) => ProviderCard(
          provider: providers[i],
          onTap: () => context.push(AppRoutes.providerDetail(providers[i].id)),
        ),
      ),
    );
  }
}

// ─── Prestataire ────────────────────────────────────────────────────────

class _ProviderHome extends ConsumerWidget {
  const _ProviderHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final user = ref.watch(authControllerProvider);
    final stats = ref.watch(providerStatsProvider).valueOrNull;
    final balance = ref.watch(walletBalanceProvider).valueOrNull;
    final receivedAsync = ref.watch(receivedBookingsProvider);
    final name = _firstName(user);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(providerStatsProvider);
            ref.invalidate(walletBalanceProvider);
            ref.invalidate(receivedBookingsProvider);
            ref.invalidate(notificationUnreadCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              _Header(
                subtitle: 'Espace prestataire',
                title: name.isEmpty ? 'Bonjour' : 'Bonjour $name',
              ),
              const SizedBox(height: AppSpacing.xl),
              // Le chiffre qui compte : ce qui a déjà été gagné.
              Padding(
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solde disponible',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: p.mutedForeground)),
                    const SizedBox(height: 2),
                    Text(balance == null ? '…' : formatFcfa(balance),
                        style: theme.textTheme.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: AppSpacing.screen,
                child: Row(
                  children: [
                    _Stat(
                      value: stats == null || stats.reviewCount == 0
                          ? '–'
                          : stats.ratingAvg
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                      label: 'Note moyenne',
                    ),
                    _Stat(
                        value: '${stats?.reviewCount ?? '–'}', label: 'Avis'),
                    _Stat(
                        value: '${stats?.contacts ?? '–'}',
                        label: 'Clients en contact'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(Icons.campaign_outlined, color: p.primary),
                  title: const Text('Demandes autour de vous'),
                  subtitle: const Text(
                      'Les problèmes publiés par les clients, à chiffrer.'),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: p.subtle),
                  onTap: () => context.push(AppRoutes.requestFeed),
                ),
              ),
              const Divider(indent: AppSpacing.gutter + 40),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined, color: p.primary),
                  title: const Text('Mes devis'),
                  subtitle: const Text('Ceux en attente et ceux acceptés.'),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: p.subtle),
                  onTap: () => context.push(AppRoutes.myQuotes),
                ),
              ),
              const Divider(),
              SectionHeader(
                title: 'À traiter',
                actionLabel: 'Tout voir',
                onAction: () => context.go(AppRoutes.bookings),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter, AppSpacing.xl, AppSpacing.sm, 0),
              ),
              receivedAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorState(
                  message: apiErrorMessage(e),
                  compact: true,
                  onRetry: () => ref.invalidate(receivedBookingsProvider),
                ),
                data: (all) {
                  final open = all.where((b) => b.isOpen).toList();
                  if (open.isEmpty) {
                    return const EmptyState(
                      compact: true,
                      title: 'Rien à traiter',
                      message:
                          'Les nouvelles réservations apparaîtront ici. Un profil complet avec des photos en attire davantage.',
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < open.length && i < 5; i++) ...[
                        if (i > 0) BookingRow.divider,
                        BookingRow(
                          booking: open[i],
                          asProvider: true,
                          onTap: () =>
                              context.push(AppRoutes.booking(open[i].id)),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
