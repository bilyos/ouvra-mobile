import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/net_image.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../home/data/mock_categories.dart';
import '../../application/provider_profile_controller.dart';
import '../../domain/service_provider.dart';

/// Profil publié du prestataire connecté (`GET /me/provider-profile`).
final _myPublishedProfileProvider =
    FutureProvider.autoDispose<(ServiceProvider, String)>((ref) async {
  final res = await ref.watch(dioProvider).get('/me/provider-profile');
  final json = res.data as Map<String, dynamic>;
  return (
    ServiceProvider.fromJson(json),
    (json['availability'] as String?) ?? '',
  );
});

/// Aperçu du profil prestataire tel que les clients le voient.
class MyProviderProfileScreen extends ConsumerWidget {
  const MyProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final local = ref.watch(providerProfileControllerProvider);

    // Profil tout juste saisi dans l'app : on l'affiche tel quel.
    if (local != null) {
      return _Scaffold(
        child: _ProfileView(
          name: user?.fullName ?? '',
          avatarUrl: user?.avatarUrl,
          title: local.title,
          category: _catLabel(local.categoryId),
          price: local.startingPrice,
          city: local.city,
          availability: local.availability,
          description: local.description,
          photos: [
            for (final b in local.photos)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.memory(b, fit: BoxFit.cover, cacheWidth: 300),
              ),
          ],
        ),
      );
    }

    final async = ref.watch(_myPublishedProfileProvider);
    return _Scaffold(
      child: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          title: 'Pas encore de profil prestataire',
          message:
              'Décrivez votre activité et ajoutez des photos : les clients de votre ville pourront vous réserver.',
          actionLabel: 'Devenir prestataire',
          onAction: () => context.push(AppRoutes.becomeProvider),
        ),
        data: (data) {
          final (p, availability) = data;
          return _ProfileView(
            name: p.name,
            avatarUrl: p.avatarUrl,
            title: p.profession,
            category: _catLabel(p.categoryId),
            price: p.startingPrice,
            city: p.city,
            availability: availability,
            description: p.bio,
            photos: [
              for (final url in p.portfolio)
                NetImage(url: url, width: 120, radius: AppSpacing.radiusSm),
            ],
            onPreview: () => context.push(AppRoutes.providerDetail(p.id)),
          );
        },
      ),
    );
  }

  static String _catLabel(String id) {
    for (final c in kMockCategories) {
      if (c.id == id) return c.label;
    }
    return id;
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil prestataire')),
      body: child,
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.name,
    required this.avatarUrl,
    required this.title,
    required this.category,
    required this.price,
    required this.city,
    required this.availability,
    required this.description,
    required this.photos,
    this.onPreview,
  });

  final String name;
  final String? avatarUrl;
  final String title;
  final String category;
  final int price;
  final String city;
  final String availability;
  final String description;
  final List<Widget> photos;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final facts = <(String, String)>[
      ('Métier', category),
      ('Prix de départ', formatFcfa(price)),
      ('Ville', city),
      if (availability.isNotEmpty) ('Disponibilités', availability),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl),
      children: [
        Row(
          children: [
            AppAvatar(name: name, url: avatarUrl, size: 64),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  Text(name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: p.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final (label, value) in facts) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                    child: Text(label,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: p.mutedForeground))),
                Flexible(
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Description', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(description.isEmpty ? 'Aucune description.' : description,
            style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        Text('Réalisations', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        if (photos.isEmpty)
          Text('Aucune photo. Les profils avec photos sont plus réservés.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: p.mutedForeground))
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            children: photos,
          ),
        if (onPreview != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Voir comme un client',
            variant: AppButtonVariant.tonal,
            onPressed: onPreview,
          ),
        ],
      ],
    );
  }
}
