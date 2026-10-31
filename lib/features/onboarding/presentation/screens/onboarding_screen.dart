import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../bookings/presentation/widgets/completion_code.dart';

/// Présentation en trois étapes : c'est réellement une suite (trouver,
/// payer, valider), d'où la numérotation. Chaque étape montre un vrai
/// morceau d'interface plutôt qu'une illustration.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Step {
  const _Step(this.title, this.body, this.preview);
  final String title;
  final String body;
  final Widget preview;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static final _steps = [
    const _Step(
      'Trouvez le bon pro, près de chez vous',
      'Plombiers, électriciens, ménage, coiffure… Comparez les avis et les tarifs avant de vous décider.',
      _TradesPreview(),
    ),
    const _Step(
      'Votre argent reste bloqué pendant le travail',
      'Vous payez par Orange Money ou MTN MoMo. Ouvra garde la somme et ne la verse au pro qu\'une fois le travail fait.',
      _EscrowPreview(),
    ),
    const _Step(
      'Donnez votre code quand c\'est fini',
      'Le pro saisit votre code à la fin : il est payé. Un problème ? Signalez-le, l\'argent reste bloqué.',
      CompletionCodePlate(code: '4827', size: CodePlateSize.large),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _steps.length - 1;

  void _next() {
    if (_isLast) {
      context.go(AppRoutes.login);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  const AppWordmark(size: 26),
                  const Spacer(),
                  if (!_isLast)
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: TextButton.styleFrom(
                        foregroundColor: p.mutedForeground,
                      ),
                      child: const Text('Passer'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _steps[i];
                  // Sur les écrans bas (petits Android), l'aperçu cède la
                  // place au texte, et la page défile au besoin.
                  return LayoutBuilder(
                    builder: (context, box) => box.maxHeight >= 480
                        ? Padding(
                            padding: AppSpacing.screen,
                            child: _page(context, i, s, showPreview: true),
                          )
                        : SingleChildScrollView(
                            padding: AppSpacing.screen,
                            child: _page(context, i, s, showPreview: false),
                          ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      width: i == _index ? 20 : 8,
                      decoration: BoxDecoration(
                        color: i == _index ? p.primary : p.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const Spacer(),
                  AppButton(
                    label: _isLast ? 'Commencer' : 'Suivant',
                    expanded: false,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(
    BuildContext context,
    int i,
    _Step s, {
    required bool showPreview,
  }) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview) ...[
          const Spacer(flex: 2),
          Center(child: s.preview),
          const Spacer(flex: 2),
        ] else
          const SizedBox(height: AppSpacing.xl),
        Text(
          '${i + 1} sur ${_steps.length}',
          style: theme.textTheme.labelMedium?.copyWith(color: p.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(s.title, style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          s.body,
          style: theme.textTheme.bodyLarge?.copyWith(color: p.mutedForeground),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Trois lignes de métiers, comme dans la recherche.
class _TradesPreview extends StatelessWidget {
  const _TradesPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    const rows = [
      (Icons.plumbing_rounded, 'Plombier', 'Akwa, Douala', 5000),
      (
        Icons.electrical_services_rounded,
        'Électricienne',
        'Bastos, Yaoundé',
        7000,
      ),
      (Icons.cleaning_services_rounded, 'Ménage', 'Bonamoussadi', 4000),
    ];
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 22, color: p.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$2, style: theme.textTheme.titleSmall),
                        Text(rows[i].$3, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    'dès ${formatFcfa(rows[i].$4)}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1) const Divider(indent: 50),
          ],
        ],
      ),
    );
  }
}

/// Le bloc séquestre tel qu'il apparaît dans une réservation.
class _EscrowPreview extends StatelessWidget {
  const _EscrowPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 18, color: p.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Bloqué chez Ouvra',
                style: theme.textTheme.labelMedium?.copyWith(color: p.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(formatFcfa(15000), style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Réparation de fuite, jeudi à 10:00',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 4,
              color: AppColors.brand500,
              backgroundColor: p.background,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Payé', style: theme.textTheme.labelSmall),
              const Spacer(),
              Text('Versé au pro', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
