import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../home/data/mock_categories.dart';
import '../../../providers/data/provider_repository.dart';
import '../../../providers/presentation/widgets/provider_card.dart';
import '../../application/search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(providerSearchProvider((
      category: _category,
      query: query.trim().isEmpty ? null : query.trim(),
      sort: 'proximity',
    )));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.md, AppSpacing.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Recherche',
                          style: theme.textTheme.displaySmall),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.map),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: const Text('Carte'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.screen,
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: (v) {
                  ref.read(searchQueryProvider.notifier).update(v);
                  setState(() {});
                },
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Métier, nom, quartier…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Effacer',
                          icon: const Icon(Icons.cancel_rounded, size: 20),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).update('');
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.screen,
                children: [
                  _FilterChip(
                    label: 'Tous',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final c in kMockCategories)
                    _FilterChip(
                      label: c.label,
                      selected: _category == c.id,
                      onTap: () => setState(
                          () => _category = _category == c.id ? null : c.id),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
              child: Text(
                resultsAsync.maybeWhen(
                  data: (r) => r.isEmpty
                      ? ''
                      : r.length == 1
                          ? '1 prestataire'
                          : '${r.length} prestataires, les plus proches d\'abord',
                  orElse: () => '',
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Divider(color: p.border),
            Expanded(
              child: resultsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorState(
                  message: apiErrorMessage(e),
                  onRetry: () => ref.invalidate(providerSearchProvider),
                ),
                data: (results) => results.isEmpty
                    ? EmptyState(
                        title: 'Aucun prestataire trouvé',
                        message: query.trim().isEmpty
                            ? 'Personne pour ce métier pour l\'instant. Publiez une demande : les pros seront prévenus.'
                            : 'Essayez un autre mot, ou le nom du métier : « plombier », « coiffure »…',
                        actionLabel: 'Publier une demande',
                        onAction: () => context.push(AppRoutes.newRequest),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: results.length,
                        separatorBuilder: (_, __) => ProviderCard.divider,
                        itemBuilder: (_, i) => ProviderCard(
                          provider: results[i],
                          onTap: () => context
                              .push(AppRoutes.providerDetail(results[i].id)),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? p.primary : p.muted,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 14,
                    color: selected ? p.onPrimary : p.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
