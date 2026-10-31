import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/token_storage.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/auth_controller.dart';

/// Lancement, en une seule séquence qui raconte la marque :
///
/// 1. six arêtes d'acier arrivent de tous côtés et s'assemblent en écrou ;
/// 2. l'écrou se remplit et se visse d'un sixième de tour (petit retour haptique) ;
/// 3. le voyant jaune du taxi libre s'allume, deux ondes s'en échappent ;
/// 4. l'écrou rapetisse, glisse à gauche et devient le « o » d'« ouvra »,
///    les lettres montant une à une derrière lui.
///
/// Tout est dessiné en vectoriel (aucune image à télécharger). Si le système
/// demande de réduire les animations, on affiche directement l'état final.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2700);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _duration,
  );
  bool _started = false;
  bool _clicked = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_haptic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _c.value = 1;
    } else {
      _c.forward();
    }
    _bootstrap(reduce);
  }

  /// Le « clic » de l'écrou qui se bloque.
  void _haptic() {
    if (!_clicked && _c.value >= _T.screw.end) {
      _clicked = true;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _bootstrap(bool reduce) async {
    final minSplash = Future<void>.delayed(
      reduce
          ? const Duration(milliseconds: 700)
          : _duration + const Duration(milliseconds: 250),
    );
    bool loggedIn = false;
    try {
      if (await ref.read(tokenStorageProvider).hasToken()) {
        loggedIn = await ref
            .read(authControllerProvider.notifier)
            .tryRestoreSession();
      }
    } catch (_) {
      loggedIn = false;
    }
    await minSplash;
    if (!mounted) return;
    context.go(loggedIn ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.brand800,
        body: Semantics(
          label: 'Ouvra',
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => _Scene(t: _c.value),
          ),
        ),
      ),
    );
  }
}

/// Découpage de la séquence (fractions de la durée totale).
abstract final class _T {
  static const assemble = Interval(0.00, 0.36, curve: Curves.easeOutCubic);
  static const fill = Interval(0.32, 0.44, curve: Curves.easeOut);
  static const screw = Interval(0.34, 0.56, curve: Curves.easeOutBack);
  static const light = Interval(0.54, 0.66, curve: Curves.elasticOut);
  static const ripple = Interval(0.56, 0.86, curve: Curves.easeOutCubic);
  static const word = Interval(0.66, 0.90, curve: Curves.easeInOutCubic);
  static const tagline = Interval(0.86, 1.0, curve: Curves.easeOut);

  static double of(Interval i, double t) => i.transform(t.clamp(0.0, 1.0));
}

class _Scene extends StatelessWidget {
  const _Scene({required this.t});
  final double t;

  static const _letters = ['u', 'v', 'r', 'a'];

  @override
  Widget build(BuildContext context) {
    final word = _T.of(_T.word, t);
    final screw = _T.of(_T.screw, t);
    final nutSize = lerpDouble(128, 37, word)!;
    // Le dessin déborde du carré (ondes) : on le laisse respirer.
    final nut = SizedBox.square(
      dimension: nutSize,
      child: Transform.rotate(
        angle: (screw - 1) * math.pi / 3,
        child: Transform.scale(
          // Léger « tassement » au moment du serrage.
          scale: 1 + 0.08 * math.sin(screw * math.pi),
          child: CustomPaint(
            painter: _NutPainter(
              assemble: t,
              fill: _T.of(_T.fill, t),
              light: _T.of(_T.light, t),
              ripple: t < _T.ripple.begin ? 0 : _T.of(_T.ripple, t),
            ),
          ),
        ),
      ),
    );

    const fontSize = 56.0;
    final letterStyle = AppTypography.display(
      const TextStyle(
        fontSize: fontSize,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
        color: Colors.white,
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Aligne l'écrou sur la hauteur d'x des minuscules.
              Padding(
                padding: EdgeInsets.only(bottom: lerpDouble(0, 9, word)!),
                child: nut,
              ),
              SizedBox(width: lerpDouble(0, 2, word)),
              for (var i = 0; i < _letters.length; i++)
                _Letter(
                  char: _letters[i],
                  style: letterStyle,
                  // Les lettres montent l'une après l'autre.
                  t: ((word - 0.15 - i * 0.14) / 0.45).clamp(0.0, 1.0),
                ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 72,
          child: Opacity(
            opacity: _T.of(_T.tagline, t),
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - _T.of(_T.tagline, t))),
              child: const Text(
                'Le bon artisan, payé seulement quand c\'est fait.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.brand200,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.char, required this.style, required this.t});
  final String char;
  final TextStyle style;
  final double t;

  @override
  Widget build(BuildContext context) {
    final e = Curves.easeOutCubic.transform(t);
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: e,
        heightFactor: 1,
        child: Opacity(
          // Quadratique : rien ne transparaît tant que la lettre est étroite.
          opacity: e * e,
          child: Transform.translate(
            offset: Offset(0, 36 * (1 - e)),
            child: Text(char, style: style),
          ),
        ),
      ),
    );
  }
}

/// Dessine l'écrou dans un repère de 32 × 32 (celui du logo).
class _NutPainter extends CustomPainter {
  const _NutPainter({
    required this.assemble,
    required this.fill,
    required this.light,
    required this.ripple,
  });

  /// Avancement global (sert à décaler l'arrivée de chaque arête).
  final double assemble;
  final double fill;
  final double light;
  final double ripple;

  static const _center = Offset(16, 16);
  static const _radius = 14.2;

  /// Sommets d'un hexagone pointe en haut, comme le logo.
  static List<Offset> get _vertices => [
    for (var k = 0; k < 6; k++)
      _center + Offset.fromDirection(-math.pi / 2 + k * math.pi / 3, _radius),
  ];

  static Path get _body => Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(11.57, 3.56)
    ..quadraticBezierTo(16, 1, 20.43, 3.56)
    ..lineTo(24.56, 5.94)
    ..quadraticBezierTo(28.99, 8.5, 28.99, 13.62)
    ..lineTo(28.99, 18.38)
    ..quadraticBezierTo(28.99, 23.5, 24.56, 26.06)
    ..lineTo(20.43, 28.44)
    ..quadraticBezierTo(16, 31, 11.57, 28.44)
    ..lineTo(7.44, 26.06)
    ..quadraticBezierTo(3.01, 23.5, 3.01, 18.38)
    ..lineTo(3.01, 13.62)
    ..quadraticBezierTo(3.01, 8.5, 7.44, 5.94)
    ..close()
    ..addOval(Rect.fromCircle(center: _center, radius: 6.4));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32, size.height / 32);

    // 1. Les six arêtes arrivent de l'extérieur en tournant, l'une après l'autre.
    if (fill < 1) {
      final v = _vertices;
      final edge = Paint()
        ..color = Colors.white.withValues(alpha: 1 - fill)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 6; k++) {
        final start = k * 0.035;
        final raw = ((assemble - start) / (_T.assemble.end - 0.175)).clamp(
          0.0,
          1.0,
        );
        final e = Curves.easeOutCubic.transform(raw);
        if (e == 0) continue;
        final a = v[k];
        final b = v[(k + 1) % 6];
        final mid = Offset.lerp(a, b, 0.5)!;
        final normal = (mid - _center) / (mid - _center).distance;
        final away = normal * (34 * (1 - e));
        final spin = (1 - e) * (k.isEven ? 1.6 : -1.6);
        canvas.save();
        canvas.translate(mid.dx + away.dx, mid.dy + away.dy);
        canvas.rotate(spin);
        edge.color = Colors.white.withValues(alpha: e * (1 - fill));
        canvas.drawLine(a - mid, b - mid, edge);
        canvas.restore();
      }
    }

    // 2. Le corps plein de l'écrou.
    if (fill > 0) {
      canvas.drawPath(
        _body,
        Paint()..color = Colors.white.withValues(alpha: fill),
      );
    }

    // 3. Le voyant : deux ondes jaunes puis le disque.
    if (ripple > 0 && ripple < 1) {
      for (var k = 0; k < 2; k++) {
        final r = 4.1 + ripple * (18 + k * 10);
        final alpha = (1 - ripple) * (k == 0 ? 0.9 : 0.5);
        canvas.drawCircle(
          _center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 * (1 - ripple) + 0.3
            ..color = AppColors.sun400.withValues(alpha: alpha),
        );
      }
    }
    if (light > 0) {
      canvas.drawCircle(
        _center,
        4.1 * light,
        Paint()..color = AppColors.sun400,
      );
    }
  }

  @override
  bool shouldRepaint(_NutPainter old) =>
      old.assemble != assemble ||
      old.fill != fill ||
      old.light != light ||
      old.ripple != ripple;
}
