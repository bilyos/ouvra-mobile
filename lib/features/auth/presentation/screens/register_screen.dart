import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../home/data/mock_categories.dart';
import '../../../providers/application/provider_profile_controller.dart';
import '../../../providers/domain/provider_profile.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../../providers/presentation/widgets/category_select_field.dart';
import '../../../providers/presentation/widgets/provider_form_fields.dart';
import '../../application/auth_controller.dart';
import '../../domain/app_user.dart';
import '../widgets/role_option_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Étape courante : 0 = identité, 1 = profil pro, 2 = réalisations.
  int _step = 0;

  // Identité
  final _identityForm = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Gender _gender = Gender.homme;
  UserRole _role = UserRole.client;
  bool _obscure = true;
  bool _obscure2 = true;

  // Profil prestataire
  final _proForm = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _availability = TextEditingController();
  final _customCategory = TextEditingController();
  String? _categoryId;

  // Réalisations
  final List<Uint8List> _photos = [];

  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _phone,
      _email,
      _password,
      _confirm,
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

  bool get _isProvider => _role == UserRole.provider;
  int get _totalSteps => _isProvider ? 3 : 1;

  // Mutations exposées aux widgets d'étape (encapsulent setState).
  void setGender(Gender g) => setState(() => _gender = g);
  void setRole(UserRole r) => setState(() => _role = r);
  void toggleObscure() => setState(() => _obscure = !_obscure);
  void toggleObscure2() => setState(() => _obscure2 = !_obscure2);
  void setCategory(String? id) => setState(() => _categoryId = id);
  void removePhoto(int i) => setState(() => _photos.removeAt(i));

  Future<void> _pickPhotos() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage();
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

  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            gender: _gender,
            role: _role,
          );
      if (_isProvider) {
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
      }
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  void _next() {
    if (_step == 0) {
      if (!_identityForm.currentState!.validate()) return;
      if (_isProvider) {
        setState(() => _step = 1);
      } else {
        _finish();
      }
    } else if (_step == 1) {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez votre métier pour continuer.')),
        );
        return;
      }
      if (!_proForm.currentState!.validate()) return;
      setState(() => _step = 2);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _back,
        ),
        title: Text(_isProvider
            ? 'Étape ${_step + 1} sur $_totalSteps'
            : 'Créer un compte'),
        bottom: _isProvider
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: StepProgress(step: _step, total: _totalSteps),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (_step) {
                0 => _IdentityStep(state: this),
                1 => _ProviderStep(state: this),
                _ => _RealizationsStep(state: this),
              },
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
                  label: _step == _totalSteps - 1
                      ? 'Créer mon compte'
                      : 'Continuer',
                  loading: _loading,
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

// ─── Étape 1 : identité ─────────────────────────────────────────────────

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({required this.state});
  final _RegisterScreenState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
      child: Form(
        key: state._identityForm,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous êtes', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              RoleOptionCard(
                role: UserRole.client,
                title: 'Client',
                description: 'Je cherche quelqu\'un pour un travail.',
                icon: Icons.search_rounded,
                selected: state._role == UserRole.client,
                onTap: () => state.setRole(UserRole.client),
              ),
              const SizedBox(height: AppSpacing.sm),
              RoleOptionCard(
                role: UserRole.provider,
                title: 'Prestataire',
                description: 'Je propose mes services. Deux étapes de plus.',
                icon: Icons.handyman_outlined,
                selected: state._role == UserRole.provider,
                onTap: () => state.setRole(UserRole.provider),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Vos informations', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Prénom',
                      controller: state._firstName,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Prénom requis.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Nom',
                      controller: state._lastName,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nom requis.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Sexe',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: p.mutedForeground)),
              const SizedBox(height: 6),
              SegmentedChoice<Gender>(
                values: Gender.values,
                selected: state._gender,
                label: (g) => g.label,
                onChanged: state.setGender,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Téléphone',
                hint: '6 90 00 00 00',
                helper: 'Le numéro de votre compte Mobile Money.',
                controller: state._phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: (v) => (v == null || v.trim().length < 8)
                    ? 'Ce numéro est trop court.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Adresse e-mail',
                hint: 'nom@exemple.cm',
                controller: state._email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Saisissez votre e-mail.';
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Cet e-mail n\'est pas valide.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Mot de passe',
                helper: 'Au moins 6 caractères.',
                controller: state._password,
                obscureText: state._obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                suffixIcon: IconButton(
                  tooltip: 'Afficher le mot de passe',
                  icon: Icon(
                      state._obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20),
                  onPressed: state.toggleObscure,
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Au moins 6 caractères.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Confirmer le mot de passe',
                controller: state._confirm,
                obscureText: state._obscure2,
                textInputAction: TextInputAction.done,
                suffixIcon: IconButton(
                  tooltip: 'Afficher le mot de passe',
                  icon: Icon(
                      state._obscure2
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20),
                  onPressed: state.toggleObscure2,
                ),
                validator: (v) => (v != state._password.text)
                    ? 'Les deux mots de passe ne correspondent pas.'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Étape 2 : activité ─────────────────────────────────────────────────

class _ProviderStep extends StatelessWidget {
  const _ProviderStep({required this.state});
  final _RegisterScreenState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xl),
      child: Form(
        key: state._proForm,
        child: ProviderActivityFields(
          categoryId: state._categoryId,
          onCategoryChanged: state.setCategory,
          customCategory: state._customCategory,
          title: state._title,
          description: state._description,
          price: state._price,
          city: state._city,
          availability: state._availability,
        ),
      ),
    );
  }
}

// ─── Étape 3 : réalisations ─────────────────────────────────────────────

class _RealizationsStep extends StatelessWidget {
  const _RealizationsStep({required this.state});
  final _RegisterScreenState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xl),
      child: RealizationsFields(
        photos: state._photos,
        onAdd: state._pickPhotos,
        onRemove: state.removePhoto,
      ),
    );
  }
}
