import 'package:alloservice/features/requests/domain/job_request.dart';
import 'package:alloservice/features/requests/presentation/request_format.dart';
import 'package:alloservice/features/requests/presentation/widgets/quote_form_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('containsContact (même règle que le serveur)', () {
    for (final text in [
      'Appelez le 690123456',
      'mon numéro : 6 90 12 34 56',
      '+237 690-12-34-56',
      '00237 6.90.12.34.56',
      '6 9O 12 34 56', // un O à la place d'un zéro
      '222 33 44 55', // fixe
      'écrivez à paul@gmail.com',
      'On parle sur WhatsApp',
      'wtsp moi',
      'wa.me/237690123456',
      'appelle-moi demain',
    ]) {
      test('repère « $text »', () => expect(containsContact(text), isTrue));
    }

    for (final text in [
      'Je change le joint, 15000 FCFA pièces comprises',
      'Disponible le 12/11 à 14 h',
      'Deux robinets et 3 mètres de tuyau',
      'Intervention en 45 minutes',
      '',
    ]) {
      test('laisse passer « $text »', () => expect(containsContact(text), isFalse));
    }
  });

  group('prix', () {
    test('selon son type', () {
      // Espaces insécables : le montant ne se coupe jamais en fin de ligne
      const amount = '15 000 FCFA';
      expect(quotePriceText(15000, PriceKind.fixed), amount);
      expect(quotePriceText(15000, PriceKind.from), 'À partir de $amount');
      expect(quotePriceText(15000, PriceKind.afterVisit), 'Environ $amount');
    });
  });

  group('temps', () {
    test('agoText', () {
      final now = DateTime.now();
      expect(agoText(now), 'à l\'instant');
      expect(agoText(now.subtract(const Duration(minutes: 12))), 'il y a 12 min');
      expect(agoText(now.subtract(const Duration(hours: 3))), 'il y a 3 h');
      expect(agoText(now.subtract(const Duration(days: 2))), 'il y a 2 j');
    });

    test('remainingText arrondit les jours et s\'arrête à l\'échéance', () {
      final now = DateTime.now();
      expect(remainingText(now.add(const Duration(hours: 71, minutes: 50))),
          'encore 3 j');
      expect(remainingText(now.add(const Duration(minutes: 90))), 'encore 1 h');
      expect(remainingText(now.subtract(const Duration(minutes: 1))), isNull);
    });

    test('whenText pour aujourd\'hui et demain', () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
      expect(whenText(tomorrow), 'demain à 9 h');
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      expect(whenText(today), 'aujourd\'hui à 14 h 30');
    });
  });

  test('kmText ne descend pas sous 500 m', () {
    expect(kmText(null), isNull);
    expect(kmText(0.2), 'à 500 m');
    expect(kmText(3.5), 'à 3,5 km');
  });

  test('libellé et icône des métiers', () {
    expect(categoryLabel('plomberie'), 'Plomberie');
    expect(categoryLabel('inconnu'), 'inconnu');
  });
}
