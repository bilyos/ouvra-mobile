import 'package:dio/dio.dart';

/// Extrait un message d'erreur lisible depuis une exception réseau.
/// Le backend renvoie un corps `{ "message": "..." }`.
String apiErrorMessage(Object error, {String fallback = 'Une erreur est survenue.'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Délai dépassé. Réessaie.',
      DioExceptionType.connectionError =>
        'Impossible de joindre le serveur.',
      _ => fallback,
    };
  }
  return fallback;
}
