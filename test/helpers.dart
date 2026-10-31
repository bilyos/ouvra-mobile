import 'package:alloservice/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monte un écran avec le thème Ouvra et, au besoin, des données simulées.
Widget wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

/// Demande telle que l'API la renvoie ; [extra] remplace des champs.
Map<String, dynamic> requestJson([Map<String, dynamic> extra = const {}]) => {
      'id': 'r1',
      'categoryId': 'plomberie',
      'title': 'Robinet de cuisine qui fuit',
      'description': 'L\'eau coule sous le meuble depuis deux jours.',
      'voiceUrl': null,
      'voiceSeconds': null,
      'media': [
        {'kind': 'PHOTO', 'url': 'http://x/uploads/a.jpg'},
        {'kind': 'VIDEO', 'url': 'http://x/uploads/b.mp4'},
      ],
      'city': 'Douala',
      'quarter': 'Bonamoussadi',
      'distanceKm': 2.5,
      'timing': 'THIS_WEEK',
      'budgetMax': 15000,
      'status': 'OPEN',
      'quoteCount': 1,
      'maxQuotes': 5,
      'expiresAt':
          DateTime.now().add(const Duration(days: 2)).toUtc().toIso8601String(),
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String(),
      'clientName': 'Aurélien T.',
      'clientAvatarUrl': null,
      'mine': false,
      'address': null,
      'bookingId': null,
      'myQuote': null,
      ...extra,
    };

Map<String, dynamic> quoteJson([Map<String, dynamic> extra = const {}]) => {
      'id': 'q1',
      'requestId': 'r1',
      'providerId': 'p1',
      'providerName': 'Paul Kamdem',
      'providerAvatarUrl': null,
      'providerTitle': 'Plombier professionnel',
      'ratingAvg': 4.8,
      'reviewCount': 2,
      'distanceKm': 1.5,
      'price': 12000,
      'priceKind': 'FIXED',
      'message': 'Je change le joint et le flexible.',
      'availableAt': DateTime.now()
          .add(const Duration(days: 1))
          .toUtc()
          .toIso8601String(),
      'status': 'SENT',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'request': null,
      ...extra,
    };
