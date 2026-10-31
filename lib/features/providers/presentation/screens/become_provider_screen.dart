import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/app_user.dart';
import '../../../home/data/mock_categories.dart';
import '../../application/provider_profile_controller.dart';
import '../../domain/provider_profile.dart';
import '../widgets/category_select_field.dart';
import '../widgets/provider_form_fields.dart';

/// Conversion client → prestataire : 2 étapes (activité + réalisations) puis
/// un écran de succès avec retour à l'accueil.
class BecomeProviderScreen extends ConsumerStatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  ConsumerState<BecomeProviderScreen> createState() =>
      _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends ConsumerState<BecomeProviderScreen> {
  int _step = 0; // 0 = activité, 1 = réalisations, 2 = succès

  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _availability = TextEditingController();
  final _customCategory = TextEditingController();
  String? _categoryId;
  final List<Uint8List> _photos = [];

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _price,
      _city,
      _availability,
      _customCategory,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final files = await ImagePicker().pickMultiImage();
      for (final f in files) {
        _photos.add(await f.readAsBytes());
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir la galerie.')),
        );
      }
    }
  }

  void _finish() {
    ref.read(authControllerProvider.notifier).setRole(UserRole.provider);
    ref.read(providerProfileControllerProvider.notifier).save(
          ProviderProfile(
            categoryId: _categoryId == kOtherCategory
                ? _customCategory.text.trim()
                : (_categoryId ?? kMockCategories.first.id),
            title: _title.text.trim(),
            description: _description.text.trim(),
            startingPrice: int.tryParse(_price.text.trim()) ?? 0,
            city: _city.text.trim(),
            availability: _availability.text.trim(),
            photos: List.of(_photos),
          ),
        );
    setState(() => _step = 2);
  }

  void _next() {
    if (_step == 0) {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez votre métier pour continuer.')),
        );
        return;
      }
      if (!_form.currentState!.validate()) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 2) return const _SuccessView();

    return Scaffold(
      appBar: AppBar(
        title: Text('Étape ${_step + 1} sur 2'),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              _step == 0 ? context.pop() : setState(() => _step = 0),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: StepProgress(step: _step, total: 2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                    AppSpacing.lg, AppSpacing.gutter, AppSpacing.xl),
                child: _step == 0
                    ? Form(
                        key: _form,
                        child: ProviderActivityFields(
                          categoryId: _categoryId,
                          onCategoryChanged: (v) =>
                              setState(() => _categoryId = v),
                          customCategory: _customCategory,
                          title: _title,
                          description: _description,
                          price: _price,
                          city: _city,
                          availability: _availability,
                        ),
                      )
                    : RealizationsFields(
                        photos: _photos,
                        onAdd: _pickPhotos,
                        onRemove: (i) => setState(() => _photos.removeAt(i)),
                      ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: context.palette.border, width: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                    AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
                child: AppButton(
                  label: _step == 0 ? 'Continuer' : 'Publier mon profil',
                  onPressed: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation : le profil est en ligne.
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(Icons.check_circle_rounded, color: p.primary, size: 44),
              const SizedBox(height: AppSpacing.lg),
              Text('Votre profil est en ligne',
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Les clients de votre ville peuvent maintenant vous trouver et vous réserver. Vous serez prévenu à chaque nouvelle demande.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: p.mutedForeground),
              ),
              const Spacer(flex: 2),
              AppButton(
                label: 'Aller à l\'accueil',
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
