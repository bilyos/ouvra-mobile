import 'package:alloservice/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Évite l'appel de plugin natif (indisponible en test unitaire).
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Le splash s\'affiche puis redirige vers l\'onboarding',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OuvraApp()));

    // Au démarrage, le splash affiche le symbole.
    expect(find.bySemanticsLabel('Ouvra'), findsOneWidget);

    // Sans jeton stocké, le splash joue son animation (~2,7 s) puis redirige.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pumpAndSettle();

    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}
