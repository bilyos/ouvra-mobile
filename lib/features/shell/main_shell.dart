import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../chat/data/chat_repository.dart';

/// Coquille et barre d'onglets flottante : une pilule arrondie détachée des
/// bords, légendes toujours visibles, onglet actif marqué par une pastille.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(chatUnreadCountProvider).valueOrNull ?? 0;

    const tabs = [
      (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
      (Icons.search_rounded, Icons.search_rounded, 'Recherche'),
      (Icons.event_note_outlined, Icons.event_note_rounded, 'Réservations'),
      (
        Icons.chat_bubble_outline_rounded,
        Icons.chat_bubble_rounded,
        'Messages',
      ),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
    ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181F1A) : p.background,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(color: p.border, width: 0.5),
              // Ombre neutre et courte : juste de quoi décoller la barre.
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _Tab(
                      icon: tabs[i].$1,
                      selectedIcon: tabs[i].$2,
                      label: tabs[i].$3,
                      selected: shell.currentIndex == i,
                      badge: i == 3 ? unread : 0,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.primary : p.subtle;
    Widget glyph = Icon(selected ? selectedIcon : icon, size: 22, color: color);
    if (badge > 0) {
      glyph = Badge(
        backgroundColor: p.danger,
        textColor: Colors.white,
        label: Text(badge > 9 ? '9+' : '$badge'),
        child: glyph,
      );
    }
    return Semantics(
      selected: selected,
      button: true,
      label: badge > 0 ? '$label, $badge non lus' : label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 28,
                width: selected ? 52 : 36,
                decoration: BoxDecoration(
                  color: selected ? p.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: glyph),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
