import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/list_rows.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/app_user.dart';
import '../../../notifications/data/notification_repository.dart';

/// Profil : qui je suis, puis des listes groupées de réglages.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vous devrez saisir votre e-mail et votre mot de passe pour revenir.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Rester connecté')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: p.danger),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final user = ref.watch(authControllerProvider);
    final mode = ref.watch(themeModeControllerProvider);
    final unread = ref.watch(notificationUnreadCountProvider).valueOrNull ?? 0;
    final isProvider = user?.role == UserRole.provider;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
              child: Semantics(
                header: true,
                child: Text('Profil', style: theme.textTheme.displaySmall),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: AppSpacing.screen,
              child: Row(
                children: [
                  AppAvatar(
                    name: user?.fullName ?? '?',
                    url: user?.avatarUrl,
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Non connecté',
                            style: theme.textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (user != null)
                          Text(
                            user.email?.isNotEmpty == true
                                ? user.email!
                                : user.phone,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: p.mutedForeground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          isProvider ? 'Compte prestataire' : 'Compte client',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: p.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GroupedSection(children: [
              AppListRow(
                icon: Icons.event_note_outlined,
                title: isProvider ? 'Réservations reçues' : 'Mes réservations',
                onTap: () => context.go(AppRoutes.bookings),
              ),
              AppListRow(
                icon: isProvider
                    ? Icons.receipt_long_outlined
                    : Icons.campaign_outlined,
                title: isProvider ? 'Mes devis' : 'Mes demandes',
                onTap: () => context.push(
                    isProvider ? AppRoutes.myQuotes : AppRoutes.myRequests),
              ),
              AppListRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                value: unread > 0 ? '$unread non lues' : null,
                onTap: () => context.push(AppRoutes.notifications),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            GroupedSection(
              header: 'Activité professionnelle',
              footer: isProvider
                  ? null
                  : 'Proposez vos services aux clients de votre ville et soyez payé par Mobile Money.',
              children: [
                if (isProvider) ...[
                  AppListRow(
                    icon: Icons.storefront_outlined,
                    title: 'Mon profil prestataire',
                    onTap: () => context.push(AppRoutes.myProviderProfile),
                  ),
                  AppListRow(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Mode d\'utilisation',
                    value: user?.role.label,
                    onTap: () => context.push(AppRoutes.roleSelection),
                  ),
                ] else
                  AppListRow(
                    icon: Icons.handyman_outlined,
                    title: user?.isProviderEnabled == true
                        ? 'Passer en mode prestataire'
                        : 'Devenir prestataire',
                    onTap: () => context.push(user?.isProviderEnabled == true
                        ? AppRoutes.roleSelection
                        : AppRoutes.becomeProvider),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GroupedSection(children: [
              AppListRow(
                icon: Icons.contrast_rounded,
                title: 'Apparence',
                value: switch (mode) {
                  ThemeMode.system => 'Automatique',
                  ThemeMode.light => 'Clair',
                  ThemeMode.dark => 'Sombre',
                },
                onTap: () => context.push(AppRoutes.settings),
              ),
              AppListRow(
                icon: Icons.settings_outlined,
                title: 'Réglages',
                onTap: () => context.push(AppRoutes.settings),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            GroupedSection(indent: AppSpacing.lg, children: [
              AppListRow(
                title: 'Se déconnecter',
                destructive: true,
                showChevron: false,
                onTap: () => _logout(context, ref),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
