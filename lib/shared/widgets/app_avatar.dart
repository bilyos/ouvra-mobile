import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'net_image.dart';

/// Avatar rond : photo si disponible, sinon initiales sur vert pâle.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 44,
    this.online = false,
  });

  final String name;
  final String? url;
  final double size;

  /// Pastille verte « en ligne ».
  final bool online;

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = ColoredBox(
      color: p.primarySoft,
      child: Center(
        child: Text(
          initials(name),
          style: TextStyle(
            color: p.primary,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
    final face = ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: NetImage(url: url, width: size, height: size, fallback: fallback),
      ),
    );
    if (!online) return face;
    final dot = size * 0.26;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          face,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: dot,
              width: dot,
              decoration: BoxDecoration(
                color: AppColors.brand400,
                shape: BoxShape.circle,
                border: Border.all(color: p.background, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
