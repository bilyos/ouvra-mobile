import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../providers/application/providers_controller.dart';
import '../../data/mock_categories.dart';

/// Tous les métiers, en liste. Choisir un métier filtre l'accueil.
class AllCategoriesScreen extends ConsumerWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Métiers')),
      body: ListView.separated(
        itemCount: kMockCategories.length,
        separatorBuilder: (_, __) => const Divider(indent: 64),
        itemBuilder: (context, i) {
          final c = kMockCategories[i];
          final isSel = selected == c.id;
          return ListTile(
            leading: Icon(c.icon, color: isSel ? p.primary : p.mutedForeground),
            title: Text(c.label),
            trailing: isSel ? Icon(Icons.check_rounded, color: p.primary) : null,
            selected: isSel,
            selectedColor: p.primary,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).toggle(c.id);
              context.pop();
            },
          );
        },
      ),
    );
  }
}
