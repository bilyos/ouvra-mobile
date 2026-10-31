import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../bookings/domain/booking.dart';
import '../domain/job_request.dart';

/// Accès à l'API du fil de demandes et des devis.
class RequestRepository {
  RequestRepository(this._dio);

  final Dio _dio;

  List<JobRequest> _requests(dynamic data) => (data as List)
      .map((e) => JobRequest.fromJson(e as Map<String, dynamic>))
      .toList();

  List<Quote> _quotes(dynamic data) => (data as List)
      .map((e) => Quote.fromJson(e as Map<String, dynamic>))
      .toList();

  JobRequest _request(Response res) =>
      JobRequest.fromJson(res.data as Map<String, dynamic>);

  Quote _quote(Response res) => Quote.fromJson(res.data as Map<String, dynamic>);

  /// Publie la demande ; renvoie aussi le nombre de prestataires prévenus.
  Future<(JobRequest, int)> create({
    required String categoryId,
    required String title,
    String? description,
    String? voiceUrl,
    int? voiceSeconds,
    List<String> photoUrls = const [],
    required String city,
    String? quarter,
    double? lat,
    double? lng,
    String? address,
    required RequestTiming timing,
    int? budgetMax,
  }) async {
    final res = await _dio.post('/requests', data: {
      'categoryId': categoryId,
      'title': title,
      'description': ?description,
      'voiceUrl': ?voiceUrl,
      'voiceSeconds': ?voiceSeconds,
      'media': [
        for (final url in photoUrls) {'kind': 'PHOTO', 'url': url},
      ],
      'city': city,
      'quarter': ?quarter,
      'lat': ?lat,
      'lng': ?lng,
      'address': ?address,
      'timing': timing.api,
      'budgetMax': ?budgetMax,
    });
    final data = res.data as Map<String, dynamic>;
    return (
      JobRequest.fromJson(data['request'] as Map<String, dynamic>),
      (data['notifiedProviders'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<JobRequest>> mine() async =>
      _requests((await _dio.get('/requests/mine')).data);

  /// Prestataire : demandes ouvertes de son métier, près de lui.
  Future<List<JobRequest>> feed({RequestTiming? timing}) async =>
      _requests((await _dio.get('/requests/feed',
              queryParameters: {'timing': ?timing?.api}))
          .data);

  Future<JobRequest> detail(String id) async =>
      _request(await _dio.get('/requests/$id'));

  Future<JobRequest> cancel(String id) async =>
      _request(await _dio.post('/requests/$id/cancel'));

  Future<JobRequest> relaunch(String id) async =>
      _request(await _dio.post('/requests/$id/relaunch'));

  /// Client : les devis reçus, le meilleur en premier.
  Future<List<Quote>> quotes(String requestId) async =>
      _quotes((await _dio.get('/requests/$requestId/quotes')).data);

  Future<Quote> sendQuote(
    String requestId, {
    required int price,
    required PriceKind priceKind,
    String? message,
    required DateTime availableAt,
  }) async =>
      _quote(await _dio.post('/requests/$requestId/quotes', data: {
        'price': price,
        'priceKind': priceKind.api,
        'message': ?message,
        'availableAt': availableAt.toUtc().toIso8601String(),
      }));

  Future<List<Quote>> myQuotes() async =>
      _quotes((await _dio.get('/quotes/mine')).data);

  Future<Quote> withdrawQuote(String quoteId) async =>
      _quote(await _dio.post('/quotes/$quoteId/withdraw'));

  /// Client : choisit ce devis. La réservation est créée et attend le paiement.
  Future<Booking> acceptQuote(String quoteId) async => Booking.fromJson(
      (await _dio.post('/quotes/$quoteId/accept')).data as Map<String, dynamic>);
}

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(ref.watch(dioProvider));
});

final myRequestsProvider = FutureProvider.autoDispose<List<JobRequest>>((ref) {
  return ref.watch(requestRepositoryProvider).mine();
});

final requestDetailProvider =
    FutureProvider.autoDispose.family<JobRequest, String>((ref, id) {
  return ref.watch(requestRepositoryProvider).detail(id);
});

final requestQuotesProvider =
    FutureProvider.autoDispose.family<List<Quote>, String>((ref, id) {
  return ref.watch(requestRepositoryProvider).quotes(id);
});

/// `null` : toutes les demandes ; `RequestTiming.now` : les urgences seulement.
final requestFeedProvider = FutureProvider.autoDispose
    .family<List<JobRequest>, RequestTiming?>((ref, timing) {
  return ref.watch(requestRepositoryProvider).feed(timing: timing);
});

final myQuotesProvider = FutureProvider.autoDispose<List<Quote>>((ref) {
  return ref.watch(requestRepositoryProvider).myQuotes();
});
