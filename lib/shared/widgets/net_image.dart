import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Image réseau économe : décodée à la taille affichée (mémoire des petits
/// Android), mise en cache disque, fond neutre pendant le chargement.
class NetImage extends StatelessWidget {
  const NetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.fallback,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  /// Affiché si l'URL est vide ou l'image indisponible.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final empty = fallback ??
        ColoredBox(color: p.muted, child: const SizedBox.expand());
    Widget image;
    if (url == null || url!.isEmpty) {
      image = SizedBox(width: width, height: height, child: empty);
    } else {
      image = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null && width!.isFinite
            ? (width! * dpr).round()
            : null,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => ColoredBox(color: p.muted),
        errorWidget: (_, __, ___) =>
            SizedBox(width: width, height: height, child: empty),
      );
    }
    if (radius == 0) return image;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}
