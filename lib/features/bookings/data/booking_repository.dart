import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/booking.dart';

/// Accès à l'API des réservations et du paiement en séquestre.
class BookingRepository {
  BookingRepository(this._dio);

  final Dio _dio;

  List<Booking> _list(dynamic data) => (data as List)
      .map((e) => Booking.fromJson(e as Map<String, dynamic>))
      .toList();

  Booking _one(Response res) =>
      Booking.fromJson(res.data as Map<String, dynamic>);

  /// Réservations passées par le client connecté.
  Future<List<Booking>> mine() async =>
      _list((await _dio.get('/bookings/mine')).data);

  /// Réservations reçues par le prestataire connecté.
  Future<List<Booking>> received() async =>
      _list((await _dio.get('/bookings/received')).data);

  Future<Booking> detail(String id) async => _one(await _dio.get('/bookings/$id'));

  Future<Booking> create({
    required String providerId,
    required String title,
    required String description,
    required DateTime scheduledAt,
    required String address,
    required int price,
    String? categoryId,
  }) async =>
      _one(await _dio.post('/bookings', data: {
        'providerId': providerId,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'address': address,
        'price': price,
        'urgent': false,
        'categoryId': categoryId,
      }));

  Future<SlotsInfo> slots(String providerId, {int days = 7}) async {
    final res = await _dio.get('/providers/$providerId/slots',
        queryParameters: {'days': days});
    return SlotsInfo.fromJson(res.data as Map<String, dynamic>);
  }

  /// Lance le paiement Mobile Money ; l'argent reste bloqué chez Ouvra.
  Future<Payment> pay(String bookingId,
      {required PaymentMethod method, String? phone}) async {
    final res = await _dio.post('/bookings/$bookingId/pay', data: {
      'method': method.api,
      'phoneNumber': ?phone,
    });
    return Payment.fromJson(res.data as Map<String, dynamic>);
  }

  /// Confirmation du paiement (simulée tant que l'opérateur n'est pas branché).
  Future<Payment> confirmPayment(String paymentId) async {
    final res = await _dio.post('/bookings/payments/$paymentId/confirm');
    return Payment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Booking> cancel(String id, {String? reason}) async =>
      _one(await _dio.post('/bookings/$id/cancel', data: {'reason': ?reason}));

  /// Côté prestataire : ACCEPTED, REJECTED, IN_PROGRESS, CANCELLED.
  Future<Booking> setStatus(String id, String status, {String? reason}) async =>
      _one(await _dio.patch('/bookings/$id/status',
          data: {'status': status, 'cancelReason': ?reason}));

  Future<Booking> onTheWay(String id) async =>
      _one(await _dio.post('/bookings/$id/on-the-way'));

  /// Le prestataire saisit le code du client : il est payé tout de suite.
  Future<Booking> completeWithCode(String id, String code) async =>
      _one(await _dio.post('/bookings/$id/complete', data: {'code': code}));

  /// Le prestataire déclare avoir fini sans code : versement sous 48 h.
  Future<Booking> markDone(String id) async =>
      _one(await _dio.post('/bookings/$id/mark-done'));

  /// Le client confirme que le travail est fait : versement immédiat.
  Future<Booking> confirmCompletion(String id) async =>
      _one(await _dio.post('/bookings/$id/confirm-completion'));

  /// Le client signale un problème : l'argent reste bloqué.
  Future<Booking> dispute(String id, String reason) async =>
      _one(await _dio.post('/bookings/$id/dispute', data: {'reason': reason}));
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(dioProvider));
});

/// Réservations du client connecté.
final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  return ref.watch(bookingRepositoryProvider).mine();
});

/// Réservations reçues par le prestataire connecté.
final receivedBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) {
  return ref.watch(bookingRepositoryProvider).received();
});

final bookingDetailProvider =
    FutureProvider.autoDispose.family<Booking, String>((ref, id) {
  return ref.watch(bookingRepositoryProvider).detail(id);
});

final providerSlotsProvider =
    FutureProvider.autoDispose.family<SlotsInfo, String>((ref, providerId) {
  return ref.watch(bookingRepositoryProvider).slots(providerId);
});
