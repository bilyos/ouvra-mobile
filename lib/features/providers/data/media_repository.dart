import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;

  /// Upload une image ou une note vocale (bytes) et renvoie l'URL publique.
  /// Le serveur juge le format sur le type annoncé : sans [contentType], il est
  /// déduit de l'extension de [filename].
  Future<String> upload(Uint8List bytes,
      {String filename = 'photo.jpg', String? contentType}) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes,
          filename: filename,
          contentType:
              contentType == null ? null : DioMediaType.parse(contentType)),
    });
    final res = await _dio.post('/media', data: form);
    return res.data['url'] as String;
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(dioProvider));
});
