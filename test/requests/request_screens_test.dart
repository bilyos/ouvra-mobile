import 'package:alloservice/features/requests/data/request_repository.dart';
import 'package:alloservice/features/requests/domain/job_request.dart';
import 'package:alloservice/features/requests/presentation/screens/new_request_screen.dart';
import 'package:alloservice/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:alloservice/features/requests/presentation/screens/request_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('Nouvelle demande', () {
    testWidgets('refuse de publier une demande vide', (tester) async {
      await tester.pumpWidget(wrap(const NewRequestScreen()));
      await tester.tap(find.text('Publier ma demande'));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('Ajoutez une photo, une note vocale'), findsOneWidget);
    });

    testWidgets('demande ensuite le métier', (tester) async {
      await tester.pumpWidget(wrap(const NewRequestScreen()));
      await tester.enterText(find.byType(TextField).first,
          'Le robinet de la cuisine fuit depuis deux jours.');
      await tester.tap(find.text('Publier ma demande'));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez le métier concerné.'), findsOneWidget);
    });

    testWidgets('le métier passé en paramètre est présélectionné',
        (tester) async {
      await tester.pumpWidget(
          wrap(const NewRequestScreen(categoryId: 'electricite')));
      await tester.enterText(find.byType(TextField).first,
          'La prise du salon chauffe et sent le brûlé.');
      await tester.tap(find.text('Publier ma demande'));
      await tester.pumpAndSettle();
      // Le métier est déjà choisi : c'est le titre qui manque
      expect(find.text('Choisissez le métier concerné.'), findsNothing);
      expect(find.text('Donnez un titre court à votre demande.'), findsOneWidget);
    });
  });

  group('Détail, vue prestataire', () {
    testWidgets('propose d\'envoyer un devis', (tester) async {
      await tester.pumpWidget(wrap(
        const RequestDetailScreen(requestId: 'r1'),
        overrides: [
          requestDetailProvider
              .overrideWith((ref, id) async => JobRequest.fromJson(requestJson())),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Robinet de cuisine qui fuit'), findsOneWidget);
      expect(find.text('Envoyer un devis'), findsOneWidget);
      expect(find.textContaining('Aurélien T.'), findsOneWidget);
    });

    testWidgets('affiche son devis en attente au lieu du bouton',
        (tester) async {
      await tester.pumpWidget(wrap(
        const RequestDetailScreen(requestId: 'r1'),
        overrides: [
          requestDetailProvider.overrideWith((ref, id) async =>
              JobRequest.fromJson(requestJson({'myQuote': quoteJson()}))),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Envoyer un devis'), findsNothing);
      expect(find.text('Votre devis : 12 000 FCFA'), findsOneWidget);
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('une demande pleine n\'accepte plus de devis', (tester) async {
      await tester.pumpWidget(wrap(
        const RequestDetailScreen(requestId: 'r1'),
        overrides: [
          requestDetailProvider.overrideWith((ref, id) async =>
              JobRequest.fromJson(requestJson({'quoteCount': 5}))),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Envoyer un devis'), findsNothing);
      expect(find.textContaining('c\'est le maximum'), findsOneWidget);
    });
  });

  group('Détail, vue client', () {
    testWidgets('liste les devis avec prix et bouton Choisir', (tester) async {
      await tester.pumpWidget(wrap(
        const RequestDetailScreen(requestId: 'r1'),
        overrides: [
          requestDetailProvider.overrideWith((ref, id) async =>
              JobRequest.fromJson(requestJson({'mine': true}))),
          requestQuotesProvider.overrideWith((ref, id) async => [
                Quote.fromJson(quoteJson()),
                Quote.fromJson(quoteJson({
                  'id': 'q2',
                  'providerName': 'Ernest Mballa',
                  'price': 9000,
                  'priceKind': 'FROM',
                })),
              ]),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Paul Kamdem'), findsOneWidget);
      expect(find.text('À partir de 9 000 FCFA'), findsOneWidget);
      expect(find.text('Choisir'), findsNWidgets(2));
    });

    testWidgets('les devis retirés n\'apparaissent pas', (tester) async {
      await tester.pumpWidget(wrap(
        const RequestDetailScreen(requestId: 'r1'),
        overrides: [
          requestDetailProvider.overrideWith((ref, id) async =>
              JobRequest.fromJson(requestJson({'mine': true}))),
          requestQuotesProvider.overrideWith((ref, id) async =>
              [Quote.fromJson(quoteJson({'status': 'WITHDRAWN'}))]),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Paul Kamdem'), findsNothing);
      expect(find.textContaining('ont été prévenus'), findsOneWidget);
    });
  });

  testWidgets('le fil affiche les demandes et le nombre de devis',
      (tester) async {
    await tester.pumpWidget(wrap(
      const RequestFeedScreen(),
      overrides: [
        requestFeedProvider.overrideWith((ref, timing) async => [
              JobRequest.fromJson(requestJson({'media': []})),
            ]),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Robinet de cuisine qui fuit'), findsOneWidget);
    expect(find.text('1/5 devis'), findsOneWidget);
  });
}
