import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../../domain/app_user.dart';
import '../widgets/role_option_card.dart';

/// Bascule de rôle pour un compte existant (transformation de compte).
/// Ouvert depuis le profil.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = ref.watch(authControllerProvider)?.role;
    final selected = _role ?? current ?? UserRole.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Mode d\'utilisation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Passez de client à prestataire quand vous voulez. Vos réservations et vos messages sont conservés.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: context.palette.mutedForeground),
              ),
              const SizedBox(height: AppSpacing.xl),
              RoleOptionCard(
                role: UserRole.client,
                title: 'Client',
                description: 'Trouver un prestataire et réserver.',
                icon: Icons.search_rounded,
                selected: selected == UserRole.client,
                onTap: () => setState(() => _role = UserRole.client),
              ),
              const SizedBox(height: AppSpacing.md),
              RoleOptionCard(
                role: UserRole.provider,
                title: 'Prestataire',
                description: 'Recevoir des réservations et être payé.',
                icon: Icons.handyman_outlined,
                selected: selected == UserRole.provider,
                onTap: () => setState(() => _role = UserRole.provider),
              ),
              const Spacer(),
              AppButton(
                label: 'Enregistrer',
                onPressed: () {
                  // Devenir prestataire → passe par le formulaire dédié.
                  if (selected == UserRole.provider &&
                      current != UserRole.provider) {
                    context.pushReplacement(AppRoutes.becomeProvider);
                    return;
                  }
                  ref.read(authControllerProvider.notifier).setRole(selected);
                  context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
