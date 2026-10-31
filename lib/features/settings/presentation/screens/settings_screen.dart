import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/list_rows.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/app_user.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final user = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    void setMode(ThemeMode m) =>
        ref.read(themeModeControllerProvider.notifier).set(m);

    Widget check(bool on) => on
        ? Icon(Icons.check_rounded, color: p.primary, size: 22)
        : const SizedBox(width: 22);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
        children: [
          GroupedSection(
            header: 'Apparence',
            indent: AppSpacing.lg,
            footer:
                'En mode automatique, Ouvra suit le réglage de votre téléphone.',
            children: [
              AppListRow(
                title: 'Automatique',
                trailing: check(themeMode == ThemeMode.system),
                onTap: () => setMode(ThemeMode.system),
              ),
              AppListRow(
                title: 'Clair',
                trailing: check(themeMode == ThemeMode.light),
                onTap: () => setMode(ThemeMode.light),
              ),
              AppListRow(
                title: 'Sombre',
                trailing: check(themeMode == ThemeMode.dark),
                onTap: () => setMode(ThemeMode.dark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GroupedSection(
            header: 'Compte',
            indent: AppSpacing.lg,
            children: [
              AppListRow(
                title: 'Mode d\'utilisation',
                value: user?.role.label ?? 'Client',
                onTap: () => context.push(AppRoutes.roleSelection),
              ),
              if (user != null)
                AppListRow(title: 'Téléphone', value: user.phone),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const GroupedSection(
            header: 'À propos',
            indent: AppSpacing.lg,
            children: [
              AppListRow(title: 'Version', value: '1.0.0'),
            ],
          ),
        ],
      ),
    );
  }
}
