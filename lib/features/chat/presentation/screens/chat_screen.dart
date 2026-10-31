import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/network/stomp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/net_image.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.peerName,
    this.peerAvatar,
  });

  final String conversationId;
  final String? peerName;
  final String? peerAvatar;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<ChatMessage> _messages = [];
  final Set<String> _ids = {};
  bool _loading = true;
  String? _error;
  String? _myId;
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _myId = ref.read(authControllerProvider)?.id;
    try {
      final msgs = await ref
          .read(chatRepositoryProvider)
          .messages(widget.conversationId, _myId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
        _ids
          ..clear()
          ..addAll(msgs.map((m) => m.id));
        _loading = false;
      });
      _scrollToBottom();
      // Les messages entrants sont marqués lus → rafraîchir badges.
      ref.invalidate(conversationsProvider);
      ref.invalidate(chatUnreadCountProvider);
      // Abonnement temps réel.
      _unsubscribe = await ref.read(stompServiceProvider).subscribe(
            '/topic/conversations/${widget.conversationId}',
            _onRealtime,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e);
      });
    }
  }

  void _onRealtime(Map<String, dynamic> json) {
    final message = ChatMessage.fromJson(json, _myId);
    if (_ids.contains(message.id)) return;
    _ids.add(message.id);
    if (!mounted) return;
    setState(() => _messages.add(message));
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      final message =
          await ref.read(chatRepositoryProvider).send(widget.conversationId, text);
      if (!_ids.contains(message.id)) {
        _ids.add(message.id);
        if (mounted) setState(() => _messages.add(message));
      }
      _scrollToBottom();
    } catch (e) {
      // Le texte n'est pas perdu : on le remet dans le champ.
      if (_input.text.isEmpty) _input.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final name = widget.peerName ?? 'Conversation';
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(name: name, url: widget.peerAvatar, size: 34),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(color: p.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorState(
                        message: _error!,
                        onRetry: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _load();
                        },
                      )
                    : _messages.isEmpty
                        ? const EmptyState(
                            title: 'Écrivez votre premier message',
                            message:
                                'Décrivez votre besoin, demandez un prix ou une disponibilité. Votre numéro n\'est pas partagé.',
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                                AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              final prev = i > 0 ? _messages[i - 1] : null;
                              final newDay = prev == null ||
                                  !DateUtils.isSameDay(prev.time, m.time);
                              final grouped = !newDay &&
                                  prev.sentByMe == m.sentByMe &&
                                  m.time.difference(prev.time).inMinutes < 5;
                              return Column(
                                children: [
                                  if (newDay) _DayLabel(time: m.time),
                                  _Bubble(message: m, grouped: grouped),
                                ],
                              );
                            },
                          ),
          ),
          _InputBar(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.time});
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.isSameDay(time, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Text(
        today ? 'Aujourd\'hui' : formatShortDate(time),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.grouped});
  final ChatMessage message;

  /// Suit un message du même auteur : espacement réduit.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final mine = message.sentByMe;
    final fg = mine ? p.onPrimary : p.ink;
    const r = Radius.circular(18);
    const tail = Radius.circular(6);
    final hasImage = message.imageUrl != null;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: grouped ? 2 : AppSpacing.sm),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        padding: hasImage
            ? const EdgeInsets.all(3)
            : const EdgeInsets.fromLTRB(14, 9, 14, 7),
        decoration: BoxDecoration(
          color: mine ? p.primary : p.muted,
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: mine ? r : tail,
            bottomRight: mine ? tail : r,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              NetImage(
                url: message.imageUrl,
                width: 220,
                height: 220,
                radius: 15,
              ),
            if (message.text.isNotEmpty)
              Padding(
                padding: hasImage
                    ? const EdgeInsets.fromLTRB(11, 6, 11, 0)
                    : EdgeInsets.zero,
                child: Text(message.text,
                    style: theme.textTheme.bodyLarge?.copyWith(color: fg)),
              ),
            const SizedBox(height: 2),
            Padding(
              padding: hasImage
                  ? const EdgeInsets.fromLTRB(0, 0, 8, 4)
                  : EdgeInsets.zero,
              child: Text(
                DateFormat.Hm('fr').format(message.time),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: mine ? p.onPrimary.withValues(alpha: 0.75) : p.subtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final canSend = widget.controller.text.trim().isNotEmpty;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide.none,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSend(),
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    border: pill,
                    enabledBorder: pill,
                    focusedBorder: pill,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Envoyer',
                onPressed: canSend ? widget.onSend : null,
                style: IconButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: p.onPrimary,
                  disabledBackgroundColor: p.muted,
                  disabledForegroundColor: p.subtle,
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
