import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/choice_pill.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../home/data/mock_categories.dart';
import '../../../home/domain/service_category.dart';
import '../../../providers/data/media_repository.dart';
import '../../data/request_repository.dart';
import '../../domain/job_request.dart';
import '../request_format.dart';
import '../widgets/request_photos.dart';
import '../widgets/voice_note.dart';

const _minText = 20;

/// Métiers du pilote, proposés en premier : ce sont ceux qu'on montre le
/// mieux en photo et pour lesquels il y a le plus de prestataires inscrits.
const _firstCategories = [
  'plomberie',
  'electricite',
  'climatisation',
  'menage',
  'reparation',
  'menuiserie',
  'peinture',
  'maconnerie',
];

const _cities = ['Douala', 'Yaoundé', 'Bafoussam', 'Garoua', 'Kribi', 'Limbé'];

/// « Montrez votre problème » : photo, vocal ou texte, puis le métier, le
/// quartier et l'urgence. Les prestataires du coin répondent avec un prix.
class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key, this.categoryId});

  /// Métier présélectionné quand on arrive d'une page catégorie.
  final String? categoryId;

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _quarter = TextEditingController();
  final _landmark = TextEditingController();
  final _budget = TextEditingController();

  List<LocalPhoto> _photos = const [];
  LocalVoice? _voice;
  late String? _category = widget.categoryId;
  late String _city = _initialCity();
  RequestTiming _timing = RequestTiming.thisWeek;
  Position? _position;
  bool _locating = false;

  bool _sending = false;
  String? _progress;
  String? _error;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_title, _details, _quarter, _landmark, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  String _initialCity() {
    final city = ref.read(authControllerProvider)?.city?.trim();
    return city == null || city.isEmpty ? 'Douala' : city;
  }

  bool get _hasSomething =>
      _photos.isNotEmpty ||
      _voice != null ||
      _details.text.trim().length >= _minText;

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'off';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'denied';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) setState(() => _position = pos);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Position indisponible. Le quartier suffit pour trouver des pros proches.')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOtherCategory() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, controller) => ListView(
          controller: controller,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
              child: Text('Tous les métiers',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final c in kMockCategories)
              ListTile(
                leading: Icon(c.icon),
                title: Text(c.label),
                trailing: c.id == _category
                    ? Icon(Icons.check_rounded, color: ctx.palette.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, c.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _category = picked);
  }

  void _fail(String message) {
    setState(() => _error = message);
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    if (!_hasSomething) {
      return _fail(
          'Ajoutez une photo, une note vocale ou quelques phrases pour montrer le problème.');
    }
    if (_category == null) return _fail('Choisissez le métier concerné.');
    if (_title.text.trim().length < 3) {
      return _fail('Donnez un titre court à votre demande.');
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final media = ref.read(mediaRepositoryProvider);
    try {
      // Un fichier à la fois : sur une connexion lente, c'est plus fiable
      final urls = <String>[];
      for (var i = 0; i < _photos.length; i++) {
        setState(() => _progress = _photos.length == 1
            ? 'Envoi de la photo…'
            : 'Envoi des photos (${i + 1} sur ${_photos.length})…');
        final photo = _photos[i];
        urls.add(await media.upload(photo.bytes,
            filename: photo.name,
            contentType: photo.mimeType ?? _imageType(photo.name)));
      }
      String? voiceUrl;
      if (_voice != null) {
        setState(() => _progress = 'Envoi de la note vocale…');
        voiceUrl = await media.upload(_voice!.bytes,
            filename: 'note.${_voice!.extension}',
            contentType: _voice!.contentType);
      }
      setState(() => _progress = 'Publication…');
      final budget = int.tryParse(_budget.text.trim());
      final details = _details.text.trim();
      final quarter = _quarter.text.trim();
      final address = [quarter, _landmark.text.trim()]
          .where((s) => s.isNotEmpty)
          .join(', ');
      final (request, notified) =
          await ref.read(requestRepositoryProvider).create(
                categoryId: _category!,
                title: _title.text.trim(),
                description: details.isEmpty ? null : details,
                voiceUrl: voiceUrl,
                voiceSeconds: _voice?.seconds,
                photoUrls: urls,
                city: _city,
                quarter: quarter.isEmpty ? null : quarter,
                lat: _position?.latitude,
                lng: _position?.longitude,
                address: address.isEmpty ? null : address,
                timing: _timing,
                budgetMax: budget == null || budget <= 0 ? null : budget,
              );
      ref.invalidate(myRequestsProvider);
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _Published(request: request, notified: notified),
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _progress = null;
        });
        _fail(apiErrorMessage(e,
            fallback:
                'La demande n\'a pas pu être publiée. Vérifiez votre connexion et réessayez.'));
      }
    }
  }

  String _imageType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final first = [
      for (final id in _firstCategories)
        kMockCategories.firstWhere((c) => c.id == id),
    ];
    final selectedElsewhere =
        _category != null && !_firstCategories.contains(_category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle demande'),
        leading: IconButton(
          tooltip: 'Fermer',
          icon: const Icon(Icons.close_rounded),
          onPressed: _sending ? null : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxl),
              children: [
                Text('Montrez le problème', style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Les prestataires du quartier vous envoient un prix et une date. Vous choisissez, sans donner votre numéro.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: p.mutedForeground),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: AppSpacing.xl),
                RequestPhotoPicker(
                  photos: _photos,
                  enabled: !_sending,
                  onChanged: (v) => setState(() {
                    _photos = v;
                    _error = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                VoiceRecorder(
                  value: _voice,
                  enabled: !_sending,
                  onChanged: (v) => setState(() {
                    _voice = v;
                    _error = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'En quelques phrases (facultatif)',
                  hint:
                      'Depuis quand, ce que vous avez déjà essayé, la marque de l\'appareil…',
                  controller: _details,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                ),
                _Section(title: 'Quel métier ?'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in first)
                      _CategoryChip(
                        category: c,
                        selected: _category == c.id,
                        onTap: () => setState(() {
                          _category = c.id;
                          _error = null;
                        }),
                      ),
                    if (selectedElsewhere)
                      _CategoryChip(
                        category: kMockCategories
                            .firstWhere((c) => c.id == _category),
                        selected: true,
                        onTap: _pickOtherCategory,
                      ),
                    ChoicePill(
                      label: 'Autre métier',
                      icon: Icons.more_horiz_rounded,
                      selected: false,
                      onTap: _pickOtherCategory,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Titre',
                  hint: _category == null
                      ? 'Fuite sous l\'évier, prise qui chauffe…'
                      : _titleHint(_category!),
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                ),
                _Section(title: 'Où ?'),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cities.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, i) => ChoicePill(
                      label: _cities[i],
                      selected: _city == _cities[i],
                      onTap: () => setState(() => _city = _cities[i]),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Quartier',
                  hint: 'Bonamoussadi, Bastos, Akwa…',
                  controller: _quarter,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Repère (facultatif)',
                  hint: 'Derrière la pharmacie, portail bleu',
                  helper:
                      'Visible seulement par le prestataire que vous choisirez.',
                  controller: _landmark,
                ),
                const SizedBox(height: AppSpacing.sm),
                _LocationRow(
                  position: _position,
                  loading: _locating,
                  onTap: _sending ? null : _locate,
                ),
                _Section(title: 'Pour quand ?'),
                for (final t in RequestTiming.values)
                  _TimingOption(
                    timing: t,
                    selected: _timing == t,
                    onTap: () => setState(() => _timing = t),
                  ),
                _Section(title: 'Budget (facultatif)'),
                AppTextField(
                  hint: 'Montant maximum en FCFA',
                  helper:
                      'Laissez vide si vous ne savez pas : les pros vous proposeront leur prix.',
                  controller: _budget,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: p.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Votre numéro et votre adresse exacte restent privés. Vous ne payez qu\'après avoir choisi un devis, et Ouvra garde l\'argent jusqu\'à la fin du travail.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: p.background,
              border: Border(top: BorderSide(color: p.border, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_progress != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(_progress!,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center),
                      ),
                    AppButton(
                      label: 'Publier ma demande',
                      loading: _sending,
                      onPressed: _publish,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _titleHint(String category) => switch (category) {
      'plomberie' => 'Fuite sous l\'évier de la cuisine',
      'electricite' => 'Prise qui chauffe dans le salon',
      'climatisation' => 'Le climatiseur ne refroidit plus',
      'menage' => 'Grand ménage d\'un appartement 3 pièces',
      'menuiserie' => 'Porte de chambre qui ne ferme plus',
      'peinture' => 'Repeindre un salon de 20 m²',
      'maconnerie' => 'Fissure sur le mur de la cour',
      _ => 'Dites en une ligne ce qu\'il faut faire',
    };

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            top: AppSpacing.xxl, bottom: AppSpacing.md),
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.dangerSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: p.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: p.danger)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoicePill(
        label: category.label,
        icon: category.icon,
        selected: selected,
        onTap: onTap,
      );
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.position,
    required this.loading,
    required this.onTap,
  });

  final Position? position;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final done = position != null;
    return InkWell(
      onTap: done ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: loading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Icon(
                      done ? Icons.check_circle_rounded : Icons.my_location_rounded,
                      size: 20,
                      color: done ? p.success : p.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                done
                    ? 'Position ajoutée. Les pros ne voient qu\'une zone d\'environ 500 m.'
                    : 'Ajouter ma position pour toucher les pros les plus proches',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: done ? p.mutedForeground : p.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingOption extends StatelessWidget {
  const _TimingOption({
    required this.timing,
    required this.selected,
    required this.onTap,
  });

  final RequestTiming timing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final urgent = timing == RequestTiming.now;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? p.primarySoft : p.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(
                color: selected ? p.primary : p.border,
                width: selected ? 1.5 : 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    urgent
                        ? Icons.bolt_rounded
                        : timing == RequestTiming.thisWeek
                            ? Icons.event_outlined
                            : Icons.schedule_rounded,
                    color: urgent ? p.danger : p.mutedForeground,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timing.label, style: theme.textTheme.titleSmall),
                        Text(timing.hint, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: selected
                        ? Icon(Icons.radio_button_checked_rounded,
                            key: const ValueKey(1), color: p.primary)
                        : Icon(Icons.radio_button_off_rounded,
                            key: const ValueKey(0), color: p.border),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Écran de confirmation après publication.
class _Published extends StatelessWidget {
  const _Published({required this.request, required this.notified});

  final JobRequest request;
  final int notified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final who = notified == 0
        ? 'Aucun prestataire de ce métier n\'est encore inscrit près de vous. Votre demande reste visible : on vous prévient dès qu\'un devis arrive.'
        : notified == 1
            ? 'Un prestataire en ${categoryLabel(request.categoryId).toLowerCase()} a été prévenu. Vous recevrez une notification à chaque devis.'
            : '$notified prestataires ont été prévenus. Vous recevrez une notification à chaque devis, et pourrez comparer jusqu\'à ${request.maxQuotes} prix.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  width: 64,
                  height: 64,
                  decoration:
                      BoxDecoration(color: p.primary, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: p.onPrimary, size: 36),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.6, 0.6),
                        duration: 350.ms,
                        curve: Curves.easeOutBack)
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: AppSpacing.xl),
                Text('Votre demande est en ligne',
                        style: theme.textTheme.headlineMedium)
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 300.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: AppSpacing.md),
                Text(who,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: p.mutedForeground))
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  request.timing == RequestTiming.now
                      ? 'Demande urgente : visible pendant 2 heures.'
                      : 'Visible pendant 3 jours. Vous pourrez la relancer si besoin.',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(flex: 2),
                AppButton(
                  label: 'Suivre ma demande',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pushReplacement(AppRoutes.request(request.id));
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Retour à l\'accueil',
                  variant: AppButtonVariant.plain,
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.home);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
