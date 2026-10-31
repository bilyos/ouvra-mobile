import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifié. Connectez-vous avec le nouveau.')),
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nouveau mot de passe', style: theme.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.email == null
                      ? 'Saisissez le code reçu, puis votre nouveau mot de passe.'
                      : 'Code envoyé à ${widget.email}. Saisissez-le, puis votre nouveau mot de passe.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: context.palette.mutedForeground),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: 'Code reçu',
                  hint: '6 chiffres',
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  validator: (v) => (v == null || v.trim().length < 4)
                      ? 'Ce code est incomplet.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Nouveau mot de passe',
                  helper: 'Au moins 6 caractères.',
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  suffixIcon: IconButton(
                    tooltip: 'Afficher le mot de passe',
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Au moins 6 caractères.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Confirmer le mot de passe',
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v != _password.text)
                      ? 'Les deux mots de passe ne correspondent pas.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Enregistrer le mot de passe',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
