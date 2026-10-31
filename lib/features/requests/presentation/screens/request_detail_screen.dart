import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../bookings/data/booking_repository.dart';
import '../../../chat/data/chat_repository.dart';
import '../../data/request_repository.dart';
import '../../domain/job_request.dart';
import '../request_format.dart';
import '../widgets/quote_form_sheet.dart';
import '../widgets/request_photos.dart';
import '../widgets/voice_note.dart';

/// Une demande : le client y compare les devis reçus et en choisit un ; le
/// prestataire y voit le problème et envoie son prix.
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(requestDetailProvider(requestId));
    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(requestDetailProvider(requestId)),
        ),
      ),
      data: (r) => r.mine ? _ClientView(request: r) : _ProviderView(request: r),
    );
  }
}

/// Partie commune : photos, titre, description, vocal, où et quand.
class _RequestBody extends StatelessWidget {
  const _RequestBody({required this.request, required this.status});

  final JobRequest request;
  final Widget status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final r = request;
    final urgent = r.timing == RequestTiming.now;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.photos.isNotEmpty) ...[
          RequestGallery(photos: r.photos),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          children: [
            Icon(categoryIcon(r.categoryId), size: 16, color: p.mutedForeground),
            const SizedBox(width: 6),
            Text(categoryLabel(r.categoryId), style: theme.textTheme.labelSmall),
            if (urgent) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.dangerSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Urgent',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: p.danger, fontWeight: FontWeight.w700)),
              ),
            ],
            const Spacer(),
            Text(agoText(r.createdAt), style: theme.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(r.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        status,
        if (r.description != null && r.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(r.description!, style: theme.textTheme.bodyLarge),
        ],
        if (r.voiceUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          VoicePlayer(source: r.voiceUrl!, seconds: r.voiceSeconds),
        ],
        const SizedBox(height: AppSpacing.xl),
        _Fact(
          icon: Icons.place_outlined,
          label: r.mine && r.address != null && r.address!.isNotEmpty
              ? '${r.address}, ${r.city}'
              : [r.place, ?kmText(r.distanceKm)].join(' · '),
        ),
        _Fact(
          icon: urgent ? Icons.bolt_rounded : Icons.event_outlined,
          label: switch (r.timing) {
            RequestTiming.now => 'Dès que possible',
            RequestTiming.thisWeek => 'Dans la semaine',
            RequestTiming.flexible => 'Pas pressé',
          },
        ),
        if (r.budgetMax != null)
          _Fact(
            icon: Icons.payments_outlined,
            label: 'Budget : ${formatFcfa(r.budgetMax!)} au plus',
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: p.mutedForeground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

// ── Vue client ──

enum _Sort { best, price, date }

class _ClientView extends ConsumerStatefulWidget {
  const _ClientView({required this.request});
  final JobRequest request;

  @override
  ConsumerState<_ClientView> createState() => _ClientViewState();
}

class _ClientViewState extends ConsumerState<_ClientView> {
  _Sort _sort = _Sort.best;
  bool _busy = false;

  JobRequest get r => widget.request;

  void _refresh() {
    ref.invalidate(requestDetailProvider(r.id));
    ref.invalidate(requestQuotesProvider(r.id));
    ref.invalidate(myRequestsProvider);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer la demande ?'),
        content: const Text(
            'Elle disparaît du fil des prestataires et les devis reçus sont annulés.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Garder')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Retirer',
                  style: TextStyle(color: ctx.palette.danger))),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => ref.read(requestRepositoryProvider).cancel(r.id),
          'Demande retirée.');
    }
  }

  Future<void> _accept(Quote q) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _ConfirmQuote(quote: q),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final booking =
          await ref.read(requestRepositoryProvider).acceptQuote(q.id);
      HapticFeedback.heavyImpact();
      _refresh();
      ref.invalidate(myBookingsProvider);
      if (mounted) context.push(AppRoutes.booking(booking.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ask(Quote q) async {
    try {
      final conv = await ref.read(chatRepositoryProvider).start(q.providerId);
      if (mounted) {
        context.push(AppRoutes.chat(conv.id),
            extra: {'name': q.providerName, 'avatarUrl': q.providerAvatarUrl});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  List<Quote> _sorted(List<Quote> all) {
    final list = [...all];
    switch (_sort) {
      case _Sort.best:
        break; // déjà classés par le serveur : note, distance, disponibilité
      case _Sort.price:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.date:
        list.sort((a, b) => a.availableAt.compareTo(b.availableAt));
    }
    // Le devis retenu reste en tête
    list.sort((a, b) => (b.status == QuoteStatus.accepted ? 1 : 0)
        .compareTo(a.status == QuoteStatus.accepted ? 1 : 0));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final quotesAsync = ref.watch(requestQuotesProvider(r.id));
    final (label, tone) = requestStatus(r);
    final left = r.isOpen ? remainingText(r.expiresAt) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma demande'),
        actions: [
          if (r.isOpen)
            PopupMenuButton<String>(
              tooltip: 'Plus d\'actions',
              onSelected: (_) => _cancel(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'cancel', child: Text('Retirer la demande')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          await ref.read(requestQuotesProvider(r.id).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxxl),
          children: [
            _RequestBody(
              request: r,
              status: Row(
                children: [
                  Flexible(child: StatusLabel(label: label, tone: tone)),
                  if (left != null) ...[
                    Text('  ·  ', style: theme.textTheme.labelSmall),
                    Text(left, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
            if (r.status == RequestStatus.assigned && r.bookingId != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _Banner(
                icon: Icons.verified_outlined,
                text:
                    'Vous avez choisi un prestataire. Suivez l\'intervention et le paiement dans la réservation.',
                action: 'Voir la réservation',
                onAction: () => context.push(AppRoutes.booking(r.bookingId!)),
              ),
            ],
            if (r.status == RequestStatus.expired) ...[
              const SizedBox(height: AppSpacing.lg),
              _Banner(
                icon: Icons.history_rounded,
                text: r.quoteCount == 0
                    ? 'Aucun prestataire n\'a répondu à temps. Relancez-la pour la remettre en tête du fil.'
                    : 'Elle a expiré avant que vous choisissiez. Relancez-la pour recevoir de nouveaux devis.',
                action: 'Relancer la demande',
                onAction: _busy
                    ? null
                    : () => _run(
                        () => ref.read(requestRepositoryProvider).relaunch(r.id),
                        'Demande relancée.'),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: Text('Devis reçus', style: theme.textTheme.titleLarge),
                ),
                Text('${r.quoteCount} sur ${r.maxQuotes}',
                    style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            quotesAsync.when(
              loading: () => const LoadingView(padding: AppSpacing.lg),
              error: (e, _) => ErrorState(
                compact: true,
                message: apiErrorMessage(e),
                onRetry: () => ref.invalidate(requestQuotesProvider(r.id)),
              ),
              data: (all) {
                final visible = all
                    .where((q) =>
                        q.status == QuoteStatus.sent ||
                        q.status == QuoteStatus.accepted)
                    .toList();
                if (visible.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: p.paper,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      r.isOpen
                          ? 'Les prestataires du métier autour de vous ont été prévenus. Les premiers devis arrivent en général dans l\'heure ; vous recevrez une notification.'
                          : 'Aucun devis en cours.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: p.mutedForeground),
                    ),
                  );
                }
                final list = _sorted(visible);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (list.length > 1) ...[
                      SegmentedChoice<_Sort>(
                        values: _Sort.values,
                        selected: _sort,
                        label: (s) => switch (s) {
                          _Sort.best => 'Conseillé',
                          _Sort.price => 'Prix',
                          _Sort.date => 'Plus tôt',
                        },
                        onChanged: (s) => setState(() => _sort = s),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    for (final q in list) ...[
                      _QuoteCard(
                        quote: q,
                        canChoose: r.isOpen && !_busy,
                        onChoose: () => _accept(q),
                        onAsk: () => _ask(q),
                        onProfile: () =>
                            context.push(AppRoutes.providerDetail(q.providerId)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: p.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text(text,
                      style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: action,
            variant: AppButtonVariant.secondary,
            compact: true,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

/// Un devis : qui, combien, quand, et ce qu'il propose de faire.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.canChoose,
    required this.onChoose,
    required this.onAsk,
    required this.onProfile,
  });

  final Quote quote;
  final bool canChoose;
  final VoidCallback onChoose;
  final VoidCallback onAsk;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final q = quote;
    final accepted = q.status == QuoteStatus.accepted;
    final rating = q.reviewCount == 0
        ? 'Nouveau'
        : '${q.ratingAvg.toStringAsFixed(1).replaceAll('.', ',')} (${q.reviewCount} avis)';

    return Container(
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: accepted ? p.primary : p.border, width: accepted ? 1.5 : 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Row(
              children: [
                AppAvatar(name: q.providerName, url: q.providerAvatarUrl, size: 44),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.providerName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 15,
                              color: q.reviewCount == 0
                                  ? p.subtle
                                  : AppColors.sun500),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              [rating, ?kmText(q.distanceKm)].join(' · '),
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (accepted)
                  Text('Choisi',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: p.primary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(quotePriceText(q.price, q.priceKind),
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            '${q.priceKind == PriceKind.fixed ? 'Prix ferme' : q.priceKind == PriceKind.from ? 'Ajusté sur place' : 'Prix fixé après visite'} · disponible ${whenText(q.availableAt)}',
            style: theme.textTheme.bodySmall,
          ),
          if (q.message != null && q.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('« ${q.message!} »',
                style: theme.textTheme.bodyMedium?.copyWith(color: p.ink)),
          ],
          if (canChoose && !accepted) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Écrire',
                    variant: AppButtonVariant.tonal,
                    compact: true,
                    onPressed: onAsk,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Choisir',
                    variant: AppButtonVariant.secondary,
                    compact: true,
                    onPressed: onChoose,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmQuote extends StatelessWidget {
  const _ConfirmQuote({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final q = quote;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir ${q.providerName.split(' ').first} ?',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                    child: Text('Prix', style: theme.textTheme.bodyMedium)),
                Text(quotePriceText(q.price, q.priceKind),
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                    child: Text('Passage', style: theme.textTheme.bodyMedium)),
                Text(whenText(q.availableAt), style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: p.paper,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: p.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Vous payez ensuite par Mobile Money. Ouvra garde l\'argent et ne le verse qu\'une fois le travail fini. Les autres devis seront déclinés.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Choisir et payer',
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Pas encore',
              variant: AppButtonVariant.plain,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vue prestataire ──

class _ProviderView extends ConsumerStatefulWidget {
  const _ProviderView({required this.request});
  final JobRequest request;

  @override
  ConsumerState<_ProviderView> createState() => _ProviderViewState();
}

class _ProviderViewState extends ConsumerState<_ProviderView> {
  bool _busy = false;

  JobRequest get r => widget.request;

  void _refresh() {
    ref.invalidate(requestDetailProvider(r.id));
    ref.invalidate(requestFeedProvider);
    ref.invalidate(myQuotesProvider);
  }

  Future<void> _quote() async {
    final sent = await showQuoteForm(context, r);
    if (sent == null) return;
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Devis envoyé. Le client est prévenu.')));
    }
  }

  Future<void> _withdraw(Quote q) async {
    setState(() => _busy = true);
    try {
      await ref.read(requestRepositoryProvider).withdrawQuote(q.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final mine = r.myQuote;
    final active = mine != null &&
        (mine.status == QuoteStatus.sent || mine.status == QuoteStatus.accepted);

    Widget bottom;
    if (active) {
      final (label, tone) = quoteStatus(mine.status);
      bottom = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Votre devis : ${quotePriceText(mine.price, mine.priceKind)}',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    StatusLabel(label: label, tone: tone),
                  ],
                ),
              ),
              if (mine.status == QuoteStatus.sent)
                TextButton(
                  onPressed: _busy ? null : () => _withdraw(mine),
                  child: Text('Retirer', style: TextStyle(color: p.danger)),
                ),
            ],
          ),
          if (mine.status == QuoteStatus.accepted) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Voir mes réservations',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(AppRoutes.bookings),
            ),
          ],
        ],
      );
    } else if (!r.isOpen) {
      bottom = Text('Cette demande n\'accepte plus de devis.',
          style: theme.textTheme.bodyMedium?.copyWith(color: p.mutedForeground),
          textAlign: TextAlign.center);
    } else if (r.isFull) {
      bottom = Text(
          'Le client a déjà reçu ${r.maxQuotes} devis : c\'est le maximum.',
          style: theme.textTheme.bodyMedium?.copyWith(color: p.mutedForeground),
          textAlign: TextAlign.center);
    } else {
      bottom = AppButton(
        label: mine == null ? 'Envoyer un devis' : 'Envoyer un nouveau devis',
        onPressed: _quote,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Demande')),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          await ref.read(requestDetailProvider(r.id).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxl),
          children: [
            _RequestBody(
              request: r,
              status: Row(
                children: [
                  AppAvatar(name: r.clientName, url: r.clientAvatarUrl, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${r.clientName} · ${r.quoteCount} devis sur ${r.maxQuotes}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'L\'adresse exacte et le numéro du client vous sont donnés une fois votre devis choisi et payé.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.background,
          border: Border(top: BorderSide(color: p.border, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
            child: bottom,
          ),
        ),
      ),
    );
  }
}
