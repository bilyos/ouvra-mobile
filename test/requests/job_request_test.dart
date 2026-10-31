import 'package:alloservice/features/requests/domain/job_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('JobRequest.fromJson', () {
    test('lit les champs et ne garde que les photos', () {
      final r = JobRequest.fromJson(requestJson());
      expect(r.title, 'Robinet de cuisine qui fuit');
      expect(r.photos.map((p) => p.url), ['http://x/uploads/a.jpg']);
      expect(r.timing, RequestTiming.thisWeek);
      expect(r.status, RequestStatus.open);
      expect(r.place, 'Bonamoussadi, Douala');
      expect(r.budgetMax, 15000);
      expect(r.isOpen, isTrue);
      expect(r.isFull, isFalse);
    });

    test('convertit les dates UTC en heure locale', () {
      final r = JobRequest.fromJson(
          requestJson({'createdAt': '2026-10-31T08:00:00Z'}));
      expect(r.createdAt.isUtc, isFalse);
      expect(r.createdAt, DateTime.utc(2026, 10, 31, 8).toLocal());
    });

    test('sans quartier, le lieu est la ville seule', () {
      expect(JobRequest.fromJson(requestJson({'quarter': null})).place, 'Douala');
    });

    test('une demande à 5 devis sur 5 est pleine', () {
      expect(JobRequest.fromJson(requestJson({'quoteCount': 5})).isFull, isTrue);
    });

    test('lit le devis du prestataire imbriqué', () {
      final r = JobRequest.fromJson(requestJson({'myQuote': quoteJson()}));
      expect(r.myQuote?.price, 12000);
      expect(r.myQuote?.status, QuoteStatus.sent);
    });

    test('statuts et urgences inconnus retombent sur des valeurs sûres', () {
      final r = JobRequest.fromJson(
          requestJson({'status': 'NOUVEAU', 'timing': null}));
      expect(r.status, RequestStatus.open);
      expect(r.timing, RequestTiming.thisWeek);
    });
  });

  group('Quote.fromJson', () {
    test('lit le prix, son type et la demande liée', () {
      final q = Quote.fromJson(quoteJson({
        'priceKind': 'AFTER_VISIT',
        'status': 'ACCEPTED',
        'request': requestJson(),
      }));
      expect(q.priceKind, PriceKind.afterVisit);
      expect(q.status, QuoteStatus.accepted);
      expect(q.request?.id, 'r1');
      expect(q.ratingAvg, 4.8);
    });
  });

  test('les valeurs envoyées à l\'API correspondent aux enums du backend', () {
    expect(RequestTiming.values.map((t) => t.api),
        ['NOW', 'THIS_WEEK', 'FLEXIBLE']);
    expect(PriceKind.values.map((k) => k.api), ['FIXED', 'FROM', 'AFTER_VISIT']);
  });
}
