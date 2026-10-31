import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Captures automatisées : `--dart-define=SEMANTICS=true` expose l'arbre
  // d'accessibilité dès le démarrage sur le web.
  if (const bool.fromEnvironment('SEMANTICS')) {
    SemanticsBinding.instance.ensureSemantics();
  }
  Intl.defaultLocale = 'fr';
  await initializeDateFormatting('fr');
  runApp(const ProviderScope(child: OuvraApp()));
}

class OuvraApp extends ConsumerWidget {
  const OuvraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    return MaterialApp.router(
      title: 'Ouvra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: AppRouter.router,
    );
  }
}
